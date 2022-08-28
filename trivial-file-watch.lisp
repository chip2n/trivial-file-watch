(in-package #:trivial-file-watch)

(defvar *inotify* nil)
(defvar *current-thread* nil)
(defvar *kill-path* nil)
(defvar *entries* (make-hash-table))

(defclass watch-entry ()
  ((path :initarg :path :reader watch-entry-path)
   (handler :initarg :handler :accessor watch-entry-handler)))

(defun start ()
  (setf *inotify* (cl-inotify:make-inotify nil))
  (setf *current-thread*
        (bt:make-thread
         (lambda ()
           ;; Always watch a temporary file, which we use to kill inotify when
           ;; it's modified. There's probably a better way to do this but I
           ;; haven't figured that out yet
           (uiop:with-temporary-file (:pathname path :prefix "trivial-file-watch-")
             (setf *kill-path* path)
             (let ((wd (cl-inotify:watch *inotify* path '(:modify))))
               (loop for event = (cl-inotify:read-event *inotify*)
                     while (not (= (cl-inotify:inotify-event-wd event) wd))
                     do (let ((queued-events (list event)))
                          ;; Read all available events and make sure to handle duplicates
                          (loop while (cl-inotify:event-available-p *inotify*)
                                do (push (cl-inotify:read-event *inotify*) queued-events))

                          ;; Remove duplicates
                          (setf queued-events (delete-duplicates queued-events :key #'cl-inotify:inotify-event-wd))

                          ;; Handle each modified file
                          (loop for queued-event in queued-events
                                do (let ((filename (cl-inotify:inotify-event-name event))
                                         (entry (gethash (cl-inotify:inotify-event-wd event) *entries*)))
                                     (when entry
                                       (funcall (watch-entry-handler entry)
                                                (if filename
                                                    (fad:merge-pathnames-as-file (watch-entry-path entry) filename)
                                                    (watch-entry-path entry))))))

                          ;; In case the watch entries log stuff, we'll finish
                          ;; output after processing the events
                          (finish-output)))
               (finish-output)
               (cl-inotify:close-inotify *inotify*)
               (setf *current-thread* nil))))))
  (values))

(defun stop ()
  (with-open-file (stream *kill-path* :direction :output :if-exists :append)
    (write-line "KILL" stream))
  (values))

(defun add-entry (path handler)
  (let ((wd (cl-inotify:watch *inotify* path '(:modify))))
    (setf (gethash wd *entries*)
          (make-instance 'watch-entry :path path :handler handler))))

(defun remove-entry (path)
  (cl-inotify:unwatch *inotify* :pathname path)
  (loop for wd being the hash-key of *entries*
          using (hash-value entry)
        when (string-equal (namestring (watch-entry-path entry)) (namestring path))
          do (remhash wd *entries*))
  (values))

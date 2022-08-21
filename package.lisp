(defpackage #:trivial-file-watch
  (:nicknames :file-watch)
  (:use #:cl)
  (:export
   #:*current-thread*
   #:watch-entry
   #:watch-entry-path
   #:watch-entry-handler
   #:start
   #:stop
   #:add-entry
   #:remove-entry))

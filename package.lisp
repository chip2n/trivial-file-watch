(defpackage #:trivial-file-watch
  (:nicknames :file-watch)
  (:use #:cl)
  (:export
   #:*current-thread*
   #:start
   #:stop
   #:add-entry
   #:remove-entry))

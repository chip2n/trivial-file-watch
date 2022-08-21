(asdf:defsystem #:trivial-file-watch
  :description "Watch files for changes."
  :author "Andreas Arvidsson <andreas@arvidsson.io>"
  :license  "MIT"
  :version "0.0.1"
  :serial t
  :depends-on (#:bt-semaphore
               #:cl-inotify)
  :components ((:file "package")
               (:file "trivial-file-watch")))

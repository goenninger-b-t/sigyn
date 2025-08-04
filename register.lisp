;;; =====================================================================
;;;  ASDF REGISTERING
;;; =====================================================================

#+thingbone-production
(declaim (optimize (speed 3) (compilation-speed 0) (safety 1) (debug 1)))

(in-package :cl-user)

(eval-when (:load-toplevel :compile-toplevel :execute)
  (pushnew (make-pathname :directory (pathname-directory (parse-namestring *load-pathname*)))
           asdf:*central-registry* :test #'eql))

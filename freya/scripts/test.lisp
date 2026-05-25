;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — run the test suite; exit 0 on success, 1 on failure. Portable.
;;;
;;;   sbcl  --script scripts/test.lisp [release] [telemetry]
;;;   alisp -L       scripts/test.lisp -- telemetry                 ; AllegroCL

(require "asdf")

(let ((ql (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname))))
  (when (probe-file ql) (load ql)))

(let* ((here (or *load-pathname* *load-truename*))
       (root (uiop:pathname-parent-directory-pathname
              (uiop:pathname-directory-pathname here))))
  (pushnew root asdf:*central-registry* :test #'equal))

(defun setf-output-translations-for-profile ()
  "Send fasls to a per-profile cache dir (the fasl cache does not key on
*features*), so checked/release/telemetry builds never reuse each other's fasls."
  (let* ((tag (format nil "~:[checked~;release~]~:[~;-telemetry~]"
                      (member :freya-release   *features*)
                      (member :freya-telemetry *features*)))
         (dir (uiop:ensure-directory-pathname
               (merge-pathnames (format nil ".cache/freya/~a/" tag)
                                (user-homedir-pathname)))))
    (asdf:initialize-output-translations
     `(:output-translations :ignore-inherited-configuration (t (,dir :implementation))))))

(let ((args (uiop:command-line-arguments)))
  (when (member "release"   args :test #'string-equal) (pushnew :freya-release   *features*))
  (when (member "telemetry" args :test #'string-equal) (pushnew :freya-telemetry *features*)))

(setf-output-translations-for-profile)

(if (find-package "QL")
    (funcall (read-from-string "ql:quickload") "net.goenninger.freya/tests")
    (asdf:load-system "net.goenninger.freya/tests"))

(let ((ok (funcall (read-from-string "net.goenninger.freya.tests:run-all"))))
  (uiop:quit (if ok 0 1)))

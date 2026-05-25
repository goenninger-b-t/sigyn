;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — load the system in a chosen build profile (PLAN §17, ADR-0009).
;;; Portable: no implementation-specific code. AllegroCL is the target; this also
;;; runs on SBCL/CCL/ECL for CI.
;;;
;;;   sbcl  --script scripts/build.lisp [release] [telemetry] [strict]
;;;   alisp -L       scripts/build.lisp -- release strict          ; AllegroCL
;;;
;;; Args: release   → push :freya-release   (speed/safety-0 hot policy)
;;;       telemetry → push :freya-telemetry (built-in Prometheus metrics)
;;;       strict    → recompile Freya's own systems with WARNINGs fatal
;;;                   (the §17 type/perf compile-time gate)

(require "asdf")

;; Quicklisp (used in dev/CI to fetch declared dependencies), if installed.
(let ((ql (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname))))
  (when (probe-file ql) (load ql)))

;; Make this repository discoverable by ASDF.
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

(format t "~&; Freya build — release=~a telemetry=~a~%"
        (and (member :freya-release   *features*) t)
        (and (member :freya-telemetry *features*) t))

;; The fasl cache does NOT key on *features*; isolate output per build profile so
;; profiles can't contaminate each other's compiled files.
(setf-output-translations-for-profile)

;; Fetch dependencies and load our code in this profile.
(if (find-package "QL")
    (funcall (read-from-string "ql:quickload") "net.goenninger.freya")
    (asdf:load-system "net.goenninger.freya"))

;; §17 type/perf gate: force-recompile ONLY Freya's systems with non-style
;; WARNINGs fatal. Dependencies are already loaded, so their diagnostics don't count.
(when (member "strict" (uiop:command-line-arguments) :test #'string-equal)
  (let ((ours (remove-if-not
               (lambda (n) (uiop:string-prefix-p "net.goenninger.freya" n))
               (asdf:already-loaded-systems))))
    (format t "~&; strict recompile of ~d Freya systems (warnings fatal)~%" (length ours))
    (handler-bind ((warning (lambda (w)
                              (unless (typep w 'style-warning)
                                (format *error-output* "~&; FATAL — type/perf gate: ~a~%" w)
                                (uiop:quit 3)))))
      (asdf:load-system "net.goenninger.freya" :force ours))))

(format t "~&; Freya loaded OK.~%")
(uiop:quit 0)

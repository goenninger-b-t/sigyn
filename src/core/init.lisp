;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-

#+sigyn-production
(declaim (optimize (speed 3) (compilation-speed 0) (safety 1) (debug 1)))

(cl:in-package "NET.GOENNINGER.SIGYN.CORE")

;;; ---------------------------------------------------------------------------

(defparameter *load-sapnwrfc-libs-on-init* t)

(let ((libsapnwrfc-initialized nil))

  (defparameter lock-libsapnwrfc-initialized (bt:make-recursive-lock))

  (defun libsapnwrfc-init (&key (load-sapnwrfc-libs-on-init *load-sapnwrfc-libs-on-init* ))

    (bt:with-recursive-lock-held (lock-libsapnwrfc-initialized)

      ;; Load SAP RFC Libraries
      (if load-sapnwrfc-libs-on-init
	  (rfc-init))

      ;; Init completed
      (setq libsapnwrfc-initialized t)
      (values)))

  (defun libsapnwrfc-reset ()
    (bt:with-recursive-lock-held (lock-libsapnwrfc-initialized)
      (rfc-reset :unload-libs nil) ;; Note: this might leak memory in the SAP Netweaver RFC library ...
      ;; Reset completed
      (setq libsapnwrfc-initialized nil)))

  (defun libsapnwrfc-initialized-p ()
    (bt:with-recursive-lock-held (lock-libsapnwrfc-initialized)
      libsapnwrfc-initialized))
  )

(defun ensure-libsapnwrfc-initialized ()
  (if (not (libsapnwrfc-initialized-p))
      (libsapnwrfc-init))
  (libsapnwrfc-initialized-p))

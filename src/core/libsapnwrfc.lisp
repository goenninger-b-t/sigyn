;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-

#+sigyn-production
(declaim (optimize (speed 3) (compilation-speed 0) (safety 1) (debug 1)))

(cl:in-package "NET.GOENNINGER.SIGYN.CORE")

;;; ---------------------------------------------------------------------------

;; Do NOT hard-code a build-machine path here. A stale or attacker-writable
;; default directory pushed onto the foreign-library search path is a
;; library-planting / code-execution vector. The location must be supplied
;; explicitly via the GBT_SIGYN_SAPNWRFC_LIB_DIR environment variable or by
;; (setf (sapnwrfc-lib-dir) #p"...").
(defparameter *sapnwrfc-foreign-libdir* nil)

(defparameter *loaded-libs* nil)

(defun sapnwrfc-lib-dir ()
  (let ((dir (or (uiop:getenv "GBT_SIGYN_SAPNWRFC_LIB_DIR")
		 *sapnwrfc-foreign-libdir*)))
    (unless dir
      (error "SAP NW RFC library directory is not configured. Set the ~
GBT_SIGYN_SAPNWRFC_LIB_DIR environment variable to a trusted, ~
non-world-writable directory containing the SAP NW RFC SDK shared ~
libraries, or (setf (sapnwrfc-lib-dir) #p\"/path/to/nwrfcsdk/lib/\")."))
    dir))

(defun (setf sapnwrfc-lib-dir) (lib-dir)
  (setq *sapnwrfc-foreign-libdir* lib-dir))

(defparameter *sapnwrfc-foreign-libs*
  #+linux
  '("libicudata.so.50"
    "libicuuc.so.50"
    "libicui18n.so.50"
    "libsapucum.so"
    "libsapnwrfc.so")
  #-linux
  '())

(defun sapnwrfc-foreign-libs (&optional (lib-list *sapnwrfc-foreign-libs*))
  lib-list)

(defun load-sapnwrfc-libs (&optional (lib-list *sapnwrfc-foreign-libs*))
  (pushnew (sapnwrfc-lib-dir) cffi:*foreign-library-directories* :test #'equal)
  (loop for lib in lib-list
     do
       (let ((loaded-lib (cffi:load-foreign-library lib )))
	 (when loaded-lib
	   (pushnew loaded-lib *loaded-libs*)))))

(defun unload-sapnwrfc-libs ()
  (loop for lib in *loaded-libs*
     do
       (progn
	 (ignore-errors
	   (cffi:close-foreign-library lib))
	 (setq *loaded-libs* (remove lib *loaded-libs*)))))

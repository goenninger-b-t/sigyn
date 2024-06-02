;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-

#+sigyn-production
(declaim (optimize (speed 3) (compilation-speed 0) (safety 1) (debug 1)))

(cl:in-package "NET.GOENNINGER.SIGYN.CORE")

;;; ---------------------------------------------------------------------------

(defparameter *sapnwrfc-foreign-libdir*
  #p "/var/data/swdev/sigyn/extlibs/linux/nwrfc750P_8-70002752/nwrfcsdk/lib/")

(defparameter *loaded-libs* nil)

(defun sapnwrfc-lib-dir ()
  *sapnwrfc-foreign-libdir*)

(defun (setf sapnwrfc-lib-dir) (lib-dir)
  (setq *sapnwrfc-foreign-libdir* lib-dir))

(defparameter *sapnwrfc-foreign-libs*
  #+linux
  '("libicudecnumber.so"
    "libicudata.so.50"
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
       (let ((loaded-lib (cffi:load-foreign-library lib)))
	 (when loaded-lib
	   (pushnew loaded-lib *loaded-libs*)))))

(defun unload-sapnwrfc-libs ()
  (loop for lib in *loaded-libs*
     do
       (progn
	 (ignore-errors
	   (cffi:close-foreign-library lib))
	 (setq *loaded-libs* (remove lib *loaded-libs*)))))

;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; =====================================================================
;;;
;;; ███████ ██  ██████ ██    ██ ███    ██
;;; ██      ██ ██       ██  ██  ████   ██
;;; ███████ ██ ██   ███  ████   ██ ██  ██
;;;      ██ ██ ██    ██   ██    ██  ██ ██
;;; ███████ ██  ██████    ██    ██   ████
;;;
;;;  SIGYN provides CFFI-based Common Lisp bindings and a high-level API.
;;;
;;;  Copyright © 2020 by Gönninger B&T UG (haftungsbeschränkt), Germany
;;;  For licensing information see file license.md.
;;;
;;;  All Rights Reserved. German law applies exclusively in all cases.
;;;
;;;  Author: Frank Gönninger <frank.goenninger@goenninger.net>
;;;  Maintainer: Gönninger B&T UG (haftungsbeschränkt)
;;;              <support@goenninger.net>
;;;
;;; =====================================================================

#+sigyn-production
(declaim (optimize (speed 3) (compilation-speed 0) (safety 1) (debug 1)))
#-sigyn-production
(declaim (optimize (speed 1) (compilation-speed 0) (safety 3) (debug 3)))

(cl:in-package "NET.GOENNINGER.SIGYN.SAPNWRFC")

;;; ---------------------------------------------------------------------------

(defparameter *connection-max-inactive-time* 120) ;; seconds

(defclass connection ()
  ((connection-parameters
    :accessor connection-parameters
    :initarg :connection-parameters
    :initform (make-hash-table :test 'string=))
   (user-designator
    :reader user-designator
    :initarg :user-designator
    :initform (error "USER-DESIGNATOR required when instantiating an object of class SIGYN.SAPNWRFC:CONNECTION!"))
   (connection-handle
    :accessor connection-handle
    :initarg :connection-handle
    :initform (cffi:null-pointer))
   (last-used
    :accessor last-used
    :initform (local-time:now))
   (active-p
    :accessor active-p
    :initform nil)
   (connection-lock
    :reader connection-lock
    :initform (bt:make-recursive-lock (gensym "SAPNWRFC-CONNECTION-LOCK-")))))

(defmethod print-object ((self connection) stream)
  (print-unreadable-object (self stream :type t)
    (with-slots (user-designator active-p last-used) self
      (format stream ":USER-DESIGNATOR ~A :ACTIVE-P ~S :CONNECTED-P ~S :LAST-USED ~S"
	      user-designator
	      active-p
	      (connected-p self)
	      last-used))))

(defmacro with-connection-locked ((connection) &body body)
  `(bt:with-recursive-lock-held((connection-lock ,connection))
     (progn
       ,@body)))

(defmethod connection-parameter ((self connection) (param-name string))
  (gethash (string-upcase param-name) (connection-parameters self)))

(defmethod set-connection-parameter ((self connection) (param-name string) (value string))
  (setf (gethash (string-upcase param-name) (connection-parameters self)) value))

(defmethod connection-parameters-as-list ((self connection))
  (loop for key being the hash-keys in (connection-parameters self) using (hash-value value)
	collect (cons key value)))

(defmethod set-connection-parameters ((self connection) (parameter-cons-list list))
  (with-connection-locked (self)
    (loop for parameter in parameter-cons-list
	  do
	     (set-connection-parameter self (car parameter) (cdr parameter))))
  self)

(defmethod %do-connected-p ((self connection))
  (ensure-libsapnwrfc-initialized)
  (let ((connection-handle (connection-handle self)))
    (if (rfc-connection-handle-set-p connection-handle)
	(rfc-connection-handle-valid-p connection-handle))))

(defmethod %do-disconnect ((self connection))
  (if (not (cffi:null-pointer-p (connection-handle self)))
      (ignore-errors
       (rfc-close-connection (connection-handle self))))
  (setf (connection-handle self) (cffi:null-pointer)))

(defmethod %do-connect ((self connection))
  (setf (connection-handle self)
	(rfc-open-connection (connection-parameters-as-list self))))

(defmethod %do-ensure-connected ((self connection))
  (if (not (%do-connected-p self))
      (%do-connect self)))

(defmethod connected-p ((self connection))
  (with-connection-locked (self)
    (%do-connected-p self)))

(defmethod disconnect ((self connection))
  (with-connection-locked (self)
    (unwind-protect
	 (%do-disconnect self)
      (setf (last-used self) (local-time:now))))
  self)

(defmethod connect ((self connection) &key (force nil))
  (with-connection-locked (self)
    (unwind-protect
	 (cond
	   ((and (%do-connected-p self)
		 force)
	    (%do-disconnect self)
	    (%do-connect self))
	   ((not (connected-p self))
	    (%do-connect self)))
      (setf (last-used self) (local-time:now))))
  self)

(defmethod ensure-connected ((self connection))
  (with-connection-locked (self)
    (%do-ensure-connected self))
  self)

(defmethod force-reconnect ((self connection))
  (with-connection-locked (self)
    (%do-disconnect self)
    (%do-connect self))
  self)

(defmacro with-connection ((var connection) &body body)
  `(let ((,var ,connection))
     (check-type ,var connection)
     (with-connection-locked (,var)
       (%do-ensure-connected ,var)
       (setf (active-p ,var) t)
       (unwind-protect
	    (progn
	      ,@body)
	 (progn
	   (setf (last-used ,var) (local-time:now))
	   (setf (active-p ,var) nil))))))

(defmethod connection-outdated-p ((self connection) &optional (inactive-time-in-seconds *connection-max-inactive-time*))
  (not (or (active-p self)
	   (< (local-time:timestamp-difference
	       (local-time:now) (last-used self))
	      inactive-time-in-seconds))))

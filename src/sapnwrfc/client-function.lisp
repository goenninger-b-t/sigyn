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

;; (defmethod invoke ((self sapnwrfc-object) sapnwrfc-connection)
;;   (flet ((%%invoke (sapnwrfc-object sapnwrfc-connection)
;; 	   (ensure-connected sapnwrfc-connection)
;; 	   (with-connection (conn sapnwrfc-connection)
;; 	     (let* ((rfc-connection-handle (connection-handle conn))
;; 		    (rfc-func-handle       (rfc-function rfc-connection-handle (rfc-object-name sapnwrfc-object))))
;; 	       (client-object-write sapnwrfc-object rfc-func-handle)
;; 	       (rfc-invoke rfc-connection-handle rfc-func-handle)
;; 	       (client-object-read sapnwrfc-object rfc-func-handle)))
;; 	   sapnwrfc-object))
;;     (handler-case (%%invoke self sapnwrfc-connection)
;;       (error (caught-condition)
;; 	(log:error "SIGYN.SAPNWRFC: While invoking client function ~A: *** Caught error ~A: ~A !"
;; 		   (class-name (class-of self))
;; 		   caught-condition
;; 		   (format nil (slot-value caught-condition 'format-control) (slot-value caught-condition 'format-arguments)))
;; 	(values))
;;       (:no-error ()
;; 	(log:debug "SIGYN.SAPNWRFC: Invoking client function ~A successfully completed."
;; 		   (class-name (class-of self)))
;; 	(values)))
;;     self))


(defparameter *sapnwrfc-client-function-max-retries* 1)

(define-condition rfc-invoke-error (sigyn.core:rfc-error)
  ())

(defun %%do-invoke (self sapnwrfc-connection)
  (ensure-connected sapnwrfc-connection)
  (with-connection (conn sapnwrfc-connection)
    (let* ((rfc-connection-handle (connection-handle conn))
	   (rfc-func-handle       (rfc-function rfc-connection-handle (rfc-object-name self))))
      (client-object-write self rfc-func-handle)
      (rfc-invoke rfc-connection-handle rfc-func-handle)
      (client-object-read self rfc-func-handle)
      self)))

(defmethod invoke ((self sapnwrfc-object) sapnwrfc-connection)
  (let ((retries 0))
    (handler-case (%%do-invoke self sapnwrfc-connection)
      (rfc-error (caught-condition)
	(log:debug "SAPNWRFC RFC Error ~S occured for function ~S." caught-condition self)
	(incf retries)
	(if (> retries *sapnwrfc-client-function-max-retries*)
	    (progn
	      (log:debug "Max nr of retrries for function ~S exceeded." self)
	      (error 'rfc-exec-error :rfc-error-info (rfc-error-info caught-condition)))
	    (progn
	      (log:debug "SAPNWRFC Connection ~S: Force-reconnecting due to RFC error." sapnwrfc-connection)
	      (force-reconnect sapnwrfc-connection)
	      (log:debug "Invoking ~S again (retry nr ~S of max. ~S)." self retries *sapnwrfc-client-function-max-retries*)
	      (invoke self sapnwrfc-connection))))
      (error (caught-condition)
	(log:error "SIGYN.SAPNWRFC: While invoking client function ~A: *** Caught error ~A: ~A !"
		   (class-name (class-of self))
		   caught-condition
		   (format nil (slot-value caught-condition 'format-control) (slot-value caught-condition 'format-arguments)))
	self)
      (:no-error (result)
	(declare (ignore result))
	(log:debug "SIGYN.SAPNWRFC: Invoking client function ~A successfully completed."
		   (class-name (class-of self)))
	self))))

(defmacro define-client-function (class-name direct-superclasses direct-slots &rest options)
  `(eval-when (:compile-toplevel :load-toplevel :execute)
     (defclass ,class-name ,direct-superclasses ,direct-slots
       ,@options (:rfc-object-kind :rfc-function)
       (:metaclass sapnwrfc-object-class))
     (export ',class-name)
     (defmethod initialize-instance :after ((self ,class-name) &key)
       (closer-mop:set-funcallable-instance-function
	self
	(lambda (connection)
	  (invoke self connection)))
       self)))

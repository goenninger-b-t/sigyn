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

(defmethod client-object-write ((object sapnwrfc-object) rfc-container-handle &optional (slot-rfc-kind (list :importing :changing)))
  (let ((slot-kinds (alexandria:ensure-list slot-rfc-kind)))
    (loop for class in (closer-mop:class-precedence-list (class-of object))
	  do
	     (loop for slot in (closer-mop:class-direct-slots class)
		   when (typep slot 'sapnwrfc-object-slot)
		     do
			(let ((rfc-type       (sapnwrfc-object-slot-rfc-type slot))
			      (rfc-length     (sapnwrfc-object-slot-rfc-length slot))
			      (rfc-param-name (sapnwrfc-object-slot-rfc-param-name slot))
			      (rfc-kind       (sapnwrfc-object-slot-rfc-kind slot)))
			  (handler-case
			      (let ((value (slot-value object (closer-mop:slot-definition-name slot))))
				(if (member rfc-kind slot-kinds)
				    (param-set rfc-container-handle rfc-type rfc-param-name rfc-length value)
				    ))
			    (unbound-slot (condition)
			      (declare (ignore condition))))))))
  object)

(defmethod client-object-read ((object sapnwrfc-object) rfc-container-handle &optional (slot-rfc-kind (list :exporting :changing)))
  (let ((slot-kinds (alexandria:ensure-list slot-rfc-kind)))
    (loop for class in (closer-mop:class-precedence-list (class-of object))
	  do
	     (loop for slot in (closer-mop:class-direct-slots class)
		   when (typep slot 'sapnwrfc-object-slot)
		     do
			(let ((rfc-type       (sapnwrfc-object-slot-rfc-type slot))
			      (rfc-length     (sapnwrfc-object-slot-rfc-length slot))
			      (rfc-param-name (sapnwrfc-object-slot-rfc-param-name slot))
			      (rfc-kind       (sapnwrfc-object-slot-rfc-kind slot)))
			  (if (member rfc-kind slot-kinds)
			      (let ((value (param-get rfc-container-handle rfc-type rfc-param-name rfc-length)))
				(setf (slot-value object (closer-mop:slot-definition-name slot)) value)))))))
  object)

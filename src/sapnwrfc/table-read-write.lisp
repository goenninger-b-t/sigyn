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

(defparameter *initial-rfc-table-size* 16)
(defparameter *extend-rfc-table-size*  16)

(defmethod client-table-write ((object sapnwrfc-object) rfc-container-handle &optional (slot-rfc-kind (list :importing :changing)))
  (declare (ignore slot-rfc-kind))
  (let ((rfc-table-handle rfc-container-handle)
	(nr-rows (nr-entries object)))
    (rfc-delete-all-rows rfc-table-handle)
    (rfc-append-new-rows rfc-table-handle nr-rows)
    (rfc-move-to-first-row rfc-table-handle)
    (setf (rfc-handle object) rfc-table-handle)
    (loop for index from 0 below nr-rows
	  do
	     (client-table-row-write object index)))
  object)

(defmethod client-table-read ((object sapnwrfc-object) rfc-container-handle &optional (slot-rfc-kind (list :importing :changing)))
  (declare (ignore slot-rfc-kind))
  (let* ((rfc-table-handle rfc-container-handle)
	 (nr-rows (rfc-get-row-count rfc-table-handle)))
    (if (> nr-rows 0)
	(progn
	  (rfc-move-to-first-row rfc-table-handle)
	  (setf (rfc-handle object) rfc-table-handle)
	  (setf (rows object) (make-array nr-rows :adjustable nil :fill-pointer 0))
	  (loop for index from 0 below nr-rows
		do
		   (client-table-row-read object index)))))
  object)

(defun %do-client-table-row-read (self row-index)
  (rfc-move-to (rfc-handle self) row-index)
  (let* ((rfc-container-handle (rfc-get-current-row (rfc-handle self)))
	 (table-row-class (table-row-class self))
	 (row (make-instance table-row-class)))
    (loop for class in (closer-mop:class-precedence-list table-row-class)
	  do
	     (loop for slot in (closer-mop:class-direct-slots class)
		   when (typep slot 'sapnwrfc-object-slot)
		     do
			(let ((rfc-type       (sapnwrfc-object-slot-rfc-type slot))
			      (rfc-length     (sapnwrfc-object-slot-rfc-length slot))
			      (rfc-param-name (sapnwrfc-object-slot-rfc-param-name slot)))
			  (let ((value (param-get rfc-container-handle rfc-type rfc-param-name rfc-length)))
			    (setf (slot-value row (closer-mop:slot-definition-name slot)) value)))))
    (add-entry self row))
  self)


(defun %do-client-table-row-write (self row-index)
  (rfc-move-to (rfc-handle self) row-index)
  (let ((rfc-container-handle (rfc-get-current-row (rfc-handle self)))
	(object (aref (rows self) row-index)))
    (loop for class in (closer-mop:class-precedence-list (table-row-class self))
	  do
	     (loop for slot in (closer-mop:class-direct-slots class)
		   when (typep slot 'sapnwrfc-object-slot)
		     do
			(let ((rfc-type       (sapnwrfc-object-slot-rfc-type slot))
			      (rfc-length     (sapnwrfc-object-slot-rfc-length slot))
			      (rfc-param-name (sapnwrfc-object-slot-rfc-param-name slot)))
			  (handler-case
			      (let ((value (slot-value object (closer-mop:slot-definition-name slot))))
				(param-set rfc-container-handle rfc-type rfc-param-name rfc-length value))
			    (unbound-slot (condition)
			      (declare (ignore condition))))))))
  (values))

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

(defmacro define-table (class-name direct-superclasses direct-slots &rest options)

  `(eval-when (:compile-toplevel :load-toplevel :execute)

     (defclass ,(intern (format nil "%%~A-ROW" class-name)) ,direct-superclasses ,direct-slots
       ,@options (:rfc-object-kind :rfc-table-row)
       (:metaclass sapnwrfc-object-class))

     (defclass ,class-name (sapnwrfc-object)
       ((rows :accessor rows :initarg :rows :initform (make-array *initial-rfc-table-size* :adjustable t :fill-pointer 0)))
       ,@options (:rfc-object-kind :rfc-table)
       (:metaclass sapnwrfc-object-class))

     (export ',class-name)

     (defmethod table-row-class ((self ,class-name))
       (find-class ',(intern (format nil "%%~A-ROW" class-name))))

     (defmethod make-and-add-entry ((self ,class-name) &rest args)
       (let ((row (apply 'make-instance ',(intern (format nil "%%~A-ROW" class-name)) args)))
	 (vector-push-extend row (rows self) *extend-rfc-table-size*)))

     (defmethod add-entry ((self ,class-name) (row ,(intern (format nil "%%~A-ROW" class-name))))
       (vector-push-extend row (rows self) *extend-rfc-table-size*))

     (defmethod nr-entries ((self ,class-name))
       (length (rows self)))

     (defmethod clear-table ((self ,class-name))
       (setf (rows self) (make-array *initial-rfc-table-size* :adjustable t :fill-pointer 0)))

     (defmethod client-table-row-write ((self ,class-name) row-index)
       (%do-client-table-row-write self row-index)
       self)

     (defmethod client-table-row-read ((self ,class-name) row-index)
       (%do-client-table-row-read self row-index)
       self)
     ))

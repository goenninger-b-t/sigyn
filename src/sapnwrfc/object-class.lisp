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

(defclass sapnwrfc-object-class (closer-mop:funcallable-standard-class)
  ((rfc-object-name :accessor sapnwrfc-object-class-rfc-object-name :initarg :rfc-object-name :initform nil)
   (rfc-object-kind :accessor sapnwrfc-object-class-rfc-object-kind :initarg :rfc-object-kind :initform nil)))

(defmethod aclmop:validate-superclass ((class sapnwrfc-object-class) (superclass t))
  nil)

(defmethod aclmop:validate-superclass ((class standard-class) (superclass sapnwrfc-object-class))
  t)

(defmethod aclmop:validate-superclass ((class sapnwrfc-object-class) (superclass standard-class))
  t)

(defmethod aclmop:validate-superclass ((class sapnwrfc-object-class) (superclass sapnwrfc-object-class))
  t)

(defclass sapnwrfc-object-slot (closer-mop:standard-direct-slot-definition)
  ((rfc-type
    :accessor sapnwrfc-object-slot-rfc-type
    :initarg :rfc-type
    :initform nil)
   (rfc-length
    :accessor sapnwrfc-object-slot-rfc-length
    :initarg :rfc-length
    :initform nil)
   (rfc-kind
    :accessor sapnwrfc-object-slot-rfc-kind
    :initarg :rfc-kind
    :initform :changing) ;; { :importing | :changing | :exporting
   (rfc-param-name
    :accessor sapnwrfc-object-slot-rfc-param-name
    :initarg :rfc-param-name
    :initform nil))
  (:documentation "Superclass for sapnwrfc-object-class slots with SAP Netweaver RFC options"))

(defmethod aclmop:direct-slot-definition-class ((class sapnwrfc-object-class) &rest initargs)
  (declare (ignore initargs))
  (find-class 'sapnwrfc-object-slot))

(defclass sapnwrfc-object ()
  ((rfc-handle :accessor rfc-handle :initarg :rfc-handle :initform nil)))

;; (defmethod initialize-instance :around ((class sapnwrfc-object-class)
;;                                         &rest rest &key direct-superclasses)
;;   (apply #'call-next-method
;;          class
;;          :direct-superclasses
;;          (append direct-superclasses (list (find-class 'sapnwrfc-object)))
;;          rest))

(defmethod closer-mop:compute-class-precedence-list ((class sapnwrfc-object-class))
  (cons (find-class 'sapnwrfc-object) (call-next-method class)))

(defmethod rfc-object-name ((self sapnwrfc-object))
  (first (sapnwrfc-object-class-rfc-object-name (class-of self))))

(defmethod rfc-object-kind ((self sapnwrfc-object))
  (first (sapnwrfc-object-class-rfc-object-kind (class-of self))))

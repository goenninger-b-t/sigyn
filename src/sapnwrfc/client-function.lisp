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

(defmethod invoke ((self sapnwrfc-object) sapnwrfc-connection)
  (ensure-connected sapnwrfc-connection)
  (with-connection (conn sapnwrfc-connection)
    (let* ((rfc-connection-handle (connection-handle conn))
	   (rfc-func-handle       (rfc-function rfc-connection-handle (rfc-object-name self))))
      (client-object-write self rfc-func-handle)
      (rfc-invoke rfc-connection-handle rfc-func-handle)
      (client-object-read self rfc-func-handle)))
  self)

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

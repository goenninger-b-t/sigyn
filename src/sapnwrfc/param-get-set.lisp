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
;;; --- SETTERS ---

;; - :RFC-CHAR -

(defmethod param-set (rfc-container-handle (rfc-type (eql :rfc-char)) rfc-param-name rfc-length (value string))
  (rfc-set-chars rfc-container-handle rfc-param-name value rfc-length))

(defmethod param-set (rfc-container-handle (rfc-type (eql :rfc-char)) rfc-param-name rfc-length (value null))
  (rfc-set-chars rfc-container-handle rfc-param-name "" rfc-length))

(defmethod param-set (rfc-container-handle (rfc-type (eql :rfc-char)) rfc-param-name rfc-length (value number))
  (rfc-set-chars rfc-container-handle rfc-param-name (format nil "~S" value) rfc-length))

(defmethod param-set (rfc-container-handle (rfc-type (eql :rfc-char)) rfc-param-name rfc-length (value uuid:uuid))
  (rfc-set-chars rfc-container-handle rfc-param-name (format nil "~S" value) rfc-length))

;; - :RFC-NUMC -

(defmethod param-set (rfc-container-handle (rfc-type (eql :rfc-numc)) rfc-param-name rfc-length (value string))
  (rfc-set-chars rfc-container-handle rfc-param-name value rfc-length))

(defmethod param-set (rfc-container-handle (rfc-type (eql :rfc-numc)) rfc-param-name rfc-length (value null))
  (declare (ignore rfc-container-handle rfc-param-name rfc-length))
  :rfc-ok)

(defmethod param-set (rfc-container-handle (rfc-type (eql :rfc-numc)) rfc-param-name rfc-length (value number))
  (declare (ignore rfc-length))
  (rfc-set-int rfc-container-handle rfc-param-name value))

;; - :RFC-INT4 -

(defmethod param-set (rfc-container-handle (rfc-type (eql :rfc-int4)) rfc-param-name rfc-length (value null))
  (declare (ignore rfc-container-handle rfc-param-name rfc-length))
  :rfc-ok)

(defmethod param-set (rfc-container-handle (rfc-type (eql :rfc-int4)) rfc-param-name rfc-length (value number))
  (rfc-set-int rfc-container-handle rfc-param-name value rfc-length))

;; -  -

(defmethod param-set (rfc-container-handle (rfc-type symbol) rfc-param-name rfc-length value)
  (declare (ignore rfc-length))
  (if value
      (progn
	(check-type value sapnwrfc-object)
	(let ((rfc-object-kind (rfc-object-kind value)))
	  (cond
	    ;; WRITE RFC STRUCTURE
	    ((eql rfc-object-kind :rfc-structure)
	     (client-structure-write value (rfc-get-structure rfc-container-handle rfc-param-name)))
	    ;; WRITE RFC TABLE
	    ((eql rfc-object-kind :rfc-table)
	     (client-table-write value (rfc-get-table rfc-container-handle rfc-param-name)))
	    (t nil)
	    )))))



;;; --- GETTERS ---

;; - :RFC-CHAR -

(defmethod param-get (rfc-container-handle (rfc-type (eql :rfc-char)) rfc-param-name rfc-length)
  (rfc-get-chars rfc-container-handle rfc-param-name rfc-length))

;; - :RFC-NUMC -

(defmethod param-get (rfc-container-handle (rfc-type (eql :rfc-numc)) rfc-param-name rfc-length)
  (rfc-get-chars rfc-container-handle rfc-param-name rfc-length))

;; - :RFC-INT4 -

(defmethod param-get (rfc-container-handle (rfc-type (eql :rfc-int4)) rfc-param-name rfc-length)
  (declare (ignore rfc-length))
  (rfc-get-int rfc-container-handle rfc-param-name))

;; -  -

(defmethod param-get (rfc-container-handle (rfc-type symbol) rfc-param-name rfc-length)
  (declare (ignore rfc-length))
  (let* ((value (make-instance rfc-type))
	 (rfc-object-kind (rfc-object-kind value)))
    (cond
      ;; READ RFC STRUCTURE
      ((eql rfc-object-kind :rfc-structure)
       (client-structure-read value (rfc-get-structure rfc-container-handle rfc-param-name)))
      ;; READ RFC TABLE
      ((eql rfc-object-kind :rfc-table)
       (client-table-read value (rfc-get-table rfc-container-handle rfc-param-name)))
      (t nil)
      )
    value))

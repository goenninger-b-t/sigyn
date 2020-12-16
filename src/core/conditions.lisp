;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-

#+sigyn-production
(declaim (optimize (speed 3) (compilation-speed 0) (safety 1) (debug 1)))

(cl:in-package "NET.GOENNINGER.SIGYN.CORE")

;;; ---------------------------------------------------------------------------

;;; CONDITION DEFINITIONS

(defclass rfc-condition (condition)
  ((rfc-error-info :reader rfc-error-info :initarg :rfc-error-info :initform nil)))

(declaim (inline rfc-error-group-to-string))
(defun rfc-error-group-to-string (rfc-error-group)
  (format nil "~A" (serapeum:string-replace-all "-" (format nil "~A" rfc-error-group) " ")))

(declaim (inline format-rfc-error-report))
(defun format-rfc-error-report (rfc-condition)
  (let ((r (rfc-error-info rfc-condition)))
    (format nil "SIGYN: SAP Netweaver RFC ~A ERROR !~%-> Code: ~S,~%-> Group: ~S,~%-> Key: ~A,~%-> Message: \"~A\",~%-> ABAP Msg Class: \"~A\",~%-> ABAP Msg Type: \"~A\",~%-> ABAP Msg Number: \"~A\",~%-> ABAP Msg V1: \"~A\",~%-> ABAP Msg V2: \"~A\",~%-> ABAP Msg V3: \"~A\",~%-> ABAP MSg V4: \"~A\""
	    (rfc-error-group-to-string (group r))
	    (code r)
	    (group r)
	    (key r)
	    (message r)
	    (abap-msg-class r)
	    (abap-msg-type r)
	    (abap-msg-number  r)
	    (abap-msg-v1 r)
	    (abap-msg-v2 r)
	    (abap-msg-v3 r)
	    (abap-msg-v4 r))))

(define-condition rfc-error (rfc-condition error)
  ()
  (:report
   (lambda (c s)
     (format s (format-rfc-error-report c)))))

;;; For eeach SAP NW RFC Error Group an indiviual condition is provided

(define-condition abap-application-failure (rfc-error)
  ())

(define-condition abap-runtime-failure (rfc-error)
  ())

(define-condition logon-failure (rfc-error)
  ())

(define-condition communication-failure (rfc-error)
  ())

(define-condition external-runtime-failure (rfc-error)
  ())

(define-condition external-application-failure (rfc-error)
  ())

(define-condition external-authorization-failure (rfc-error)
  ())

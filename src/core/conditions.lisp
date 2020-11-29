;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-

#+sigyn-production
(declaim (optimize (speed 3) (compilation-speed 0) (safety 1) (debug 1)))

(cl:in-package "NET.GOENNINGER.SIGYN.CORE")

;;; ---------------------------------------------------------------------------

;;; CONDITION DEFINITIONS

(defclass rfc-condition (condition)
  ((rfc-error-info :reader rfc-error-info :initarg :rfc-error-info :initform nil)))

(define-condition rfc-error (rfc-condition error)
  ()
  (:report
   (lambda (c s)
     (let ((r (rfc-error-info c)))
       (format s "SIGYN: SAP Netweaver RFC error !~%-> Code: ~S,~%-> Group: ~S,~%-> Key: ~A,~%-> Message: \"~A\",~%-> ABAP Msg Class: \"~A\",~%-> ABAP Msg Type: \"~A\",~%-> ABAP Msg Number: \"~A\",~%-> ABAP Msg V1: \"~A\",~%-> ABAP Msg V2: \"~A\",~%-> ABAP Msg V3: \"~A\",~%-> ABAP MSg V4: \"~A\""
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
	       (abap-msg-v4 r))))))

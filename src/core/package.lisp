;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; =====================================================================
;;;
;;;  T H I N G B O N E  -   The BackBONE for all THINGs
;;;
;;;  A data-centric messaging middleware for real-time application
;;;  integration and IoT integration based on OMG DDS and Common Lisp.
;;;
;;;  Copyright © 2019 by Gönninger B&T UG (haftungsbeschränkt), Germany
;;;  For licensing information see file license.md.
;;;
;;;  All Rights Reserved. German law applies exclusively in all cases.
;;;
;;;  Author: Frank Gönninger <frgo@me.com>
;;;  Maintainer: Gönninger B&T UG (haftungsbeschränkt)
;;;              <support@goenninger.net>
;;;
;;; =====================================================================
;;;
;;;  SAP RFC BINDINGS (libsapnwrfc)
;;;
;;; =====================================================================

#+thingbone-production
(declaim (optimize (speed 3) (compilation-speed 0) (safety 1) (debug 1)))

(uiop:define-package "NET.GOENNINGER.SIGYN.CORE"
    (:use "COMMON-LISP")
  (:nicknames "SIGYN.CORE")
  (:export

   #:libsapnwrfc-init
   #:libsapnwrfc-reset
   #:libsapnwrfc-initialized-p
   #:ensure-libsapnwrfc-initialized
   #:sapnwrfc-lib-dir

   #:rfc-rc
   #:rfc-connection-handle

   #:set-*rfc-sap-uc-encoding*
   #:rfc-sap-uc-encoding
   #:rfc-sap-uc-char-size
   #:sap-uc-string-to-lisp
   #:lisp-to-sap-uc-string
   #:with-lisp-to-sap-uc-string
   #:with-lisp-to-sap-uc-strings

   #:set-*rfc-client-connection-parameters*
   #:set-*rfc-server-connection-parameters*
   #:with-rfc-connection-parameter
   #:set-rfc-connection-parameter
   #:zero-rfc-connection-parameter
   #:print-rfc-connection-parameter
   #:free-rfc-connection-parameter-contents
   #:with-rfc-connection-parameters

   #:rfc-get-version

   #:with-rfc-error-info
   #:rfc-error-info
   #:set-sap-error-info-from-rfc-error-info
   #:log-rfc-error
   #:check-and-handle-rfc-error-info

   #:signal-rfc-invalid-parameter

   #:rfc-is-connection-handle-valid
   #:rfc-connection-handle-set-p
   #:rfc-connection-handle-valid-p
   #:rfc-close-connection
   #:rfc-open-connection
   #:ensure-rfc-connection
   #:rfc-get-connection-attributes

   #:rfc-init
   #:rfc-reset

   #:rfc-ping

   #:rfc-get-function-desc
   #:rfc-create-function
   #:rfc-destroy-function
   #:rfc-function
   #:rfc-invoke

   #:rfc-get-structure
   #:rfc-get-table
   #:rfc-get-current-row
   #:rfc-append-new-row
   #:rfc-append-new-rows
   #:rfc-insert-new-row
   #:rfc-append-row
   #:rfc-insert-row
   #:rfc-delete-current-row
   #:rfc-delete-all-rows
   #:rfc-move-to-first-row
   #:rfc-move-to-last-row
   #:rfc-move-to-next-row
   #:rfc-move-to-previous-row
   #:rfc-move-to
   #:rfc-get-row-count
   #:rfc-get-string
   #:rfc-get-chars
   #:rfc-get-int
   #:rfc-get-float
   #:rfc-set-chars
   #:rfc-set-string
   #:rfc-set-int
   #:rfc-set-float

   #:rfc-install-server-function
   #:rfc-register-server
   #:rfc-listen-and-dispatch

   #:rfc-condition
   #:rfc-error
   #:abap-application-failure
   #:abap-runtime-failure
   #:logon-failure
   #:communication-failure
   #:external-runtime-failure
   #:external-application-failure
   #:external-authorization-failure

   #:ensure-member

   ))

;;; ---------------------------------------------------------------------------

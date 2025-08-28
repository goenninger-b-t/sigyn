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

(uiop:define-package "NET.GOENNINGER.SIGYN.SAPNWRFC"
    (:use "CLOSER-COMMON-LISP" "NET.GOENNINGER.SIGYN.CORE")
  (:nicknames "SIGYN.SAPNWRFC")
  (:export

   #:connection
   #:with-connection-locked
   #:connection-parameter
   #:set-connection-parameter
   #:connection-parameters-as-list
   #:set-connection-parameters
   #:connected-p
   #:connect
   #:disconnect
   #:ensure-connected
   #:force-reconnect
   #:with-connection
   #:connection-outdated-p

   #:sapnwrfc-object-class
   #:sapnwrfc-object
   #:rfc-object-name
   #:rfc-object-kind

   #:invoke
   #:define-client-function

   #:client-object-write
   #:client-object-read

   #:param-set
   #:param-get

   #:define-structure

   #:client-structure-write
   #:client-structure-read

   #:define-table
   #:table-row-class
   #:make-and-add-entry
   #:add-entry
   #:nr-entries
   #:clear-table
   #:client-table-row-write
   #:client-table-row-read
   #:rows

   ))

;;; ---------------------------------------------------------------------------

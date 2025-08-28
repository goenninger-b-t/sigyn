;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-

#+sigyn-production
(declaim (optimize (speed 3) (compilation-speed 0) (safety 1) (debug 1)))

(cl:in-package "NET.GOENNINGER.SIGYN.CORE")

;;; ---------------------------------------------------------------------------

(eval-when (:load-toplevel :execute :compile-toplevel)

  #-linux
  (error "These SAPNWRFC bindings only work on Linux platforms.")

  (pushnew 'sap-on-linux cl:*features*)
  (pushnew 'sap-on-lin cl:*features*)
  (pushnew 'sap-on-unix cl:*features*)

  (defconstant +sap-short-bytes+ 2)
  (defconstant +sap-llong-is-long+ nil)
  (defconstant +sap-llong-is-long-long+ t)
  (defconstant +sap-llong-bytes+ 8)
  (defconstant +sap-ullong-bytes+ 8)
  (defconstant +sap-date-ln+ 8)
  (defconstant +sap-time-ln+ 6)
  (defconstant +decf-16-max-strlen+ 25)
  (defconstant +decf-34-max-strlen+ 43)
  (defconstant +rfc-tid-ln+ 24)
  (defconstant +rfc-unitid-ln+ 32)
  (defconstant +sap-uc-ln+ 2)
  (defconstant +sap-uc-sf+ 1)
  (defconstant +sap-uc-align-mask+ 1)

  (defconstant +unicode-id+ "@(#)     Unicode")

  ) ;; - ] eval-when

(cffi:defctype sap-raw :uchar)
(cffi:defctype sap-sraw :char)

(cffi:defctype sap-ushort :ushort)
(cffi:defctype sap-short :short)

(cffi:defctype sap-uint :uint)
(cffi:defctype sap-int :int)

(cffi:defctype sap-llong :llong)
(cffi:defctype sap-ullong :ullong)

(cffi:defctype sap-bool :uchar)

(cffi:defctype sap-double :float)

(cffi:defctype sap-date (:array sap-char +sap-date-ln+))
(cffi:defctype sap-time (:array sap-char +sap-time-ln+))

(cffi:defctype sap-bcd sap-raw)

(cffi:defcstruct sap-uuid
  (a sap-uint)
  (b sap-ushort)
  (c sap-ushort)
  (d (:array sap-raw 8)))

(cffi:defctype platform-max-t sap-double)

(cffi:defcunion sap-max-align-t
  (align-1 :long)
  (align-2 :double)
  (align-3 (:pointer :void))
  (align-4 platform-max-t))


(cffi:defctype sap-char :char)
(cffi:defctype sap-uc (:array :char #.+sap-uc-ln+))

(cffi:defcunion dec-float-16
  (bytes (:array sap-raw 8))
  (align sap-double))

(cffi:defcunion dec-float-34
  (bytes (:array sap-raw 16))
  (align (:union sap-max-align-t)))

(cffi:defcenum dec-float-raw-len
  (dec-float-16-raw-len 8)
  (dec-float-34-raw-len 16))

(cffi:defctype dec-float-16-raw (:array sap-raw 8))
(cffi:defctype dec-float-34-raw (:array sap-raw 16))

(cffi:defcenum dec-float-len
  (:dec-float-16-len 8)
  (:dec-float-34-len 16))

(cffi:defctype dec-float-16-buff (:array sap-uc +decf-16-max-strlen+))
(cffi:defctype dec-float-34-buff (:array sap-uc +decf-34-max-strlen+))

(cffi:defctype sap-uint-ptr :ulong)

(pushnew :sap-with-icu-coll cl:*features*)
(pushnew :sap-with-icu-bidi cl:*features*)
(pushnew :sap-with-icu-bidi cl:*features*)
(pushnew :sap-with-icu-shaping cl:*features*)
(pushnew :sap-with-icu-break cl:*features*)
(pushnew :sap-with-icu-norm cl:*features*)
(pushnew :sap-with-icu-trans cl:*features*)
(pushnew :sap-with-icu-idna cl:*features*)
(pushnew :sap-with-icu-cal cl:*features*)

(pushnew :sap-with-icu-ctype cl:*features*)

#+ (or sap-with-icu-coll sap-with-icu-bidi sap-with-icu-shaping
       sap-with-icu-break sap-with-icu-norm sap-with-icu-trans
       sap-with-icu-idna sap-with-icu-cal)
(pushnew :sap-with-icu cl:*features*)

(pushnew :sap-with-u16lib cl:*features*)
(pushnew :sap-with-u16lib-linked cl:*features*)

(pushnew :sap-uc-is-2b cl:*features*)
(pushnew :sap-uc-us-utf16 cl:*features*)

(pushnew :sap-with-int-little-endian cl:*features*)

(pushnew :sap-uc-is-2b-l cl:*features*)
(pushnew :sap-uc-is-utf16-l cl:*features*)

(cffi:defctype sap-u2 sap-ushort)

(cffi:defctype sap-u4 sap-uint)
(cffi:defctype sap-b8 :char)
(cffi:defctype sap-utf8 :uchar)
(cffi:defctype sap-cesu8 :uchar)
(cffi:defctype sap-utf7 :uchar)
(cffi:defctype sap-a7 :char)
(cffi:defctype sap-b7 :char)
(cffi:defctype sap-e8 :uchar)
(cffi:defctype sap-uc-mb :char)

(cffi:defctype icu-bool :char)

(cffi:defctype rfc-int8 :llong)
(cffi:defctype rfc-char sap-uc)
(cffi:defctype rfc-num sap-char)
(cffi:defctype rfc-byte sap-raw)
(cffi:defctype rfc-bcd sap-raw)
(cffi:defctype rfc-int1 sap-raw)
(cffi:defctype rfc-int2 :short)
(cffi:defctype rfc-int :int)
(cffi:defctype rfc-float :double)
(cffi:defctype rfc-date (:array rfc-char 8))
(cffi:defctype rfc-time (:array rfc-char 6))
(cffi:defctype rfc-decf16 (:union dec-float-16))
(cffi:defctype rfc-decf34 (:union dec-float-34))
(cffi:defctype rfc-utclong rfc-int8)
(cffi:defctype rfc-utcsecond rfc-int8)
(cffi:defctype rfc-utcminute rfc-int8)
(cffi:defctype rfc-dtday :int)
(cffi:defctype rfc-dtweek :int)
(cffi:defctype rfc-dtmonth :int)
(cffi:defctype rfc-tsecond :int)
(cffi:defctype rfc-tminute :short)
(cffi:defctype rfc-cday :short)

(cffi:defctype rfc-tid (:array sap-uc #.(1+ +rfc-tid-ln+)))
(cffi:defctype rfc-unitid (:array sap-uc #.(1+ +rfc-unitid-ln+)))

(cffi:defcenum rfctype
  (:rfctype-char 0)
  (:rfctype-date 1)
  (:rfctype-bcd 2)
  (:rfctype-time 3)
  (:rfctype-byte 4)
  (:rfctype-table 5)
  (:rfctype-num 6)
  (:rfctype-float 7)
  (:rfctype-int 8)
  (:rfctype-int2 9)
  (:rfctype-int1 10)
  (:rfctype-null 14)
  (:rfctype-abapobject 16)
  (:rfctype-structure 17)
  (:rfctype-decf16 23)
  (:rfctype-decf34 24)
  (:rfctype-xmldata 28)
  (:rfctype-string 29)
  (:rfctype-xstring 30)
  :rfctype-int8
  :rfctype-utclong
  :rfctype-utcsecond
  :rfctype-utcminute
  :rfctype-dtday
  :rfctype-dtweek
  :rfctype-dtmonth
  :rfctype-tsecond
  :rfctype-cday
  :rfctype-box
  :rfctype-generic-box
  :rfctype-max-value)

(cffi:defcenum rfc-rc
  :rfc-ok
  :rfc-communication-failure
  :rfc-logon-failure
  :rfc-abap-runtime-failure
  :rfc-abap-message
  :rfc-abap-exception
  :rfc-closed
  :rfc-canceled
  :rfc-timeout
  :rfc-memory-insufficient
  :rfc-version-mismatch
  :rfc-invalid-protocol
  :rfc-serialization-failure
  :rfc-invalid-handle
  :rfc-retry
  :rfc-external-failure
  :rfc-executed
  :rfc-not-found
  :rfc-not-supported
  :rfc-illegal-state
  :rfc-invalid-parameter
  :rfc-codepage-conversion-failure
  :rfc-conversion-failure
  :rfc-buffer-too-small
  :rfc-table-move-bof
  :rfc-table-move-eof
  :rfc-start-sapgui-failure
  :rfc-abap-class-exception
  :rfc-unknown-error
  :rfc-authorization-failure
  :rfc-authentication-failure
  :rfc-cryptolib-failure
  :rfc-io-failure
  :rfc-locking-failure
  :rfc-rc-max-value)

(cffi:defcenum rfc-error-group
  :ok
  :abap-application-failure
  :abap-runtime-failure
  :logon-failure
  :communication-failure
  :external-runtime-failure
  :external-application-failure
  :external-authorization-failure
  :external-authentication-failure
  :cryptolib-failure
  :locking-failure)

;; (cffi:defcstruct rfc-error-info
;;   (code rfc-rc)
;;   (group rfc-error-group)
;;   (key (:array sap-uc #. (* 128 +sap-uc-ln+)))
;;   (message (:array sap-uc #. (* 512 +sap-uc-ln+)))
;;   (abap-msg-class (:array sap-uc #. (* 21 +sap-uc-ln+)))
;;   (abap-msg-type (:array sap-uc #. (* 2 +sap-uc-ln+)))
;;   (abap-msg-number (:array sap-uc #. (* 4 +sap-uc-ln+)))
;;   (abap-msg-v1 (:array sap-uc #. (* 51 +sap-uc-ln+)))
;;   (abap-msg-v2 (:array sap-uc #. (* 51 +sap-uc-ln+)))
;;   (abap-msg-v3 (:array sap-uc #. (* 51 +sap-uc-ln+)))
;;   (abap-msg-v4 (:array sap-uc #. (* 51 +sap-uc-ln+))))

(cffi:defcstruct rfc-error-info
  (code rfc-rc)
  (group rfc-error-group)
  (key (:array sap-uc 128))
  (message (:array sap-uc 512))
  (abap-msg-class (:array sap-uc 21))
  (abap-msg-type (:array sap-uc 2))
  (abap-msg-number (:array sap-uc 4))
  (abap-msg-v1 (:array sap-uc 51))
  (abap-msg-v2 (:array sap-uc 51))
  (abap-msg-v3 (:array sap-uc 51))
  (abap-msg-v4 (:array sap-uc 51)))


(cffi:defcstruct rfc-attributes
  (dest (:array sap-uc 65))
  (host (:array sap-uc 101))
  (partner-host (:array sap-uc 101))
  (sys-number (:array sap-uc 3))
  (sys-id (:array sap-uc 9))
  (client (:array sap-uc 4))
  (user (:array sap-uc 13))
  (language (:array sap-uc 3))
  (trace (:array sap-uc 2))
  (iso-language (:array sap-uc 3))
  (codepage (:array sap-uc 5))
  (partner-codepage (:array sap-uc 5))
  (rfc-role (:array sap-uc 2))
  (type (:array sap-uc 2))
  (partner-type (:array sap-uc 2))
  (rel (:array sap-uc 5))
  (partner-rel (:array sap-uc 5))
  (kernel-rel (:array sap-uc 5))
  (cpic-conv-id (:array sap-uc 9))
  (prog-name (:array sap-uc 129))
  (partner-bytes-per-char (:array sap-uc 2))
  (partner-system-codepage (:array sap-uc 5))
  (partner-ip (:array sap-uc 16))
  (partner-ipv6 (:array sap-uc 46))
  (reserved (:array sap-uc 17)))

(cffi:defctype p-rfc-attributes (:pointer (:struct rfc-attributes)))

(cffi:defcstruct rfc-security-attributes
  (function-name (:pointer sap-uc))
  (sys-id (:pointer sap-uc))
  (client (:pointer sap-uc))
  (user (:pointer sap-uc))
  (prog-name (:pointer sap-uc))
  (snc-name (:pointer sap-uc))
  (sso-ticket (:pointer sap-uc))
  (snc-acl-key (:pointer sap-uc))
  (snc-acl-key-length :uint))

(cffi:defctype p-rfc-security-attributes (:pointer (:struct rfc-security-attributes)))

(cffi:defcstruct rfc-unit-attributes
  (kernel-trace :short)
  (sat-trace :short)
  (unit-history :short)
  (lock :short)
  (no-commit-check :short)
  (user (:array sap-uc 13))
  (client (:array sap-uc 4))
  (t-code (:array sap-uc 21))
  (program (:array sap-uc 41))
  (hostname (:array sap-uc 41))
  (sending-date rfc-date)
  (sending-time rfc-time))


(cffi:defcstruct rfc-unit-identifier
  (unit-type sap-uc)
  (unit-id rfc-unitid))

(cffi:defcenum rfc-unit-state
  :rfc-unit-not-found
  :rfc-unit-in-process
  :rfc-unit-committed
  :rfc-unit-rolled-back
  :rfc-unit-confirmed)

(cffi:defctype rfc-abap-name (:array rfc-char 31))
(cffi:defctype rfc-parameter-defvalue (:array rfc-char 31))
(cffi:defctype rfc-parameter-text (:array rfc-char 80))

(cffi:defcenum rfc-call-type
  :rfc-synchrnonous
  :rfc-transactional
  :rfc-queued
  :rfc-background-unit)

(cffi:defcstruct rfc-server-context
  (type rfc-call-type)
  (tid rfc-tid)
  (unit-identifier (:pointer (:struct rfc-unit-identifier)))
  (unit-attributes (:pointer (:struct rfc-unit-attributes)))
  (is-stateful :uint)
  (session-id (:array sap-uc 33))
  (queue-names-count :uint)
  (queue-names (:pointer (:pouinter sap-uc))))

(cffi:defcenum rfc-authentication-type
  :rfc-auth-none
  :rfc-auth-basic
  :rfc-auth-x509
  :rfc-auth-sso)

(cffi:defcstruct rfc-certificate-data-struct
  (subject (:pointer sap-uc))
  (issuer (:pointer sap-uc))
  (valid-to sap-ullong)
  (valid-from sap-ullong)
  (signature (:poiunter sap-uc))
  (next (:pointer (:struct rfc-certificate-data-struct))))


(cffi:defcstruct rfc-type-desc-handle-struct
  (handle (:pointer :void)))

(cffi:defctype rfc-type-desc-handle (:pointer (:struct rfc-type-desc-handle-struct)))

(cffi:defcstruct rfc-function-desc-handle-struct
  (handle (:pointer :void)))

(cffi:defctype rfc-function-desc-handle (:pointer (:struct rfc-function-desc-handle-struct)))

(cffi:defcstruct rfc-class-desc-handle-struct
  (handle (:pointer :void)))

(cffi:defctype rfc-class-desc-handle (:pointer (:struct rfc-class-desc-handle-struct)))

(cffi:defcstruct rfc-data-container
  (handle (:pointer :void)))

(cffi:defctype data-container-handle (:pointer (:struct rfc-data-container)))
(cffi:defctype rfc-structure-handle data-container-handle)
(cffi:defctype rfc-function-handle data-container-handle)
(cffi:defctype rfc-table-handle data-container-handle)
(cffi:defctype rfc-abap-object-handle data-container-handle)

(cffi:defcstruct rfc-throughput-handle-struct
  (handle (:pointer :void)))

(cffi:defctype rfc-throughput-handle (:pointer (:struct rfc-throughput-handle-struct)))

(cffi:defcstruct rfc-authentication-handle-struct
  (handle (:pointer :void)))

(cffi:defctype rfc-authentication-handle (:pointer (:struct rfc-authentication-handle-struct)))

(cffi:defcstruct rfc-connection-handle-struct
  (handle (:pointer :void)))

(cffi:defctype rfc-connection-handle (:pointer (:struct rfc-connection-handle-struct)))

(cffi:defcstruct rfc-server-handle-struct
  (handle (:pointer :void)))

(cffi:defctype rfc-server-handle (:pointer (:struct rfc-server-handle-struct)))

(cffi:defcenum rfc-protocol-type
  :rfc-unknown
  :rfc-client
  :rfc-started-server
  :rfc-registered-server
  :rfc-multi-count-registered-server
  :rfc-tcp-socket-client
  :rfc-tcp-socket-server
  :rfc-websocket-client
  :rfc-websocket-server
  :rfc-proxy-websocket-client
  )

(cffi:defcenum rfc-server-state
  :rfc-server-initial
  :rfc-server-starting
  :rfc-server-running
  :rfc-server-broken
  :rfc-server-stopping
  :rfc-server-stopped)

(cffi:defcstruct rfc-server-attributes
  (server-name (:pointer sap-uc))
  (type rfc-protocol-type)
  (registration-count :uint)
  (state rfc-server-state)
  (current-busy-count :uint)
  (peak-busy-count :uint))

(cffi:defcenum rfc-session-event
  :rfc-session-created
  :rfc-session-activated
  :rfc-session-passivated
  :rfc-session-destroyed)

(cffi:defcstruct rfc-session-change
  (session-id (:array sap-uc 31))
  (event rfc-session-event))

(cffi:defctype rfc-server-session-change-listener (:pointer :void))
(cffi:defctype rfc-server-error-listener (:pointer :void))

(cffi:defcstruct rfc-state-change
  (old-state rfc-server-state)
  (new-state rfc-server-state))

(cffi:defctype rfc-server-state-change-listener (:pointer :void))

#+time-t-defined
(cffi:defcstruct rfc-server-monitor-data
		 (client-info (:pointer (:struct rfc-attributes)))
		 (is-active :int)
		 (is-stateful :int)
		 (function-module-name (:array sap-uc 128))
		 (last-activity :time))

(cffi:defcstruct rfc-transaction-handle-struct
  (handle (:pointer :void)))

(cffi:defctype rfc-transaction-handle (:pointer (:struct rfc-transaction-handle-struct)))

(cffi:defcstruct rfc-unit-handle-struct
  (handle (:pointer :void)))

(cffi:defctype rfc-unit-handle (:pointer (:struct rfc-transaction-handle-struct)))

(cffi:defcstruct rfc-connection-parameter
  (name (:pointer sap-uc))
  (value (:pointer sap-uc)))

(cffi:defctype p-rfc-connection-parameter (:pointer (:struct rfc-connection-parameter)))

(cffi:defcstruct rfc-field-desc
  (name rfc-abap-name)
  (type rfctype)
  (n-length :uint)
  (n-offset :uint)
  (length :uint)
  (offset :uint)
  (decimals :uint)
  (type-desc-handle rfc-type-desc-handle)
  (extended-description (:pointer :void)))

(cffi:defctype p-rfc-field-desc (:pointer (:struct rfc-field-desc)))

(cffi:defcenum rfc-direction
  (rfc-import #x01)
  (rfc-export #x02)
  (rfc-changing #. (logior #x01 #x02))
  (rfc-tables #. (logior #x04 #x02 #x01)))

(cffi:defcstruct rfc-parameter-desc
  (name rfc-abap-name)
  (type rfctype)
  (direction rfc-direction)
  (n-length :uint)
  (length :uint)
  (decimals :uint)
  (type-desc-handle rfc-type-desc-handle)
  (default-value rfc-parameter-defvalue)
  (parameter-text rfc-parameter-text)
  (optional rfc-byte)
  (extended-description (:pointer :void)))

(cffi:defctype p-rfc-parameter-desc (:pointer (:struct rfc-parameter-desc)))

(cffi:defcstruct rfc-exception-desc
  (key (:array sap-uc 128))
  (message (:array sap-uc 512)))

(cffi:defctype p-rfc-exception-desc (:pointer (:struct rfc-exception-desc)))

(cffi:defcenum rfc-class-attribute-type
  :rfc-class-attribute-instance
  :rfc-class-attribute-class
  :rfc-class-attribute-constant)

(cffi:defctype rfc-class-attribute-defvalue (:array rfc-char 31))
(cffi:defctype rfc-class-name (:array rfc-char 31))
(cffi:defctype rfc-class-attribute-description (:array rfc-char 512))

(cffi:defcstruct rfc-class-attribute-desc
  (name rfc-abap-name)
  (type rfctype)
  (n-length :uint)
  (length :uint)
  (decimals :uint)
  (type-desc-handle rfc-type-desc-handle)
  (default-value rfc-class-attribute-defvalue)
  (declaring-class rfc-class-name)
  (description rfc-class-attribute-description)
  (is-read-only :uint)
  (attribute-type rfc-class-attribute-type)
  (extended-description (:pointer :void)))

(cffi:defctype p-rfc-class-attributes-desc (:pointer (:struct rfc-class-attribute-desc)))

(cffi:defctype rfc-server-function (:pointer :void))
(cffi:defctype rfc-on-check-transaction (:pointer :void))
(cffi:defctype rfc-on-commit-transaction (:pointer :void))
(cffi:defctype rfc-on-rollback-transaction (:pointer :void))
(cffi:defctype rfc-on-confirm-transaction (:pointer :void))

(cffi:defctype rfc-func-desc-callback (:pointer :void))
(cffi:defctype rfc-pm-callback (:pointer :void))

(cffi:defctype rfc-on-check-unit (:pointer :void))
(cffi:defctype rfc-on-commit-unit (:pointer :void))
(cffi:defctype rfc-on-rollback-unit (:pointer :void))
(cffi:defctype rfc-on-confirm-unit (:pointer :void))
(cffi:defctype rfc-on-get-unit-state (:pointer :void))
(cffi:defctype rfc-on-password-change (:pointer :void))
(cffi:defctype rfc-on-authorization-check (:pointer :void))
(cffi:defctype rfc-on-authentication-check (:pointer :void))

(cffi:defcfun ("RfcInit" %rfc-init) :rfc-rc ())
(cffi:defcfun ("RfcCleanup" %rfc-cleanup) :rfc-rc ())

(cffi:defcfun ("RfcGetVersion" %rfc-get-version) (:pointer sap-uc)
  (major-version (:pointer :uint))
  (minor-version (:pointer :uint))
  (patch-level (:pointer :uint)))

(cffi:defcfun ("RfcSetIniPath" %rfc-set-ini-path) rfc-rc
  (path-name (:pointer sap-uc))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcReloadIniFile" %rfc-reload-ini-file) rfc-rc
	      (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetTraceLevel" %rfc-set-trace-level) rfc-rc
  (connection rfc-connection-handle)
  (destination (:pointer sap-uc))
  (trace-level :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetTraceEncoding" %rfc-set-trace-envoding) rfc-rc
  (encoding (:pointer sap-uc))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetTraceDir" %rfc-set-trace-dir) rfc-rc
  (trace-dir (:pointer sap-uc))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetTraceType" %rfc-set-trace-type) rfc-rc
  (trace-type (:pointer sap-uc))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetCpicTraceLevel" %rfc-set-cpic-trace-level) rfc-rc
  (trace-level :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetCpicKeepalive" %rfc-set-cpic-keepalive) rfc-rc
  (timeout :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetSocketTraceLevel" %rfc-set-socket-trace-level) rfc-rc
  (trace-level :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcLoadCryptoLibrary" %rfc-load-crypto-library) rfc-rc
  (path-to-libary (:pointer sap-uc))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetWebsocketPingInterval" %rfc-set-websocket-ping-interval) rfc-rc
  (ping-interval :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetWebsocketPongTimeout" %rfc-set-websocket-pong-timeout) rfc-rc
  (pong-timeout :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetMaximumTraceFileSize" %rfc-set-maximum-trace-file-size) rfc-rc
  (size :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetMaximumStoredTraceFiles" %rfc-set-maximum-stored-trace-files) rfc-rc
  (number-of-files :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcUTF8ToSAPUC" %rfc-utf8-to-sap-uc) rfc-rc
  (utf8 (:pointer rfc-byte))
  (utf8-length :uint)
  (sapuc (:pointer sap-uc))
  (result-length (:pointer :uint))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcUTF8ToSAPUC_CCE" %rfc-utf8-to-sap-uc-cce) rfc-rc
  (utf8 (:pointer rfc-byte))
  (utf8-length :uint)
  (sapuc (:pointer sap-uc))
  (sapuc-size (:pointer :uint))
  (result-length (:pointer :uint))
  (on-cce :ushort)
  (substitute :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSAPUCToUTF8" %rfc-sap-uc-to-utf8) rfc-rc
  (sapuc (:pointer sap-uc))
  (sapuc-length :uint)
  (utf8 (:pointer rfc-byte))
  (utf8-size (:pointer :uint))
  (result-length (:pointer :uint))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSAPUCToUTF8_CCE" %rfc-sap-uc-to-utf8) rfc-rc
  (sapuc (:pointer sap-uc))
  (sapuc-length :uint)
  (utf8 (:pointer rfc-byte))
  (utf8-size (:pointer :uint))
  (result-length (:pointer :uint))
  (on-cce :ushort)
  (substitute :uint)
  (error-info (:pointer (:struct rfc-error-info))))


(cffi:defcfun ("RfcGetRcAsString" %rfc-get-rc-as-string) (:pointer sap-uc)
  (rc rfc-rc))

(cffi:defcfun ("RfcGetTypeAsString" %rfc-get-type-as-string) (:pointer sap-uc)
  (type rfctype))

(cffi:defcfun ("RfcGetDirectionAsString" %rfc-get-direction-as-string) (:pointer sap-uc)
  (direction rfc-direction))

(cffi:defcfun ("RfcGetServerStateAsString" %rfc-get-server-state-as-string) (:pointer sap-uc)
  (server-state rfc-server-state))

(cffi:defcfun ("RfcGetSessionEventAsString" %rfc-get-session-event-as-string) (:pointer sap-uc)
  (session-event rfc-session-event))

(cffi:defcfun ("RfcLanguageIsoToSap" %rfc-language-iso-to-sap) rfc-rc
  (laiso (:pointer sap-uc))
  (lang (:pointer sap-uc))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcLanguageSapToIso" %rfc-language-sap-to-iso) rfc-rc
  (lang (:pointer sap-uc))
  (laiso (:pointer sap-uc))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetSaplogonEntries" %rfc-get-saplogon-entries) rfc-rc
  (saplogin-id-list (:pointer (:pointer (:pointer sap-uc))))
  (num-saplogon-ids (:pointer :uint))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcFreeSaplogonEntries" %rfc-free-saplogon-entries) rfc-rc
  (saplogin-id-list (:pointer (:pointer (:pointer sap-uc))))
  (num-saplogon-ids (:pointer :uint))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetSaplogonEntry" %rfc-get-saplogon-entry) rfc-rc
	      (saplogin-id (:pointer sap-uc))
	      (entry-parameters (:pointer (:pointer (:struct rfc-connection-parameter))))
	      (num-parameters (:pointer :uint))
	      (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcFreeSaplogonEntry" %rfc-free-saplogon-entry) rfc-rc
	      (entry-parameters (:pointer (:pointer (:struct rfc-connection-parameter))))
	      (num-parameters (:pointer :uint))
	      (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcOpenConnection" %rfc-open-connection) rfc-connection-handle
	      (connection-params (:pointer (:struct rfc-connection-parameter)))
	      (param-count :uint)
	      (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcRegisterServer" %rfc-register-server) rfc-connection-handle
	      (connection-params (:pointer (:struct rfc-connection-parameter)))
	      (param-count :uint)
	      (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcStartServer" %rfc-start-server) rfc-connection-handle
	      (argc :int)
	      (argv (:pointer (:pointer sap-uc)))
	      (connection-params (:pointer (:struct rfc-connection-parameter)))
	      (param-count :uint)
	      (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcCloseConnection" %rfc-close-connection) rfc-rc
  (rfc-handle rfc-connection-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcIsConnectionHandleValid" %rfc-is-connection-handle-valid) rfc-rc
  (rfc-handle rfc-connection-handle)
  (is-valid (:pointer :int))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcCancel" %rfc-cancel) rfc-rc
  (rfc-handle rfc-connection-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcResetServerContext" %rfc-reset-server-context) rfc-rc
  (rfc-handle rfc-connection-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcPing" %rfc-ping) rfc-rc
  (rfc-handle rfc-connection-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetConnectionAttributes" %rfc-get-connection-attributes) rfc-rc
  (rfc-handle rfc-connection-handle)
  (attr (:pointer (:struct rfc-attributes)))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetServerContext" %rfc-get-server-contect) rfc-rc
  (rfc-handle rfc-connection-handle)
  (context (:pointer (:struct rfc-server-context)))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetSapRouter" %rfc-get-sap-router) rfc-rc
  (rfc-handle rfc-connection-handle)
  (sap-router (:pointer sap-uc))
  (length (:pointer :uint))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetPartnerExternalIP" %rfc-get-partner-external-ip) rfc-rc
  (rfc-handle rfc-connection-handle)
  (partner-external-ip (:pointer sap-uc))
  (length (:pointer :uint))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetLocalAddress" %rfc-get-local-address) rfc-rc
  (rfc-handle rfc-connection-handle)
  (local-address (:pointer sap-uc))
  (length (:pointer :uint))
  (local-port (:pointer :uint))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetPartnerSSOTicket" %rfc-get-partner-sso-ticket) rfc-rc
  (rfc-handle rfc-connection-handle)
  (sso-ticket (:pointer sap-uc))
  (length (:pointer :uint))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetPartnerSNCName" %rfc-get-partner-snc-name) rfc-rc
	      (rfc-handle rfc-connection-handle)
	      (snc-name (:pointer sap-uc))
	      (length (:pointer :uint))
	      (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetPartnerSNCKey" %rfc-get-partner-snc-key) rfc-rc
	      (rfc-handle rfc-connection-handle)
	      (snc-key (:pointer sap-uc))
	      (length (:pointer :uint))
	      (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSNCNameToKey" %rfc-snc-name-to-key) rfc-rc
	      (snc-lib (:pointer sap-uc))
	      (snc-name (:pointer sap-uc))
	      (snc-key (:pointer sap-uc))
	      (key-length (:pointer :uint))
	      (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSNCKeyToName" %rfc-snc-key-to-name) rfc-rc
  (snc-lib (:pointer sap-uc))
  (snc-key (:pointer sap-uc))
  (key-length :uint)
  (snc-name (:pointer sap-uc))
  (name-length :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcListenAndDispatch" %rfc-listen-and-dispatch) rfc-rc
	      (rfc-handle rfc-connection-handle)
	      (timeout :int)
	      (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcInvoke" %rfc-invoke) rfc-rc
	      (rfc-handle rfc-connection-handle)
	      (func-handle rfc-function-handle)
	      (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcCreateServer" %rfc-create-server) rfc-server-handle
	      (connection-params (:pointer (:struct rfc-connection-parameter)))
	      (param-count :uint)
	      (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcDestroyServer" %rfc-destroy-server) rfc-rc
  (server-handle rfc-server-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcLaunchServer" %rfc-launch-server) rfc-rc
  (server-handle rfc-server-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcShutdownServer" %rfc-shutdown-server) rfc-rc
  (server-handle rfc-server-handle)
  (timeout :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetServerAttributes" %rfc-get-server-attriutes) rfc-rc
  (server-handle rfc-server-handle)
  (server-atttributes (:pointer (:struct rfc-server-attributes)))
  (error-info (:pointer (:struct rfc-error-info))))

#+rfc-server-minotor-data-defined
(cffi:defcfun ("RfcGetServerConnectionMonitorData" %rfc-get-server-connection-monitor-data) rfc-rc
	      (server-handle rfc-server-handle)
	      (number-of-connections (:pointer :uint))
	      (connection-data (:pointer (:pointer rfc-server-monitor-data)))
	      (error-info (:pointer (:struct rfc-error-info))))

#+rfc-server-minotor-data-defined
(cffi:defcfun ("RfcDestroyServerConnectionMonitorData" %rfc-destroy-server-connection-monitor-data) rfc-rc
	      (server-handle rfc-server-handle)
	      (number-of-connections :uint)
	      (connection-data (:pointer rfc-server-monitor-data))
	      (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcAddServerErrorListener" %rfc-add-server-error-listener) rfc-rc
  (server-handle rfc-server-handle)
  (error-listener rfc-server-error-listener)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcAddServerStateChangeListener" %rfc-add-server-state-change-listener) rfc-rc
  (server-handle rfc-server-handle)
  (state-change-listener rfc-server-state-change-listener)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcAddServerSessionChangedListener" %rfc-add-server-session-changed-listener) rfc-rc
  (server-handle rfc-server-handle)
  (session-change-listener rfc-server-session-change-listener)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetServerStateful" %rfc-set-server-stateful) rfc-rc
  (connection-handle rfc-connection-handle)
  (is-stateful :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcInstallAuthenticationCheckHandler" %rfc-install-authentication-check-handler) rfc-rc
  (on-authentication-check rfc-on-authentication-check)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetAuthenticationType" %rfc-get-authentication-type) rfc-rc
  (authentication-handle rfc-authentication-handle)
  (type (:pointer rfc-authentication-type))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetAuthenticationUser" %rfc-get-authentication-user) rfc-rc
  (authentication-handle rfc-authentication-handle)
  (user (:pointer (:pointer sap-uc)))
  (lenght (:pointer :uint))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetAuthenticationPassword" %rfc-get-authentication-password) rfc-rc
  (authentication-handle rfc-authentication-handle)
  (password (:pointer (:pointer sap-uc)))
  (lenght (:pointer :uint))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetAuthenticationAssertionTicket" %rfc-get-authentication-assertion-ticket) rfc-rc
  (authentication-handle rfc-authentication-handle)
  (assertion-ticket (:pointer (:pointer sap-uc)))
  (lenght (:pointer :uint))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetAuthenticationCertificateData" %rfc-get-authentication-certificate-data) rfc-rc
  (authentication-handle rfc-authentication-handle)
  (certificate-data (:pointer (:pointer rfc-certificate-data)))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetTransactionID" %rfc-get-transaction-id) rfc-rc
  (connection-handle rfc-connection-handle)
  (tid rfc-tid)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcCreateTransaction" %rfc-create-transaction) rfc-transaction-handle
  (connection-handle rfc-connection-handle)
  (tid rfc-tid)
  (queue-name (:pointer sap-uc))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcInvokeInTransaction" %rfc-invoke-in-transaction) rfc-rc
  (t-handle rfc-transaction-handle)
  (func-handle rfc-function-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSubmitTransaction" %rfc-submit-transaction) rfc-rc
  (t-handle rfc-transaction-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcConfirmTransaction" %rfc-confirm-transaction) rfc-rc
  (t-handle rfc-transaction-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcConfirmTransactionID" %rfc-confirm-transaction-id) rfc-rc
  (connection-handle rfc-copnnection-handle)
  (tid rfc-tid)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcDestroyTransaction" %rfc-destroy-transaction) rfc-rc
  (t-handle rfc-transaction-handle)
  (error-info (:pointer (:struct rfc-error-info))))

;;; -- NOTE: bgUnit Functions NOT INCLUDED HERE !!! TODO: Implement bgUnit-related RFC bindings

(cffi:defcfun ("RfcInstallServerFunction" %rfc-install-server-function) rfc-rc
  (sys-id (:pointer sap-uc))
  (func-desc-handle rfc-function-desc-handle)
  (server-function rfc-server-function)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcInstallGenericServerFunction" %rfc-install-generic-server-function) rfc-rc
  (server-function rfc-server-function)
  (func-desc-provider rfc-func-desc-callback)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcInstallTransactionHandlers" %rfc-install-transaction-handlers) rfc-rc
  (sys-id (:pointer sap-uc))
  (on-check-function rfc-on-check-transaction)
  (on-commit-function rfc-on-commit-transaction)
  (on-rollback-function rfc-on-rollback-transaction)
  (on-confirm-function rfc-on-confirm-transaction)
  (error-info (:pointer (:struct rfc-error-info))))

;;; NOTE:  RfcInstallBgRfcHandlers NOT INCLUDED HERE

(cffi:defcfun ("RfcInstallPassportManager" %rfc-install-passport-manager) rfc-rc
  (on-client-call-start rfc-pm-callback)
  (on-client-call-end rfc-pm-callback)
  (on-server-call-start rfc-pm-callback)
  (on-server-call-end rfc-pm-callback)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcInstallPasswordChangeHandler" %rfc-install-password-change-handler) rfc-rc
  (on-password-change rfc-on-password-change)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcInstallAuthorizationCheckHandler" %rfc-install-authorization-check-handler) rfc-rc
  (on-authorization-check rfc-on-authorization-check)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcCreateFunction" %rfc-create-function) rfc-function-handle
  (func-desc-handle rfc-function-desc-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcDestroyFunction" %rfc-destroy-function) rfc-rc
  (func-handle rfc-function-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetParameterActive" %rfc-set-parameter-active) rfc-rc
  (func-handle rfc-function-handle)
  (param-name (:pointer sap-uc))
  (is-active :int)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcIsParameterActive" %rfc-is-parameter-active) rfc-rc
  (func-handle rfc-function-handle)
  (param-name (:pointer sap-uc))
  (is-active (:pointer :int))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcCreateStructure" %rfc-create-structure) rfc-structure-handle
  (type-desc-handle rfc-type-desc-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcCloneStructure" %rfc-clone-structure) rfc-structure-handle
  (src-structure-handle rfc-structure-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcDestroyStructure" %rfc-destroy-structure) rfc-rc
  (struct-handle rfc-structure-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcCreateTable" %rfc-create-table) rfc-table-handle
  (type-desc-handle rfc-type-desc-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcCloneTable" %rfc-clone-table) rfc-table-handle
  (src-table-handle rfc-table-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcDestroyTable" %rfc-destroy-table) rfc-rc
  (table-handle rfc-table-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetCurrentRow" %rfc-get-current-row) rfc-structure-handle
  (table-handle rfc-table-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcAppendNewRow" %rfc-append-new-row) rfc-structure-handle
  (table-handle rfc-table-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcReserveCapacity" %rfc-reserve-capacity) rfc-structure-handle
  (table-handle rfc-table-handle)
  (num-rows :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcAppendNewRows" %rfc-append-new-rows) rfc-structure-handle
  (table-handle rfc-table-handle)
  (num-rows :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcInsertNewRow" %rfc-insert-new-row) rfc-structure-handle
  (table-handle rfc-table-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcAppendRow" %rfc-append-row) rfc-rc
  (table-handle rfc-table-handle)
  (struct-handle rfc-structure-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcInsertRow" %rfc-insert-row) rfc-rc
  (table-handle rfc-table-handle)
  (struct-handle rfc-structure-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcDeleteCurrentRow" %rfc-delete-current-row) rfc-rc
  (table-handle rfc-table-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcDeleteAllRows" %rfc-delete-all-rows) rfc-rc
  (table-handle rfc-table-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcMoveToFirstRow" %rfc-move-to-first-row) rfc-rc
  (table-handle rfc-table-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcMoveToLastRow" %rfc-move-to-last-row) rfc-rc
  (table-handle rfc-table-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcMoveToNextRow" %rfc-move-to-next-row) rfc-rc
  (table-handle rfc-table-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcMoveToPreviousRow" %rfc-move-to-previous-row) rfc-rc
  (table-handle rfc-table-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcMoveTo" %rfc-move-to) rfc-rc
  (table-handle rfc-table-handle)
  (index :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetRowCount" %rfc-get-row-count) rfc-rc
  (table-handle rfc-table-handle)
  (row-count (:pointer :uint))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetRowType" %rfc-get-row-type) rfc-type-desc-handle
  (table-handle rfc-table-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcCreateAbapObject" %rfc-create-abap-object) rfc-abap-object-handle
  (class-desc-handle rfc-class-desc-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcDestroyAbapObject" %rfc-destroy-abap-object) rfc-rc
  (obj-handle rfc-abap-object-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetChars" %rfc-get-chars) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (char-buffer (:pointer rfc-char))
  (buffer-length :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetCharsByIndex" %rfc-get-chars-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (char-buffer (:pointer rfc-char))
  (buffer-length :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetNum" %rfc-get-num) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (char-buffer (:pointer rfc-num))
  (buffer-length :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetNumByIndex" %rfc-get-num-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (char-buffer (:pointer rfc-num))
  (buffer-length :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetDate" %rfc-get-date) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (empty-date rfc-date)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetDateByIndex" %rfc-get-date-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (empty-date rfc-date)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetTime" %rfc-get-time) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (empty-time rfc-time)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetTimeByIndex" %rfc-get-time-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (empty-time rfc-time)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetString" %rfc-get-string) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (string-buffer (:pointer sap-uc))
  (buffer-length :uint)
  (string-length (:pointer :uint))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetStringByIndex" %rfc-get-string-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (string-buffer (:pointer sap-uc))
  (buffer-length :uint)
  (string-length (:pointer :uint))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetBytes" %rfc-get-bytes) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (byte-buffer (:pointer sap-raw))
  (buffer-length :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetBytesbyIndex" %rfc-get-bytes-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (byte-buffer (:pointer sap-raw))
  (buffer-length :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetXString" %rfc-get-xstring) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (byte-buffer (:pointer sap-raw))
  (buffer-length :uint)
  (xstring-length (:pointer :uint))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetXStringByIndex" %rfc-get-xstring-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (byte-buffer (:pointer sap-raw))
  (buffer-length :uint)
  (xstring-length (:pointer :uint))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetInt" %rfc-get-int) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (value (:pointer rfc-int))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetIntByIndex" %rfc-get-int-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (value (:pointer rfc-int))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetInt1" %rfc-get-int1) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (value (:pointer rfc-int1))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetInt1ByIndex" %rfc-get-int1-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (value (:pointer rfc-int1))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetInt2" %rfc-get-int2) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (value (:pointer rfc-int2))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetInt2ByIndex" %rfc-get-int2-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (value (:pointer rfc-int2))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetInt8" %rfc-get-int8) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (value (:pointer rfc-int8))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetInt8ByIndex" %rfc-get-int8-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (value (:pointer rfc-int8))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetFloat" %rfc-get-float) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (value (:pointer rfc-float))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetFloatByIndex" %rfc-get-float-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (value (:pointer rfc-float))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetDecF16" %rfc-get-decf16) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (value (:pointer rfc-decf16))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetDecF16ByIndex" %rfc-get-decf16-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (value (:pointer rfc-decf16))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetDecF34" %rfc-get-decf34) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (value (:pointer rfc-decf34))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetDecF34ByIndex" %rfc-get-decf34-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (value (:pointer rfc-decf34))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetStructure" %rfc-get-structure) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (struct-handle (:pointer rfc-structure-handle))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetStructureByIndex" %rfc-get-structure-by-index) rfc-rc
  (data-handle data-container-handle)
  (idnex :uint)
  (struct-handle (:pointer rfc-structure-handle))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetStructureIntoCharBuffer" %rfc-get-structure-into-char-buffer) rfc-rc
  (data-handle data-container-handle)
  (char-buffer (:pointer sap-uc))
  (buffer-length :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetTable" %rfc-get-table) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (table-handle (:pointer rfc-table-handle))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetTableByIndex" %rfc-get-table-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (table-handle (:pointer rfc-table-handle))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetAbapObject" %rfc-get-abap-object) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (obj-handle (:pointer rfc-abap-object-handle))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetAbapObjectByIndex" %rfc-get-abap-object-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (obj-handle (:pointer rfc-abap-object-handle))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetStringLength" %rfc-get-string-length) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (string-length (:pointer :uint))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetStringLengthByIndex" %rfc-get-string-length-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (string-length (:pointer :uint))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetChars" %rfc-set-chars) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (char-value (:pointer rfc-char))
  (value-length :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetCharsByIndex" %rfc-set-chars-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (char-value (:pointer rfc-char))
  (value-length :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetNum" %rfc-set-num) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (char-value (:pointer rfc-num))
  (value-length :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetNumByIndex" %rfc-set-num-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (char-value (:pointer rfc-num))
  (value-length :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetString" %rfc-set-string) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (string-value (:pointer sap-uc))
  (value-length :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetStringByIndex" %rfc-set-string-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (string-value (:pointer sap-uc))
  (value-length :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetDate" %rfc-set-date) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (date rfc-date)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetDateByIndex" %rfc-set-date-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (date rfc-date)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetTime" %rfc-set-time) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (time rfc-time)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetTimeByIndex" %rfc-set-time-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (time rfc-time)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetBytes" %rfc-set-bytes) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (byte-value (:pointer sap-raw))
  (value-length :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetBytesByIndex" %rfc-set-bytes-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (byte-value (:pointer sap-raw))
  (value-length :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetXString" %rfc-set-xstring) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (byte-value (:pointer sap-raw))
  (value-length :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetXStringByIndex" %rfc-set-xstring-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (byte-value (:pointer sap-raw))
  (value-length :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetInt" %rfc-set-int) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (value rfc-int)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetIntByIndex" %rfc-set-int-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (value rfc-int)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetInt1" %rfc-set-int1) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (value rfc-int1)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetInt1ByIndex" %rfc-set-int1-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (value rfc-int1)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetInt2" %rfc-set-int2) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (value rfc-int2)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetInt2ByIndex" %rfc-set-int2-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (value rfc-int2)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetInt8" %rfc-set-int8) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (value rfc-int8)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetInt8ByIndex" %rfc-set-int8-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (value rfc-int8)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetFloat" %rfc-set-float) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (value rfc-float)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetFloatByIndex" %rfc-set-float-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (value rfc-float)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetDecF16" %rfc-set-decf16) rfc-rc
	      (data-handle data-container-handle)
	      (name (:pointer sap-uc))
	      (value rfc-decf16)
	      (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetDecF16ByIndex" %rfc-set-decf16-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (value rfc-decf16)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetDecF34" %rfc-set-decf34) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (value rfc-decf34)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetDecF34ByIndex" %rfc-set-decf34-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (value rfc-decf34)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetStructure" %rfc-set-structure) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (value rfc-structure-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetStructureByIndex" %rfc-set-structure-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (value rfc-structure-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetStructureFromCharBuffer" %rfc-set-structure-from-char-buffer) rfc-rc
  (data-handle data-container-handle)
  (char-buffer (:pointer sap-uc))
  (buffer-length :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetTable" %rfc-set-table) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (value rfc-table-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetTableByIndex" %rfc-set-table-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (value rfc-table-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetAbapObject" %rfc-set-abap-object) rfc-rc
  (data-handle data-container-handle)
  (name (:pointer sap-uc))
  (value rfc-abap-object-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetAbapObjectByIndex" %rfc-set-abap-object-by-index) rfc-rc
  (data-handle data-container-handle)
  (index :uint)
  (value rfc-abap-object-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetAbapClassException" %rfc-get-abap-class-exception) rfc-abap-object-handle
  (func-handle rfc-function-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetAbapClassException" %rfc-set-abap-class-exception) rfc-rc
  (func-handle rfc-function-handle)
  (excp-handle rfc-abap-object-handle)
  (exception-text (:pointer sap-uc))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcDescribeFunction" %rfc-describe-function) rfc-function-desc-handle
  (func-handle rfc-function-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcDescribeType" %rfc-describe-type) rfc-type-desc-handle
  (data-handle data-container-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetFunctionDesc" %rfc-get-function-desc) rfc-function-desc-handle
  (rfc-handle rfc-connection-handle)
  (func-name (:pointer sap-uc))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetCachedFunctionDesc" %rfc-get-cached-function-desc) rfc-function-desc-handle
  (repository-id (:pointer sap-uc))
  (func-name (:pointer sap-uc))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcAddFunctionDesc" %rfc-add-function-desc) rfc-rc
  (repository-id (:pointer sap-uc))
  (func-desc rfc-function-desc-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcRemoveFunctionDesc" %rfc-remove-function-desc) rfc-rc
  (repository-id (:pointer sap-uc))
  (func-name (:pointer sap-uc))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetTypeDesc" %rfc-get-type-desc) rfc-type-desc-handle
  (rfc-handle rfc-connection-handle)
  (type-name (:pointer sap-uc))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetCachedTypeDesc" %rfc-get-cached-type-desc) rfc-type-desc-handle
  (repository-id (:pointer sap-uc))
  (type-name (:pointer sap-uc))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcAddTypeDesc" %rfc-add-type-desc) rfc-rc
  (repository-id (:pointer sap-uc))
  (type-handle rfc-type-desc-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcRemoveTypeDesc" %rfc-remove-type-desc) rfc-rc
  (repository-id (:pointer sap-uc))
  (type-name (:pointer sap-uc))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetClassDesc" %rfc-get-class-desc) rfc-class-desc-handle
  (rfc-handle rfc-connection-handle)
  (class-name (:pointer sap-uc))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetCachedClassDesc" %rfc-get-cached-class-desc) rfc-class-desc-handle
  (repository-id (:pointer sap-uc))
  (class-name (:pointer sap-uc))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcDescribeAbapObject" %rfc-describe-abap-object) rfc-class-desc-handle
  (object-handle rfc-abap-object-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcAddClassDesc" %rfc-add-class-desc) rfc-rc
  (repository-id (:pointer sap-uc))
  (class-desc rfc-class-desc-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcRemoveClassDesc" %rfc-remove-class-desc) rfc-rc
  (repository-id (:pointer sap-uc))
  (class-name (:pointer sap-uc))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcClearRepository" %rfc-clear-repository) rfc-rc
  (repository-id (:pointer sap-uc))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSaveRepository" %rfc-save-repository) rfc-rc
  (repository-id (:pointer sap-uc))
  (target-stream (:pointer :void)) ;; FILE *
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcLoadRepository" %rfc-load-repository) rfc-rc
  (repository-id (:pointer sap-uc))
  (target-stream (:pointer :void)) ;; FILE *
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcCreateTypeDesc" %rfc-create-type-desc) rfc-type-desc-handle
  (name (:pointer sap-uc))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcAddTypeField" %rfc-add-type-field) rfc-rc
  (type-handle rfc-type-desc-handle)
  (field-desc (:pointer (:struct rfc-field-desc)))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetTypeLength" %rfc-set-type-length) rfc-rc
  (type-handle rfc-type-desc-handle)
  (n-byte-length :uint)
  (byte-length :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetTypeName" %rfc-get-type-name) rfc-rc
  (type-handle rfc-type-desc-handle)
  (buffer-for-name rfc-abap-name)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetFieldCount" %rfc-get-field-count) rfc-rc
  (type-handle rfc-type-desc-handle)
  (count (:pointer :uint))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetFieldDescByIndex" %rfc-get-field-desc-by-index) rfc-rc
  (type-handle rfc-type-desc-handle)
  (index :uint)
  (field-desc (:pointer (:struct rfc-field-desc)))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetFieldDescByName" %rfc-get-field-desc-by-name) rfc-rc
  (type-handle rfc-type-desc-handle)
  (name (:pointer sap-uc))
  (field-desc (:pointer (:struct rfc-field-desc)))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetTypeLength" %rfc-get-type-length) rfc-rc
  (type-handle rfc-type-desc-handle)
  (n-byte-length (:pointer :uint))
  (byte-length (:pointer :uint))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcDestroyTypeDesc" %rfc-destroy-type-desc) rfc-rc
  (type-handle rfc-type-desc-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcCreateFunctionDesc" %rfc-create-function-desc) rfc-function-desc-handle
  (name (:pointer sap-uc))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetFunctionName" %rfc-get-function-name) rfc-rc
  (func-desc rfc-function-desc-handle)
  (buffer-for-name rfc-abap-name)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcAddParameter" %rfc-add-parameter) rfc-rc
  (func-desc rfc-function-desc-handle)
  (param-descr (:pointer (:struct rfc-parameter-desc)))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetParameterCount" %rfc-get-parameter-count) rfc-rc
  (func-desc rfc-function-desc-handle)
  (count (:pointer :uint))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetParameterDescByIndex" %rfc-get-parameter-desc-by-index) rfc-rc
  (func-desc rfc-function-desc-handle)
  (index :uint)
  (param-desc (:pointer (:struct rfc-parameter-desc)))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetParameterDescByName" %rfc-get-parameter-desc-by-name) rfc-rc
  (func-desc rfc-function-desc-handle)
  (name (:pointer sap-uc))
  (param-desc (:pointer (:struct rfc-parameter-desc)))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcAddException" %rfc-add-exception) rfc-rc
  (func-desc rfc-function-desc-handle)
  (exc-desc (:pointer (:struct rfc-exception-desc)))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetExceptionCount" %rfc-get-exception-count) rfc-rc
  (func-desc rfc-function-desc-handle)
  (count (:pointer :uint))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetExceptionDescByIndex" %rfc-get-excpetion-desc-by-index) rfc-rc
  (func-desc rfc-function-desc-handle)
  (index :uint)
  (exc-desc (:pointer (:struct rfc-exception-desc)))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetExceptionDescByName" %rfc-get-excpetion-desc-by-name) rfc-rc
  (func-desc rfc-function-desc-handle)
  (name (:pointer sap-uc))
  (exc-desc (:pointer (:struct rfc-exception-desc)))
  (error-info (:pointer (:struct rfc-error-info))))

;;; Note: RfcEnableBASXML NOT INCLUDED HERE !
;;; Note: RfcIsBASXMLSupported NOT INCLUDED HERE !

(cffi:defcfun ("RfcDestroyFunctionDesc" %rfc-destroy-function-desc) rfc-rc
  (func-desc rfc-function-desc-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcEnableAbapClassException" %rfc-enable-abap-class-exception) rfc-rc
  (func-handle rfc-function-handle)
  (rfc-handle-repository rfc-connection-handle)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcIsAbapClassExceptionEnabled" %rfc-is-abap-class-exception-enabled) rfc-rc
  (func-handle rfc-function-handle)
  (is-enabled (:pointer :int))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcCreateClassDesc" %rfc-create-class-desc) rfc-class-desc-handle
  (name (:pointer sap-uc))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetClassName" %rfc-get-class-name) rfc-rc
  (class-desc rfc-class-desc-handle)
  (buffer-for-name rfc-abap-name)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcAddClassAttribute" %rfc-add-class-attribute) rfc-rc
  (class-desc rfc-class-desc-handle)
  (attr-desc (:pointer (:struct rfc-class-attribute-desc)))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetClassAttributesCount" rfc-get-class-attributes-count) rfc-rc
	      (class-desc rfc-class-desc-handle)
	      (count (:pointer :uint))
	      (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetClassAttributeDescByIndex" rfc-get-class-attribute-desc-by-index) rfc-rc
  (class-desc rfc-class-desc-handle)
  (index :uint)
  (attr-desc (:pointer (:struct rfc-class-attribute-desc)))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetClassAttributeDescByName" rfc-get-class-attribute-desc-by-name) rfc-rc
  (class-desc rfc-class-desc-handle)
  (name (:pointer sap-uc))
  (attr-desc (:pointer (:struct rfc-class-attribute-desc)))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetParentClassByIndex" rfc-get-parent-class-by-index) rfc-rc
	      (class-desc rfc-class-desc-handle)
	      (name rfc-class-name)
	      (index :uint)
	      (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetParentClassesCount" rfc-get-parent-classes-count) rfc-rc
	      (class-desc rfc-class-desc-handle)
	      (parent-classes-count (:pointer :uint))
	      (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcAddParentClass" rfc-add-parent-class) rfc-rc
	      (class-desc rfc-class-desc-handle)
	      (name rfc-class-name)
	      (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetImplementedInterfaceByIndex" rfc-get-implemented-interface-by-index) rfc-rc
	      (class-desc rfc-class-desc-handle)
	      (index :uint)
	      (name rfc-class-name)
	      (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetImplementedInterfacesCount" rfc-get-implemented-interfaces-count) rfc-rc
	      (class-desc rfc-class-desc-handle)
	      (implemented-interfaces-count (:pointer :uint))
	      (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcAddImplementedInterface" rfc-add-implemented-interface) rfc-rc
	      (class-desc rfc-class-desc-handle)
	      (name rfc-class-name)
	      (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcDestroyClassDesc" rfc-destroy-class-desc) rfc-rc
	      (class-desc rfc-class-desc-handle)
	      (error-info (:pointer (:struct rfc-error-info))))

(cffi:defctype rfc-metdata-query-result-handle (:pointer :void))

(cffi:defcstruct rfc-metadata-query-result-entry
  (name rfc-abap-name)
  (error-message (:array sap-uc 512)))

(cffi:defcenum rfc-metadata-obj-type
  :rfc-metadata-function
  :rfc-metadata-type
  :rfc-metadata-class)

;;; TODO: Implement RfcCreateMetadataQueryResult
;;; TODO: Implement RfcDestroyMetadataQueryResult
;;; TODO: Implement RfcDescribeMetadataQueryResult!
;;; TODO: Implement RfcGetMetadataQueryFailedEntry
;;; TODO: Implement RfcGetMetadataQuerySucceededEntry
;;; TODO: Implement RfcMetadataBatchQuery
;;; TODO: Implement RfcCreateThroughput
;;; TODO: Implement RfcDestroyThroughput
;;; TODO: Implement RfcSetThroughputOnConnection
;;; TODO: Implement RfcGetThroughputFromConnection
;;; TODO: Implement RfcRemoveThroughputFromConnection
;;; TODO: Implement RfcSetThroughputOnServer
;;; TODO: Implement RfcGetThroughputFromServer
;;; TODO: Implement RfcRemoveThroughputFromServer
;;; TODO: Implement RfcResetThroughput
;;; TODO: Implement RfcGetNumberOfCalls
;;; TODO: Implement RfcGetTotalTime
;;; TODO: Implement RfcGetSerializationTime
;;; TODO: Implement RfcGetDeserializationTime
;;; TODO: Implement RfcGetApplicationTime
;;; TODO: Implement RfcGetServerTime
;;; TODO: Implement RfcGetNetworkReadingTime
;;; TODO: Implement RfcGetNetworkWritingTime
;;; TODO: Implement RfcGetSentBytes
;;; TODO: Implement RfcGetReceivedBytes

(cffi:defcfun ("RfcSetMessageServerResponseTimeout" %rfc-set-message-server-response-timeout) rfc-rc
  (timeout :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetMaximumCpicConversations" %rfc-set-maximum-cpic-conversations) rfc-rc
  (max-cpic-conversations :uint)
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcGetMaximumCpicConversations" %rfc-get-maximum-cpic-conversations) rfc-rc
  (max-cpic-conversations (:pointer :uint))
  (error-info (:pointer (:struct rfc-error-info))))

(cffi:defcfun ("RfcSetGlobalLogonTimeout" %rfc-set-global-logon-timeout) rfc-rc
  (timeout :uint)
  (error-info (:pointer (:struct rfc-error-info))))


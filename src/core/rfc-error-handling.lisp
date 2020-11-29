;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-

#+sigyn-production
(declaim (optimize (speed 3) (compilation-speed 0) (safety 1) (debug 1)))

(cl:in-package "NET.GOENNINGER.SIGYN.CORE")

;;; ---------------------------------------------------------------------------

;;; LOGGING

;; (defun format-rfc-condition-for-slack (rfc-condition)
;;   (check-type rfc-condition rfc-condition)
;;   (with-slots (tb.core:function-return-code tb.core:message-nr tb.core:reason-code tb.core:reason-text) rfc-condition
;;     (format nil "*SAP RFC: ~A*~%~%~30A ~32A ~30A~%~23A ~32A ~30A~%~%*Reason Text*:~%~A"
;; 	    rfc-condition
;; 	    "*Msg Nr*:"
;; 	    "*Reason Code*:"
;; 	    "*RFC Return Code*:"
;; 	    tb.core:message-nr
;; 	    tb.core:reason-code
;; 	    (princ-to-string tb.core:function-return-code)
;; 	    tb.core:reason-text)))

;; (defun dispatch-rfc-condition (rfc-condition)
;;   (let ((msg (format-rfc-condition-for-slack rfc-condition))
;; 	(level-nr (tb.core:level-nr rfc-condition)))
;;     (cond
;;       ((= level-nr tb.core:+TB-MSG-LEVEL-UNDEFINED+)
;;        nil) ;; NOP
;;       ((= level-nr tb.core:+TB-MSG-LEVEL-DEBUG+)
;;        (log:debug "~A" msg))
;;       ((= level-nr tb.core:+TB-MSG-LEVEL-INFORMATIONAL+)
;;        (log:info "~A" msg))
;;       ((or (= level-nr tb.core:+TB-MSG-LEVEL-NOTICE+)
;; 	   (= level-nr tb.core:+TB-MSG-LEVEL-WARNING+))
;;        (log:warn "~A" msg))
;;       ((or (= level-nr tb.core:+TB-MSG-LEVEL-ERROR+)
;; 	   (= level-nr tb.core:+TB-MSG-LEVEL-CRITICAL+))
;;        (log:error "~A" msg))
;;       ((or (= level-nr tb.core:+TB-MSG-LEVEL-ALERT+)
;; 	   (= level-nr tb.core:+TB-MSG-LEVEL-EMERGENCY+))
;;        (log:fatal "~A" msg))
;;       (t (log:fatal "Cannot dispatch SERVB-RETURN-INFO: Cannot determine log function from level ~S. Message was:~%~%~A" level-nr msg))))
;;   (values))


;; (defmethod tb.msgs:dispatch ((rfc-condition rfc-condition) &key &allow-other-keys)
;;   (dispatch-rfc-condition rfc-condition))

;; (defmethod tb.msgs:dispatch ((rfc-condition rfc-invalid-parameter) &key &allow-other-keys)
;;   (dispatch-rfc-condition rfc-condition))

;; (defmethod tb.msgs:dispatch ((rfc-condition rfc-communication-failure) &key &allow-other-keys)
;;   (dispatch-rfc-condition rfc-condition))

;; (defmethod tb.msgs:dispatch ((rfc-condition rfc-misc-failure) &key &allow-other-keys)
;;   (dispatch-rfc-condition rfc-condition))

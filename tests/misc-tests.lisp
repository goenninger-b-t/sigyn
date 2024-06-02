(cl:in-package #:net.goenninger.sigyn)

 ;;; --- CONNECTION ---

(defun make-stu-kw0-connection ()

  (let ((connection (make-instance 'connection :user-designator "luederh")))

    ;; (set-connection-parameter connection "USER"      "THINGBONE")
    ;; (set-connection-parameter connection "PASSWD"    "t3hdi5ncg5b8o4nfe3a24e9e2136fd6a6daf731e")
    (set-connection-parameter connection "USER"      "luederh")
    (set-connection-parameter connection "PASSWD"    "kl23060")
    (set-connection-parameter connection "SAPROUTER" "/H/10.79.128.1/S/5890")
    (set-connection-parameter connection "ASHOST"    "wudkw0ci")
    (set-connection-parameter connection "SYSNR"     "00")
    (set-connection-parameter connection "CLIENT"    "500")
    (set-connection-parameter connection "LANG"      "EN")
    (set-connection-parameter connection "TRACE"     "3")

    (with-connection (connection connection)

      (format *debug-io* "*** Connected to SAP KW0? ~S ~%" (connected-p connection))
      (format *debug-io* "~%*** Connecting to SAP KW0 ... ~%")
      (format *debug-io* "*** - Using connection parameters ~S~%" (connection-parameters-as-list connection))

      (connect connection)
      (format *debug-io* "~%*** Connected to SAP KW2? ~S ~%" (connected-p connection))
      ;; (disconnect connection)
      ;; (format *debug-io* "~%*** Connected to SAP KW2? ~S ~%" (connectedp connection))
      connection)))


;; --- GCG ---

(define-structure ZTB_S_OBJNR_CRE_A0100 (sapnwrfc-object)

  ((OBJKND :accessor OBJKND :initarg :OBJKND :initform ""
 	   :rfc-type :rfc-char :rfc-length 4 :rfc-param-name "OBJKND")

   (SSID   :accessor SSID :initarg :SSID :initform ""
 	   :rfc-type :rfc-char :rfc-length 36 :rfc-param-name "SSID")

   (CID    :accessor CID :initarg :CID :initform ""
 	   :rfc-type :rfc-char :rfc-length 36 :rfc-param-name "CID")

   (NRIDS  :accessor NRIDS :initarg :NRIDS :initform 0
 	   :rfc-type :rfc-numc :rfc-length 8 :rfc-param-name "NRIDS"))

  (:rfc-object-name "ZTB_S_OBJNR_CRE_A0100"))


(define-table Z_TB_T_OBJNR_CRE_RES_A0100 (sapnwrfc-object)

  ((LINE_NUMBER :accessor LINE_NUMBER :initarg :LINE_NUMBER :initform nil
 		:rfc-type :rfc-numc :rfc-length 6 :rfc-param-name "LINE_NUMBER")

   (OBJKND      :accessor OBJKND :initarg :OBJKND :initform nil
 	  	:rfc-type :rfc-char :rfc-length 4 :rfc-param-name "OBJKND")

   (OBJIDNR     :accessor OBJIDNR :initarg :OBJKND :initform nil
 	  	:rfc-type :rfc-numc :rfc-length 40 :rfc-param-name "OBJIDNR")

   (OBJIDNRLEN  :accessor OBJIDNRLEN :initarg :OBJIDNRLEN :initform nil
 	  	:rfc-type :rfc-int4 :rfc-param-name "OBJIDNRLEN"))

  (:rfc-object-name "Z_TB_T_OBJNR_CRE_RES_A0100"))


(define-client-function Z_TB_RR_OBJNR_CRE_A0100 (sapnwrfc-object)

  ((IS_OBJNR_CRE_REQ :accessor IS_OBJNR_CRE_REQ
		     :initarg :IS_OBJNR_CRE_REQ
		     :initform nil
 		     :rfc-type ZTB_S_OBJNR_CRE_A0100
		     :rfc-param-name "IS_OBJNR_CRE_REQ"
		     :rfc-kind :importing)

   (ES_RETURN_INFO   :accessor ES_RETURN_INFO
		     :initform nil
   		     :rfc-type ZTB_S_RETURN_INFO
		     :rfc-param-name "ES_RETURN_INFO"
		     :rfc-kind :exporting)

   (ET_OBJNR_CRE_RES :accessor ET_OBJNR_CRE_RES
		     :initform nil
     		     :rfc-type Z_TB_T_OBJNR_CRE_RES_A0100
		     :rfc-param-name "ET_OBJNR_CRE_RES"
		     :rfc-kind :exporting)
   )

  (:rfc-object-name "Z_TB_RR_OBJNR_CRE_A0100"))

(defun test-Z_TB_RR_OBJNR_CRE_A0100 (&key (conn (make-stu-kw0-connection))
 				       (objknd "01")
 				       (ssid (uuid:make-uuid-from-string "2563C291-A857-463D-BFE3-0B4DF600182E"))
 				       (cid (uuid:make-v4-uuid))
 				       (nrids 1))

  (let ((req (make-instance 'ZTB_S_OBJNR_CRE_A0100)))

    (setf (OBJKND req) objknd)
    (setf (SSID   req) ssid)
    (setf (CID    req) cid)
    (setf (NRIDS  req) nrids)

    (let ((fn (make-instance 'Z_TB_RR_OBJNR_CRE_A0100 :IS_OBJNR_CRE_REQ req)))
      (funcall fn conn)
      fn)))


;; --- OBJECT EVENTS ---


(define-client-function Z_TB_RR_OBJ_GEN (sapnwrfc-object)

  ((IS_OBJ_GEN_REQ :accessor IS_OBJ_GEN_REQ :initarg :IS_OBJ_GEN_REQ :initform nil
 		   :rfc-type ZTB_S_OBJ_GEN_REQ :rfc-param-name "IS_OBJ_GEN_REQ" :rfc-kind :importing)

   (ES_RETURN_INFO :accessor ES_RETURN_INFO :initform nil
 		   :rfc-type ZTB_S_RETURN_INFO :rfc-param-name "ES_TB_RETURN_INFO" :rfc-kind :exporting)

   ;; - DOESN't WORK YET
   (ES_OBJ_GEN_RES :accessor ES_OBJ_GEN_RES :initform nil
     		   :rfc-type ZTB_S_OBJ_GEN_RES :rfc-param-name "ES_OBJ_GEN_RES" :rfc-kind :exporting)
   )

  (:rfc-object-name "Z_TB_RR_OBJ_GEN_A0100"))

(define-structure ZTB_S_OBJ_DATA (sapnwrfc-object)

  ((ARTICLES        :accessor ARTICLES :initarg :ARTICLES :initform nil
 		    :rfc-type Z_TB_T_ARTICLES :rfc-param-name "ARTICLES")

   (DOCUMENTS       :accessor DOCUMENTS :initarg :DOCUMENTS :initform nil
 		    :rfc-type Z_TB_T_DOCUMENTS :rfc-param-name "DOCUMENTS")

   (EQUIPMENTS      :accessor EQUIPMENTS :initarg :EQUIPMENTS :initform nil
 		    :rfc-type Z_TB_T_EQUIPMENTS :rfc-param-name "EQUIPMENTS")

   (BOMS            :accessor BOMS :initarg :BOMS :initform nil
 		    :rfc-type Z_TB_T_BOMS :rfc-param-name "BOMS")

   (CHANGE_REQUESTS :accessor CHANGE_REQUERSTS :initarg :CHANGE_REQUESTS :initform nil
 		    :rfc-type Z_TB_T_CHANGE_REQUESTS :rfc-param-name "CHANGE_REQUESTS")

   (CHANGE_ORDERS   :accessor CHANGE_ORDERS :initarg :CHANGE_ORDERS :initform nil
 		    :rfc-type Z_TB_T_CHANGE_ORDERS :rfc-param-name "CHANGE_ORDERS")

   (CHANGE_NOTES    :accessor CHANGE_NOTES :initarg :CHANGE_NOTES :initform nil
 		    :rfc-type Z_TB_T_CHANGE_NOTES :rfc-param-name "CHANGE_NOTES")

   (PROJECTS        :accessor PROJECTS :initarg :PROJECTS :initform nil
 		    :rfc-type Z_TB_T_PROJECTS :rfc-param-name "PROJECTS")

   (ROUTING_LISTS   :accessor ROUTING_LISTS :initarg :ROUTING_LISTS :initform nil
 		    :rfc-type Z_TB_T_ROUTING_LISTS :rfc-param-name "ROUTING_LISTS")

   (BASELINES       :accessor BASELINES :initarg :BASELINES :initform nil
 		    :rfc-type Z_TB_T_BASELINES :rfc-param-name "BASELINES"))

  (:rfc-object-name "ZTB_S_OBJ_DATA"))


(define-structure ZTB_S_RETURN_INFO (sapnwrfc-object)

  ((TB_OID              :accessor TB_OID :initarg :TB_OID :initform (uuid:make-v4-uuid)
 			:rfc-type :rfc-char :rfc-length 36 :rfc-param-name "TB_OID")

   (TB_TIMESTAMP        :accessor TB_TIMESTAMP :initarg :TB_TIMESTAMP :initform nil
 			:rfc-type :rfc-char :rfc-length 22 :rfc-param-name : "TB_TIMESTAMP")

   (TB_RFC_IF_FM_NAME   :accessor TB_RFC_IF_FM_NAME :initarg :TB_RFC_IF_FM_NAME :initform nil
 			:rfc-type :rfc-char :rfc-length 40 :rfc-param-name "TB_RFC_IF_FM_NAME")

   (TB_SOURCE_SYSTEM_ID :accessor TB_SOURCE_SYSTEM_ID :initarg :TB_SOURCE_SYSTEM_ID :initform nil
 			:rfc-type :rfc-char :rfc-length 36 :rfc-param-name "TB_SOURCE_SYSTEM_ID")

   (TB_IN_REPLY_TO      :accessor TB_IN_REPLY_TO :initarg :TB_IN_REPLY_TO :initform nil
 			:rfc-type :rfc-char :rfc-length 36 :rfc-param-name "TB_IN_REPLY_TO")

   (TB_RETURN_CODE      :accessor TB_RETURN_CODE :initarg :TB_RETURN_CODE :initform nil
 			:rfc-type :rfc-numc :rfc-length 8 :rfc-param-name "TB_RETURN_CODE")

   (TB_LEVEL            :accessor TB_LEVEL :initarg :TB_LEVEL :initform nil
 			:rfc-type :rfc-int4 :rfc-length 1 :rfc-param-name "TB_LEVEL")

   (TB_MSG_NR           :accessor TB_MSG_NR :initarg :TB_MSG_NR :initform nil
 			:rfc-type :rfc-char :rfc-length 8 :rfc-param-name "TB_MSG_NR")

   (TB_REASON_CODE      :accessor TB_REASON_CODE :initarg :TB_REASON_CODE :initform nil
 			:rfc-type :rfc-char :rfc-length 8 :rfc-param-name "TB_REASON_CODE")

   (TB_REASON_TEXT      :accessor TB_REASON_TEXT :initarg :TB_REASON_TEXT :initform nil
 			:rfc-type :rfc-char :rfc-length 511 :rfc-param-name "TB_REASON_TEXT")

   ;; (TB_FM_RETURN_INFO   :accessor TB_ :initarg :TB_ :initform nil
   ;;     :rfc-type Z_TB_T_FM_RETURN_INFO :rfc-param-name "TB_REASON_TEXT" )
   )

  (:rfc-object-name "ZTB_S_RETURN_INFO"))



(define-table Z_TB_T_ARTICLES (sapnwrfc-object)

  ((LINE_NUMBER         :accessor LINE_NUMBER :initarg :LINE_NUMBER :initform nil
 			:rfc-type :rfc-numc :rfc-length 6 :rfc-param-name "LINE_NUMBER")

   (DETAILS             :accessor DETAILS :initarg :DETAILS :initform nil
 	 		:rfc-type Z_TB_S_ARTICLE_DETAILS :rfc-param-name "DETAILS")

   (MATNR               :accessor MATNR :initarg :MATNR :initform nil
 			:rfc-type :rfc-numc :rfc-length 18 :rfc-param-name "MATNR"))

  (:rfc-object-name "Z_TB_T_ARTICLES"))

(defun test-Z_TB_RR_OBJ_GEN ()
  (let* ((conn   (make-stu-kw0-connection))
 	 (struct (make-instance 'ZTB_S_OBJ_DATA))
 	 (fn     (make-instance 'Z_TB_RR_OBJ_GEN :IS_OBJ_GEN_REQ struct)))
    (funcall fn conn)))


 ;;; ---------------------------------------------------------

(define-structure ZTB_S_TEST_STRUCT02 (sapnwrfc-object)

  ((E1                  :accessor E1 :initarg :E1 :initform nil
 			:rfc-type :rfc-char :rfc-length 8 :rfc-param-name "E1")

   (E2                  :accessor E2 :initarg :E2 :initform nil
 			:rfc-type :rfc-char :rfc-length 8 :rfc-param-name "E2"))

  (:rfc-object-name "ZTB_S_TEST_STRUCT02"))


(define-table Z_TB_T_TEST_TABLE01 (sapnwrfc-object)

  ((LINE_NUMBER         :accessor LINE_NUMBER :initarg :LINE_NUMBER :initform nil
 			:rfc-type :rfc-numc :rfc-length 6 :rfc-param-name "LINE_NUMBER")

   (E1                  :accessor E1 :initarg :E1 :initform nil
 	 		:rfc-type :rfc-char :rfc-length 8 :rfc-param-name "E1")

   (E2                  :accessor E2 :initarg :E2 :initform nil
 	 		:rfc-type ZTB_S_TEST_STRUCT02 :rfc-param-name "E2"))

  (:rfc-object-name "Z_TB_T_TEST_TABLE01"))


(define-client-function Z_TB_TEST_002_TABLE (sapnwrfc-object)

  ((IT_TABLE01 :accessor IT_TABLE01 :initarg :IT_TABLE01 :initform nil
 	       :rfc-type Z_TB_T_TEST_TABLE01 :rfc-param-name "IT_TABLE01" :rfc-kind :importing)

   (ET_TABLE01 :accessor ET_TABLE01 :initform nil
 	       :rfc-type Z_TB_T_TEST_TABLE01 :rfc-param-name "ET_TABLE01" :rfc-kind :exporting))

  (:rfc-object-name "Z_TB_TEST_002_TABLE"))


(defun tb-sapwrfc-test-002 ()

  (let* ((conn       (make-stu-kw0-connection))
 	 (s-e2-1     (make-instance 'ZTB_S_TEST_STRUCT02 :e1 "E1-1" :e2 "E2-1"))
 	 (s-e2-2     (make-instance 'ZTB_S_TEST_STRUCT02 :e1 "E1-2" :e2 "E2-2"))
 	 (it-table01 (make-instance 'Z_TB_T_TEST_TABLE01))
 	 (fn         (make-instance 'Z_TB_TEST_002_TABLE :it_table01 it-table01)))

    (make-and-add-entry it-table01 :line_number "000001" :e1 "E1" :e2 s-e2-1)
    (make-and-add-entry it-table01 :line_number "000002" :e1 "E2" :e2 s-e2-2)

    (funcall fn conn)))

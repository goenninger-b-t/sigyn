;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-

#+sigyn-production
(declaim (optimize (speed 3) (compilation-speed 0) (safety 1) (debug 1)))

(cl:in-package "NET.GOENNINGER.SIGYN.CORE")

;;; ---------------------------------------------------------------------------

;;; --- SPECIAL VARS ---

(eval-when (:compile-toplevel :execute :load-toplevel)
  (defparameter *rfc-sap-uc-encoding* :utf-16le)
  (defparameter *rfc-server-timeout* 5) ;; server timout in seconds [s]
  )

;;; ---------------------------------------------------------------------------

(cffi:defcfun ("memset" memset) (:pointer :void)
  (dest (:pointer :void))
  (ch :int)
  (count :uint))

(defparameter *lock-rfc-sap-uc-encoding* (bt:make-recursive-lock))

(declaim (inline set-*rfc-sap-uc-encoding*))
(defun set-*rfc-sap-uc-encoding* (encoding)
  (declare (type keyword encoding))
  (bt:with-recursive-lock-held (*lock-rfc-sap-uc-encoding*)
    (setq *rfc-sap-uc-encoding* encoding)))

(declaim (inline rfc-sap-uc-encoding))
(defun rfc-sap-uc-encoding ()
  (bt:with-recursive-lock-held (*lock-rfc-sap-uc-encoding*)
    *rfc-sap-uc-encoding*))

(declaim (inline rfc-sap-uc-char-size))
(defun rfc-sap-uc-char-size (&optional (encoding *rfc-sap-uc-encoding*))
  (declare (ignore encoding))
  (cffi:foreign-type-size 'sap-uc))

(declaim (inline foreign-string-buffer))
(defun foreign-string-buffer (lisp-string-length &optional (encoding *rfc-sap-uc-encoding*))
  (let* ((buffer-size (+ 2 (* (rfc-sap-uc-char-size encoding) lisp-string-length)))
	 (buffer-ptr (cffi:foreign-alloc 'sap-uc :count buffer-size)))
    (memset buffer-ptr 0 buffer-size)
    (values buffer-ptr buffer-size)))

(declaim (inline sap-uc-string-to-lisp))
(defun sap-uc-string-to-lisp (sap-uc-pointer &optional (encoding *rfc-sap-uc-encoding*))
  (if (not (cffi:null-pointer-p sap-uc-pointer))
      (cffi:foreign-string-to-lisp sap-uc-pointer :encoding encoding)))

(declaim (inline lisp-to-sap-uc-string))
(defun lisp-to-sap-uc-string (lisp-string &optional (encoding *rfc-sap-uc-encoding*))
  (multiple-value-bind (buffer-ptr buffer-size)
      (foreign-string-buffer (length lisp-string) encoding)
    (cffi:lisp-string-to-foreign lisp-string buffer-ptr buffer-size :encoding encoding)))

(defmacro with-lisp-to-sap-uc-string ((lisp-string var &optional (encoding *rfc-sap-uc-encoding*)) &body body)
  `(let ((,var (cffi:null-pointer)))
     (unwind-protect
	  (progn
	    (setq ,var (lisp-to-sap-uc-string ,lisp-string ,encoding))
	    (progn
	      ,@body))
       (if (not (cffi:null-pointer-p ,var))
	   (cffi:foreign-free ,var)))))

(defmacro with-lisp-to-sap-uc-strings (bindings &body body)
  (if bindings
      `(with-lisp-to-sap-uc-string ,(car bindings)
	 (with-lisp-to-sap-uc-strings ,(cdr bindings)
	   ,@body))
      `(progn ,@body)))

(defmacro with-rfc-connection-parameter ((var name value &optional (encoding *rfc-sap-uc-encoding*)) &body body)
  (let ((g-fs-name (gensym))
	(g-fs-value (gensym)))
    `(cffi:with-foreign-object (,var 'rfc-connection-parameter)
       (with-lisp-to-sap-uc-strings ((,name ,g-fs-name :encoding ,encoding)
				     (,value ,g-fs-value :encoding ,encoding))
	 (setf (cffi:foreign-slot-value ,var 'rfc-connection-parameter 'name) ,g-fs-name)
	 (setf (cffi:foreign-slot-value ,var 'rfc-connection-parameter 'value) ,g-fs-value)
	 ,@body))))

(declaim (inline set-rfc-connection-parameter))
(defun set-rfc-connection-parameter (ptr lisp-name lisp-value)
  (let ((name-ptr (lisp-to-sap-uc-string lisp-name))
	(value-ptr (lisp-to-sap-uc-string lisp-value)))
    (setf (cffi:foreign-slot-value ptr '(:struct rfc-connection-parameter) 'name) name-ptr)
    (setf (cffi:foreign-slot-value ptr '(:struct rfc-connection-parameter) 'value) value-ptr))
  ptr)

(declaim (inline zero-rfc-connection-parameter))
(defun zero-rfc-connection-parameter (ptr)
  (setf (cffi:foreign-slot-value ptr '(:struct rfc-connection-parameter) 'name) (cffi:null-pointer))
  (setf (cffi:foreign-slot-value ptr '(:struct rfc-connection-parameter) 'value) (cffi:null-pointer)))

(declaim (inline print-rfc-connection-parameter))
(defun print-rfc-connection-parameter (ptr &optional (stream *debug-io*))
  (let ((name-ptr (cffi:foreign-slot-value ptr '(:struct rfc-connection-parameter) 'name))
	(value-ptr (cffi:foreign-slot-value ptr '(:struct rfc-connection-parameter) 'value)))
    (print-unreadable-object (ptr stream :type t :identity t)
      (format stream "~S :NAME-PTR ~S :VALUE-PTR ~S" ptr name-ptr value-ptr))))

(declaim (inline free-rfc-connection-parameter))
(defun free-rfc-connection-parameter-contents (ptr)
  (let ((name-ptr (cffi:foreign-slot-value ptr '(:struct rfc-connection-parameter) 'name))
	(value-ptr (cffi:foreign-slot-value ptr '(:struct rfc-connection-parameter) 'value)))
    (cffi:foreign-free name-ptr)
    (cffi:foreign-free value-ptr)
    (values)))

(defmacro with-rfc-connection-parameters ((var nr-conn-params-var conn-params-list) &body body)
  `(let ((,nr-conn-params-var (length ,conn-params-list)))
     (cffi:with-foreign-object (,var '(:struct rfc-connection-parameter) ,nr-conn-params-var)
       (loop
	  for index from 0 below ,nr-conn-params-var
	  for connection-parameter in ,conn-params-list
	  do
	    (let ((conn-param-ptr (cffi:mem-aptr ,var '(:struct rfc-connection-parameter) index)))
	      (zero-rfc-connection-parameter conn-param-ptr)
	      (set-rfc-connection-parameter conn-param-ptr
					    (car connection-parameter)
					    (cdr connection-parameter))))
       (unwind-protect
	    (progn
	      ,@body)
	 (loop
	    for index from 0 below ,nr-conn-params-var
	    do
	      (free-rfc-connection-parameter-contents
	       (cffi:mem-aptr ,var '(:struct rfc-connection-parameter) index)))))))

;;; ---------------------------------------------------------------------------
;;; HIGH LEVEL RFC API
;;; ---------------------------------------------------------------------------

(defun setenv (var value &optional (overwrite nil))
  #+allegro
  (excl.osi:setenv var value overwrite))

(declaim (inline rfc-get-version))
(defun rfc-get-version ()
  (let ((p-sap-uc nil))
    (cffi:with-foreign-objects ((p-major :uint)
				(p-minor :uint)
				(p-patch-level :uint))
      (setq p-sap-uc (%rfc-get-version p-major p-minor p-patch-level))
      (values (sap-uc-string-to-lisp p-sap-uc)
	      (cffi:mem-ref p-major :uint)
	      (cffi:mem-ref p-minor :uint)
	      (cffi:mem-ref p-patch-level :uint)))))

(defmacro with-rfc-error-info ((var) &body body)
  `(cffi:with-foreign-object (,var '(:struct rfc-error-info))
     ,@body))

(defclass rfc-error-info ()
  ((code            :accessor code            :initarg :code            :initform :rfc-ok)
   (group           :accessor group           :initarg :group           :initform :ok)
   (key             :accessor key             :initarg :key             :initform "")
   (message         :accessor message         :initarg :message         :initform "")
   (abap-msg-class  :accessor abap-msg-class  :initarg :abap-msg-class  :initform "")
   (abap-msg-type   :accessor abap-msg-type   :initarg :abap-msg-type   :initform "")
   (abap-msg-number :accessor abap-msg-number :initarg :abap-msg-number :initform "000")
   (abap-msg-v1     :accessor abap-msg-v1     :initarg :abap-msg-v1     :initform "")
   (abap-msg-v2     :accessor abap-msg-v2     :initarg :abap-msg-v2     :initform "")
   (abap-msg-v3     :accessor abap-msg-v3     :initarg :abap-msg-v3     :initform "")
   (abap-msg-v4     :accessor abap-msg-v4     :initarg :abap-msg-v4     :initform "")))

(defmacro %rfc-e-i-sap-uc-slot-value (error-info-ptr slot encoding)
  (let ((g-result (gensym)))
    `(let ((,g-result (sap-uc-string-to-lisp
		       (cffi:foreign-slot-pointer ,error-info-ptr
						  '(:struct rfc-error-info) ',slot) ,encoding)))
       ,g-result)))

(defmacro %set-rfc-e-i-sap-uc-slot-value (error-info-ptr slot value
					  &optional (encoding *rfc-sap-uc-encoding*))
  `(progn
     (setf (cffi:foreign-slot-pointer ,error-info-ptr
				      '(:struct rfc-error-info) ',slot)
	   (if ,value
	       (lisp-to-sap-uc-string ,value ,encoding)
	       (cffi:null-pointer)))))

(declaim (inline make-rfc-error-info-from-sap-rfc-error-info))
(defun make-rfc-error-info-from-sap-rfc-error-info (error-info-ptr
						    &optional (encoding *rfc-sap-uc-encoding*))
  (let ((code (cffi:foreign-slot-value error-info-ptr '(:struct rfc-error-info) 'code))
	(group :ok)
	(key "")
	(message "")
	(abap-msg-class "")
	(abap-msg-type "")
	(abap-msg-number "")
	(abap-msg-v1 "")
	(abap-msg-v2 "")
	(abap-msg-v3 "")
	(abap-msg-v4 ""))
    (if (not (eql code :rfc-ok))
	(progn
	  (setq group (cffi:foreign-slot-value error-info-ptr '(:struct rfc-error-info) 'group))
	  (setq key (%rfc-e-i-sap-uc-slot-value error-info-ptr key encoding))
	  (setq message (%rfc-e-i-sap-uc-slot-value error-info-ptr message encoding))
	  (setq abap-msg-class (%rfc-e-i-sap-uc-slot-value error-info-ptr abap-msg-class encoding))
	  (setq abap-msg-type (%rfc-e-i-sap-uc-slot-value error-info-ptr abap-msg-type encoding))
	  (setq abap-msg-number (%rfc-e-i-sap-uc-slot-value error-info-ptr abap-msg-number encoding))
	  (setq abap-msg-v1 (%rfc-e-i-sap-uc-slot-value error-info-ptr abap-msg-v1 encoding))
	  (setq abap-msg-v2 (%rfc-e-i-sap-uc-slot-value error-info-ptr abap-msg-v2 encoding))
	  (setq abap-msg-v3 (%rfc-e-i-sap-uc-slot-value error-info-ptr abap-msg-v3 encoding))
	  (setq abap-msg-v4 (%rfc-e-i-sap-uc-slot-value error-info-ptr abap-msg-v4 encoding))))
    (make-instance 'rfc-error-info
		   :code code
		   :group group
		   :key key
		   :message message
		   :abap-msg-class abap-msg-class
		   :abap-msg-type abap-msg-type
		   :abap-msg-number abap-msg-number
		   :abap-msg-v1 abap-msg-v1
		   :abap-msg-v2 abap-msg-v2
		   :abap-msg-v3 abap-msg-v3
		   :abap-msg-v4 abap-msg-v4)))

(defmethod print-object ((object rfc-error-info) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (with-slots (code group key message abap-msg-class abap-msg-type abap-msg-number abap-msg-v1 abap-msg-v2 abap-msg-v3 abap-msg-v4) object
      (format stream ":code ~S :group ~S :key ~s :message ~S :abap-msg-class ~S :abap-msg-type ~S :abap-msg-number ~S :abap-msg-v1 ~S :abap-msg-v2 ~S :abap-msg-v3 ~S :abap-msg-v4 ~S" code group key message abap-msg-class abap-msg-type abap-msg-number abap-msg-v1 abap-msg-v2 abap-msg-v3 abap-msg-v4))))

(declaim (inline set-sap-error-info-from-rfc-error-info))
(defun set-sap-error-info-from-rfc-error-info (rfc-error-info error-info-ptr)
  (setf (cffi:foreign-slot-value error-info-ptr '(:struct rfc-error-info) 'code) (code rfc-error-info))
  (setf (cffi:foreign-slot-value error-info-ptr '(:struct rfc-error-info) 'group) (group rfc-error-info))
  (values))

(declaim (inline log-rfc-condition))
(defun log-rfc-condition (rfc-condition)
  (log:error "~A" rfc-condition))

(declaim (inline signal-rfc-condition))
(defun signal-rfc-condition (rfc-error-info &key (on-error :signal-error) (log-condition t))
  (let* ((condition-class (case (group rfc-error-info)
			    (:abap-application-failure       'abap-application-failure)
			    (:abap-runtime-failure           'abap-runtime-failure)
			    (:logon-failure                  'logon-failure)
			    (:communication-failure          'communication-failure)
			    (:external-runtime-failure       'external-runtime-failure)
			    (:external-application-failure   'external-application-failure)
			    (:external-authorization-failure 'external-authorization-failure)
			    (otherwise                       'rfc-error)))
	 (condition (make-condition condition-class
				    :rfc-error-info rfc-error-info)))
    (if (eql log-condition t)
	(log-rfc-condition condition))
    (if (eql on-error :signal-error)
	(error condition)
	(signal condition)))
  (values))

(declaim (inline check-and-handle-rfc-error-info))
(defun check-and-handle-rfc-error-info (error-info-ptr &key (on-error :signal-error) (encoding *rfc-sap-uc-encoding*))
  (let* ((rfc-error-info (make-rfc-error-info-from-sap-rfc-error-info error-info-ptr encoding))
	 (rc (code rfc-error-info)))
    (if (not (eql rc :rfc-ok))
	(signal-rfc-condition rfc-error-info :on-error on-error :log-condition t))
    rc))

(declaim (inline rfc-connection-handle-set-p))
(defun rfc-connection-handle-set-p (connection-handle)
  (not (or (not connection-handle)
	   (cffi:null-pointer-p connection-handle))))

(declaim (inline rfc-is-connection-handle-valid))
(defun rfc-is-connection-handle-valid (connection-handle)
  (cffi:with-foreign-object (is-valid-ptr :int)
    (%rfc-is-connection-handle-valid connection-handle is-valid-ptr (cffi:null-pointer))
    (cffi:mem-ref is-valid-ptr :uint)))

(declaim (inline rfc-connection-handle-valid-p))
(defun rfc-connection-handle-valid-p (connection-handle)
  (and (rfc-connection-handle-set-p connection-handle)
       (= (rfc-is-connection-handle-valid connection-handle) 1)
       (eql (rfc-ping connection-handle :on-error :ignore) :rfc-ok)))

(declaim (inline check-rfc-connection-handle))
(defun check-rfc-connection-handle (connection-handle)
  (if (not (rfc-connection-handle-valid-p connection-handle))
      (error "Invalid RFC Connection Handle!")
      ))

(declaim (inline rfc-close-connection))
(defun rfc-close-connection (connection-handle)
  (if (rfc-connection-handle-valid-p connection-handle)
      (with-rfc-error-info (error-info-ptr)
	(log:debug "Closing RFC connection #x~X ..." connection-handle)
	(let ((rc (%rfc-close-connection connection-handle error-info-ptr)))
	  (ignore-errors
	   (check-and-handle-rfc-error-info error-info-ptr :on-error nil))
	  rc))))

(defmacro %connection-attribute (attr-ptr attr encoding)
  `(progn
     (let* ((ptr (cffi:foreign-slot-pointer ,attr-ptr '(:struct rfc-attributes) ,attr))
	    (result (sap-uc-string-to-lisp ptr ,encoding)))
       result)))

(declaim (inline rfc-get-connection-attributes))
(defun rfc-get-connection-attributes (connection-handle
				      &optional (encoding *rfc-sap-uc-encoding*))
  (with-rfc-error-info (error-info-ptr)
    (cffi:with-foreign-object (attr-ptr '(:struct rfc-attributes))
      (let ((rc (%rfc-get-connection-attributes connection-handle attr-ptr error-info-ptr)))
	(check-and-handle-rfc-error-info error-info-ptr)
	(list rc
	      (list (%connection-attribute attr-ptr 'dest encoding)
		    (%connection-attribute attr-ptr 'host encoding)
		    (%connection-attribute attr-ptr 'partner-host encoding)
		    (%connection-attribute attr-ptr 'sys-number encoding)
		    (%connection-attribute attr-ptr 'sys-id encoding)
		    (%connection-attribute attr-ptr 'client encoding)
		    (%connection-attribute attr-ptr 'user encoding)
		    (%connection-attribute attr-ptr 'language encoding)
		    (%connection-attribute attr-ptr 'trace encoding)
		    (%connection-attribute attr-ptr 'iso-language encoding)
		    (%connection-attribute attr-ptr 'codepage encoding)
		    (%connection-attribute attr-ptr 'partner-codepage encoding)
		    (%connection-attribute attr-ptr 'rfc-role encoding)
		    (%connection-attribute attr-ptr 'type encoding)
		    (%connection-attribute attr-ptr 'partner-type encoding)
		    (%connection-attribute attr-ptr 'rel encoding)
		    (%connection-attribute attr-ptr 'partner-rel encoding)
		    (%connection-attribute attr-ptr 'kernel-rel encoding)
		    (%connection-attribute attr-ptr 'cpic-conv-id encoding)
		    (%connection-attribute attr-ptr 'prog-name encoding)
		    (%connection-attribute attr-ptr 'partner-bytes-per-char encoding)
		    (%connection-attribute attr-ptr 'partner-system-codepage encoding)
		    (%connection-attribute attr-ptr 'partner-ip encoding)
		    (%connection-attribute attr-ptr 'partner-ipv6 encoding)))))))

(declaim (inline rfc-open-connection))
(defun rfc-open-connection (connection-parameter-list)
  (if (not (listp connection-parameter-list))
      (error "Parameter CONNECTION-PARAMETER-LIST must be a list of RFC Connection Parameters."))
  (with-rfc-connection-parameters (conn-param-ptr nr-params connection-parameter-list)
    (with-rfc-error-info (error-info-ptr)
      (let ((connection-handle (%rfc-open-connection conn-param-ptr nr-params error-info-ptr)))
	(if (cffi:null-pointer-p connection-handle)
	    (check-and-handle-rfc-error-info error-info-ptr))
	connection-handle))))

(let ((initialized-p nil))

  (defun rfc-init (&key (load-libs t) (lib-dir *sapnwrfc-foreign-libdir*))
    (if (not initialized-p)
	(progn
	  (when lib-dir
	    (setq *sapnwrfc-foreign-libdir* lib-dir))
	  (when load-libs
	    (load-sapnwrfc-libs))
	  (setq initialized-p t)))
    initialized-p)

  (defun rfc-reset (&key (unload-libs t))
    (if initialized-p
	(progn
	  (when unload-libs
	    (unload-sapnwrfc-libs))
	  (setq initialized-p nil)))
    initialized-p))

(declaim (inline rfc-ping))
(defun rfc-ping (connection-handle &key (on-error :signal-error))
  (with-rfc-error-info (error-info-ptr)
    (let ((rc (%rfc-ping connection-handle error-info-ptr)))
      (check-and-handle-rfc-error-info error-info-ptr :on-error on-error)
      rc)))

(declaim (inline rfc-get-function-desc))
(defun rfc-get-function-desc (connection-handle func-name)
  (check-rfc-connection-handle connection-handle)
  (with-rfc-error-info (error-info-ptr)
    (with-lisp-to-sap-uc-string (func-name foreign-string-ptr)
      (let ((desc (%rfc-get-function-desc connection-handle
					  foreign-string-ptr
					  error-info-ptr)))
	(check-and-handle-rfc-error-info error-info-ptr)
	desc))))

(declaim (inline rfc-create-function))
(defun rfc-create-function (func-desc)
  (with-rfc-error-info (error-info-ptr)
    (let ((func (%rfc-create-function func-desc error-info-ptr)))
      (check-and-handle-rfc-error-info error-info-ptr)
      func)))

(declaim (inline rfc-destroy-function))
(defun rfc-destroy-function (func-handle)
  (with-rfc-error-info (error-info-ptr)
    (let ((rc (%rfc-destroy-function func-handle error-info-ptr)))
      (check-and-handle-rfc-error-info error-info-ptr)
      rc)))

(declaim (inline rfc-function))
(defun rfc-function (connection-handle func-name)
  (let* ((func-desc-handle (rfc-get-function-desc connection-handle func-name))
	 (func-handle (rfc-create-function func-desc-handle)))
    func-handle))

(declaim (inline rfc-invoke))
(defun rfc-invoke (connection-handle func-handle)
  (with-rfc-error-info (error-info-ptr)
    (let ((rc (%rfc-invoke connection-handle func-handle error-info-ptr)))
      (check-and-handle-rfc-error-info error-info-ptr)
      rc)))

(declaim (inline rfc-get-structure))
(defun rfc-get-structure (container-handle struct-name)
  (cffi:with-foreign-object (struct-handle-ptr 'rfc-structure-handle)
    (if (not (cffi:null-pointer-p struct-handle-ptr))
	(with-rfc-error-info (error-info-ptr)
	  (with-lisp-to-sap-uc-string (struct-name foreign-string-ptr)
	    (%rfc-get-structure container-handle foreign-string-ptr struct-handle-ptr error-info-ptr)
	    (check-and-handle-rfc-error-info error-info-ptr)
	    (cffi:mem-ref struct-handle-ptr 'rfc-structure-handle)))
	(cffi:null-pointer))))

(declaim (inline rfc-get-table))
(defun rfc-get-table (container-handle table-name)
  (cffi:with-foreign-object (table-handle-ptr 'rfc-table-handle)
    (if (not (cffi:null-pointer-p table-handle-ptr))
	(with-rfc-error-info (error-info-ptr)
	  (with-lisp-to-sap-uc-string (table-name foreign-string-ptr)
	    (%rfc-get-table container-handle foreign-string-ptr table-handle-ptr error-info-ptr)
	    (check-and-handle-rfc-error-info error-info-ptr)
	    (cffi:mem-ref table-handle-ptr 'rfc-table-handle)))
	(cffi:null-pointer))))

(declaim (inline rfc-get-current-row))
(defun rfc-get-current-row (table-handle)
  (with-rfc-error-info (error-info-ptr)
    (let ((result (%rfc-get-current-row table-handle error-info-ptr)))
      (check-and-handle-rfc-error-info error-info-ptr)
      result)))

(declaim (inline rfc-append-new-row))
(defun rfc-append-new-row (table-handle)
  (with-rfc-error-info (error-info-ptr)
    (let ((result (%rfc-append-new-row table-handle error-info-ptr)))
      (check-and-handle-rfc-error-info error-info-ptr)
      result)))

(declaim (inline rfc-append-new-rows))
(defun rfc-append-new-rows (table-handle num-rows)
  (with-rfc-error-info (error-info-ptr)
    (let ((result (%rfc-append-new-rows table-handle num-rows error-info-ptr)))
      (check-and-handle-rfc-error-info error-info-ptr)
      result)))

(declaim (inline rfc-insert-new-row))
(defun rfc-insert-new-row (table-handle)
  (with-rfc-error-info (error-info-ptr)
    (let ((result (%rfc-insert-new-row table-handle error-info-ptr)))
      (check-and-handle-rfc-error-info error-info-ptr)
      result)))

(declaim (inline rfc-append-row))
(defun rfc-append-row (table-handle structure-handle)
  (with-rfc-error-info (error-info-ptr)
    (let ((result (%rfc-append-row table-handle structure-handle error-info-ptr)))
      (check-and-handle-rfc-error-info error-info-ptr)
      result)))

(declaim (inline rfc-insert-row))
(defun rfc-insert-row (table-handle structure-handle)
  (with-rfc-error-info (error-info-ptr)
    (let ((result (%rfc-insert-row table-handle structure-handle error-info-ptr)))
      (check-and-handle-rfc-error-info error-info-ptr)
      result)))

(declaim (inline rfc-delete-current-row))
(defun rfc-delete-current-row (table-handle)
  (with-rfc-error-info (error-info-ptr)
    (let ((result (%rfc-delete-current-row table-handle error-info-ptr)))
      (check-and-handle-rfc-error-info error-info-ptr)
      result)))

(declaim (inline rfc-delete-all-rows))
(defun rfc-delete-all-rows (table-handle)
  (with-rfc-error-info (error-info-ptr)
    (let ((result (%rfc-delete-all-rows table-handle error-info-ptr)))
      (check-and-handle-rfc-error-info error-info-ptr)
      result)))

(declaim (inline rfc-move-to-first-row))
(defun rfc-move-to-first-row (table-handle)
  (with-rfc-error-info (error-info-ptr)
    (let ((result (%rfc-move-to-first-row table-handle error-info-ptr)))
      (check-and-handle-rfc-error-info error-info-ptr)
      result)))

(declaim (inline rfc-move-to-last-row))
(defun rfc-move-to-last-row (table-handle)
  (with-rfc-error-info (error-info-ptr)
    (let ((result (%rfc-move-to-last-row table-handle error-info-ptr)))
      (check-and-handle-rfc-error-info error-info-ptr)
      result)))

(declaim (inline rfc-move-to-next-row))
(defun rfc-move-to-next-row (table-handle)
  (with-rfc-error-info (error-info-ptr)
    (let ((result (%rfc-move-to-next-row table-handle error-info-ptr)))
      (check-and-handle-rfc-error-info error-info-ptr)
      result)))

(declaim (inline rfc-move-to-previous-row))
(defun rfc-move-to-previous-row (table-handle)
  (with-rfc-error-info (error-info-ptr)
    (let ((result (%rfc-move-to-previous-row table-handle error-info-ptr)))
      (check-and-handle-rfc-error-info error-info-ptr)
      result)))

(declaim (inline rfc-move-to))
(defun rfc-move-to (table-handle index)
  (with-rfc-error-info (error-info-ptr)
    (let ((result (%rfc-move-to table-handle index error-info-ptr)))
      (check-and-handle-rfc-error-info error-info-ptr)
      result)))

(declaim (inline rfc-get-row-count))
(defun rfc-get-row-count (table-handle)
  (cffi:with-foreign-object (uint-ptr :uint)
    (if (not (cffi:null-pointer-p uint-ptr))
	(with-rfc-error-info (error-info-ptr)
	  (%rfc-get-row-count table-handle uint-ptr error-info-ptr)
	  (check-and-handle-rfc-error-info error-info-ptr)
	  (cffi:mem-ref uint-ptr :uint))
	nil)))

(declaim (inline rfc-get-string))
(defun rfc-get-string (container-handle param-name string-length &optional (encoding *rfc-sap-uc-encoding*))
  (with-rfc-error-info (error-info-ptr)
    (multiple-value-bind (buffer-ptr buffer-size)
	(foreign-string-buffer string-length encoding)
      (unwind-protect
	   (with-lisp-to-sap-uc-string (param-name param-name-ptr encoding)
	     (cffi:with-foreign-object (size-ptr :uint)
	       (%rfc-get-string container-handle param-name-ptr buffer-ptr (1+ string-length) size-ptr error-info-ptr)
	       (check-and-handle-rfc-error-info error-info-ptr)
	       (sap-uc-string-to-lisp buffer-ptr encoding)))
	(cffi:foreign-free buffer-ptr)))))

(declaim (inline rfc-get-chars))
(defun rfc-get-chars (container-handle param-name buffer-length &optional (encoding *rfc-sap-uc-encoding*))
  (with-rfc-error-info (error-info-ptr)
    (multiple-value-bind (buffer-ptr buffer-size)
	(foreign-string-buffer buffer-length encoding)
      (unwind-protect
	   (with-lisp-to-sap-uc-string (param-name param-name-ptr encoding)
	     (%rfc-get-chars container-handle param-name-ptr buffer-ptr buffer-length error-info-ptr)
	     (check-and-handle-rfc-error-info error-info-ptr)
	     (sap-uc-string-to-lisp buffer-ptr encoding))
	(cffi:foreign-free buffer-ptr)))))

(declaim (inline rfc-get-int))
(defun rfc-get-int (container-handle param-name &optional (encoding *rfc-sap-uc-encoding*))
  (with-rfc-error-info (error-info-ptr)
    (cffi:with-foreign-object (buffer-ptr :int)
      (with-lisp-to-sap-uc-string (param-name param-name-ptr encoding)
	(%rfc-get-int container-handle param-name-ptr buffer-ptr error-info-ptr)
	(check-and-handle-rfc-error-info error-info-ptr)
	(cffi:mem-ref buffer-ptr :int)))))

(declaim (inline rfc-get-float))
(defun rfc-get-float (container-handle param-name &optional (encoding *rfc-sap-uc-encoding*))
  (with-rfc-error-info (error-info-ptr)
    (cffi:with-foreign-object (buffer-ptr :double)
      (with-lisp-to-sap-uc-string (param-name param-name-ptr encoding)
	(%rfc-get-float container-handle param-name-ptr buffer-ptr error-info-ptr)
	(check-and-handle-rfc-error-info error-info-ptr)
	(cffi:mem-ref buffer-ptr :int)))))

(declaim (inline rfc-set-chars))
(defun rfc-set-chars (container-handle
		      param-name
		      value
		      value-length
		      &optional (encoding *rfc-sap-uc-encoding*))
  (with-rfc-error-info (error-info-ptr)
    (with-lisp-to-sap-uc-strings ((param-name param-name-ptr encoding)
				  (value value-ptr encoding))
      (let ((rc (%rfc-set-chars container-handle param-name-ptr value-ptr value-length error-info-ptr)))
	(check-and-handle-rfc-error-info error-info-ptr)
	rc))))

(declaim (inline rfc-set-string))
(defun rfc-set-string (container-handle
		       param-name
		       value
		       value-length
		       &optional (encoding *rfc-sap-uc-encoding*))
  (with-rfc-error-info (error-info-ptr)
    (with-lisp-to-sap-uc-strings ((param-name param-name-ptr encoding)
				  (value value-ptr encoding))
      (let ((rc (%rfc-set-string container-handle param-name-ptr value-ptr value-length error-info-ptr)))
	(check-and-handle-rfc-error-info error-info-ptr)
	rc))))

(declaim (inline rfc-set-int))
(defun rfc-set-int (container-handle
		    param-name
		    value
		    &optional (encoding *rfc-sap-uc-encoding*))
  (with-rfc-error-info (error-info-ptr)
    (with-lisp-to-sap-uc-string (param-name param-name-ptr encoding)
      (let ((rc (%rfc-set-int container-handle param-name-ptr value error-info-ptr)))
	(check-and-handle-rfc-error-info error-info-ptr)
	rc))))

(declaim (inline rfc-set-float))
(defun rfc-set-float (container-handle
		      param-name
		      value
		      &optional (encoding *rfc-sap-uc-encoding*))
  (with-rfc-error-info (error-info-ptr)
    (with-lisp-to-sap-uc-string (param-name param-name-ptr encoding)
      (let ((rc (%rfc-set-float container-handle param-name-ptr value error-info-ptr)))
	(check-and-handle-rfc-error-info error-info-ptr)
	rc))))

(declaim (inline rfc-set-bytes))
(defun rfc-set-bytes (container-handle
		      param-name
		      byte-value
		      value-length
		      &optional (encoding *rfc-sap-uc-encoding*))
  (with-rfc-error-info (error-info-ptr)
    (with-lisp-to-sap-uc-string (param-name param-name-ptr encoding)
      (let ((rc (%rfc-set-bytes container-handle param-name-ptr byte-value value-length error-info-ptr)))
	(check-and-handle-rfc-error-info error-info-ptr)
	rc))))

(declaim (inline rfc-set-xstring))
(defun rfc-set-xstring (container-handle
			param-name
			byte-value
			value-length
			&optional (encoding *rfc-sap-uc-encoding*))
  (with-rfc-error-info (error-info-ptr)
    (with-lisp-to-sap-uc-string (param-name param-name-ptr encoding)
      (let ((rc (%rfc-set-xstring container-handle param-name-ptr byte-value value-length error-info-ptr)))
	(check-and-handle-rfc-error-info error-info-ptr)
	rc))))

;;; ---------------------------------------------------------------------------
;;;    RFC SERVER FUNCTIONALITY
;;; ---------------------------------------------------------------------------

(defun %install-server-function (sys-id-ptr func-desc-handle server-fn-ptr)
  (with-rfc-error-info (error-info-ptr)
    (let ((rc (%rfc-install-server-function sys-id-ptr func-desc-handle server-fn-ptr error-info-ptr)))
      (check-and-handle-rfc-error-info error-info-ptr)
      rc)))

(declaim (inline rfc-install-server-function))
(defun rfc-install-server-function (sys-id func-desc-handle server-fn-ptr)
  (if sys-id
      (with-lisp-to-sap-uc-string (sys-id sys-id-ptr)
	(%install-server-function sys-id-ptr func-desc-handle server-fn-ptr))
      (%install-server-function (cffi:null-pointer) func-desc-handle server-fn-ptr)))

(declaim (inline rfc-register-server))
(defun rfc-register-server (server-connection-parameter-list)
  #-rfc-api-production
  (progn
    (if (not (listp server-connection-parameter-list))
	(error "Parameter SEREVR-CONNECTION-PARAMETER-LIST must be a list of RFC Connection Parameters.")))
  (with-rfc-connection-parameters (conn-param-ptr nr-params server-connection-parameter-list)
    (with-rfc-error-info (error-info-ptr)
      (let ((server-handle (%rfc-register-server conn-param-ptr nr-params error-info-ptr)))
	(log:debug "Registering RFC Server: Server handle = ~S" server-handle)
	(if (cffi:null-pointer-p server-handle)
	    (progn
	      (check-and-handle-rfc-error-info error-info-ptr)
	      (cffi:null-pointer))
	    server-handle)))))

(declaim (inline rfc-listen-and-dispatch))
(defun rfc-listen-and-dispatch (connection-handle timeout)
  (with-rfc-error-info (error-info-ptr)
    (let ((rc (%rfc-listen-and-dispatch connection-handle timeout error-info-ptr)))
      (check-and-handle-rfc-error-info error-info-ptr :on-error :ignore)
      rc)))

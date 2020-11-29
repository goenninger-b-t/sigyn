;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-

(cl:in-package "CL-USER")

(asdf:defsystem #:sigyn.sapnwrfc
    :description "SIGYN.SAPNWRFC provides a high-level API to the SAP Netweaver RFC Library."
  :author "Goenninger B&T <support@goenninger.net>"
  :maintainer "#frgo, a.k.a. Frank Goenninger <frank.goenninger@goenninger.net>"
  :license  "Proprietary. All Rights reserved."
  :version "1.0.3"
  :depends-on (:uiop
	       :closer-mop
	       :waaf-cffi
	       :local-time
	       :uuid
	       :sigyn.core)
  :serial t
  :components
  ((:module sigyn.core
    :pathname "src/sapnwrfc/"
    :components
    ((:file "package")
     (:file "connection")
     ;;(:file "connection-pool")
     (:file "object-class")
     (:file "client-object-read-write")
     (:file "client-function")
     (:file "server-function")
     (:file "param-get-set")
     (:file "structure")
     (:file "structure-read-write")
     (:file "table")
     (:file "table-read-write")
     ))))

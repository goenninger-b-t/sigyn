;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-

(cl:in-package "CL-USER")

(asdf:defsystem #:sigyn.core
    :description "SIGYN provides Common Lisp bindings to the SAP Netweaver RFC Library."
    :author "Goenninger B&T <support@goenninger.net>"
    :maintainer "#frgo, a.k.a. Frank Goenninger <frank.goenninger@goenninger.net>"
    :license  "Proprietary. All Rights reserved."
    :version "1.0.3"
    :depends-on (:uiop
		 :trivial-features
		 :alexandria
		 :serapeum
		 :cffi-libffi)
    :serial t
    :components
    ((:module sigyn.core
      :pathname "src/core/"
      :components
      ((:file "package")
       (:file "libsapnwrfc")
       (:file "conditions")
       (:file "rfc-error-handling")
       (:file "init")
       (:file "bindings")
       (:file "rfc-api")
       ))))

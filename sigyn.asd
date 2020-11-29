;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-

(cl:in-package "CL-USER")

(asdf:defsystem #:sigyn
    :description "SIGYN provides Common Lisp bindings and a high-level API to the SAP Netweaver RFC Library."
  :author "Goenninger B&T <support@goenninger.net>"
  :maintainer "#frgo, a.k.a. Frank Goenninger <frank.goenninger@goenninger.net>"
  :license  "Proprietary. All Rights reserved."
  :version "1.0.3"
  :depends-on (:uiop
	       :sigyn.core
	       :sigyn.sapnwrfc)
  :serial t
  :components
  ((:module sigyn
    :pathname "src/"
    :components
    ((:file "package")))))

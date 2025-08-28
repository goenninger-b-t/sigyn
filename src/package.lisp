(cl:in-package #:cl-user) 

(uiop:define-package :net.goenninger.sigyn
    (:use :closer-common-lisp :sigyn.core :sigyn.sapnwrfc)
  (:nicknames :sigyn)
  (:reexport
   :sigyn.core
   :sigyn.sapnwrfc))

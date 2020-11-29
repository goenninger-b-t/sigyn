;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-

#+sigyn-production
(declaim (optimize (speed 3) (compilation-speed 0) (safety 1) (debug 1)))

(cl:in-package "NET.GOENNINGER.SIGYN.CORE")

;;; ---------------------------------------------------------------------------

(defun ensure-member (list elt)
  (check-type list list)
  (if (not (member elt list))
      (append list (alexandria:ensure-list elt))
      list))

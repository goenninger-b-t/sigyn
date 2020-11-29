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

(cl:in-package "NET.GOENNINGER.SIGYN.SAPNWRFC")

;;; ---------------------------------------------------------------------------

(defparameter *sapnwrfc-connection-pool-max-connections*  20)
(defparameter *sapnwrfc-connection-pool-manager-class*   'sapnwrfc-connection-pool-manager)
(defparameter *sapnwrfc-connection-pool-prune-fn*        'prune-sapnwrfc-connection-pool-as-thread)
(defparameter *sapnwrfc-connection-pool-prune-interval*   60) ;; seconds

(defmacro with-sapnwrfc-connection-pool-manager-locked ((connection-pool-manager) &body body)
  `(bt:with-lock-held ((connection-pool-manager-lock ,connection-pool-manager))
     (progn
       ,@body)))

(defun prune-sapnwrfc-connection-pool (connection-pool &key (force nil))
  (with-hash-table-iterator (next-kv (connections connection-pool))
    (multiple-value-bind (morep user-designator connection)
	(next-kv)
      (if morep
	  (progn
	    (log:debug "PRUNE-SAPNWRFC-CONNECTION-POOL: Maybe prune ~S for user-designator ~S." connection user-designator)
	    (if (maybe-release-connection connection :force force)
		(remhash user-designator (connections connection-pool)))))))
  connection-pool)

(defun prune-sapnwrfc-connection-pool-as-thread (connection-pool)
  (bt:thread-yield)
  (log:debug "PRUNE-SAPWNRFC-CONNECTION-POOL thread ~A started." (bt:thread-name (bt:current-thread)))
  (loop
    do
       (sleep (prune-interval connection-pool))
       (prune-sapnwrfc-connection-pool connection-pool)
       (bt:thread-yield)))

(defclass sapnwrfc-connection-pool-manager (net.goenninger.baldr.core::thing
					    net.goenninger.baldr.core::lifecycle)
  ((prune-interval :accessor prune-interval :initarg :prune-interval :initform *sapnwrfc-connection-pool-prune-interval*)
   (prune-fn :reader prune-fn :initarg :prune-fn :initform *sapnwrfc-connection-pool-prune-fn*)
   (connection-pool-manager-lock :reader connection-pool-manager-lock :initarg :connection-pool-manager-lock :initform (bt:make-recursive-lock (gensym "SAPNWRFC-CONNECTION-LOCK-")))
   (connection-pool-manager-prune-thread :accessor connection-pool-manager-prune-thread :initarg :connection-pool-manager-prune-thread :initform nil)))

(defmethod initalize ((self sapnwrfc-connection-pool-manager))
  (if (not (initializedp self))
      (with-sapnwrfc-connection-pool-manager-locked (self)
	(with-slots ((cpmpt connection-pool-manager-prune-thread)
		     prune-fn) self
	  (if cpmpt
	      (progn
		(release self)
		(sleep 0.1)) ;; give the thread time to die
	      )
	  (setf cpmpt (bt:make-thread (lambda ()
					(funcall prune-fn self))
				      :name (gensym "SAPNWRFC-CONNECTION-POOL-MANAGER-PRUNE-THREAD-"))))
	(setf (initialzedp self) t)))
  self)

(defmethod release ((self sapnwrfc-connection-pool-manager))
  (with-sapnwrfc-connection-pool-manager-locked (self)
    (with-slots (connection-pool-manager-prune-thread) self
      (ignore-errors (bt:destroy-thread connection-pool-manager-prune-thread))
      (setf connection-pool-manager-prune-thread nil)
      (setf (initialzedp self) t)))
  self)

(defun user-designator= (ud1 ud2)
  (check-type ud1 string)
  (check-type ud2 string)
  (string= ud1 ud2))

(defclass sapnwrfc-connection-pool (net.goenninger.baldr.core::thing)
  ((identifier  :accessor identifier  :initarg :identifier  :initform (error "IDENTIFIER required when instantiating an SAPNWRFC-CONNECTION-POOL!" ))
   (max-connections :reader max-connections :initarg :max-connections :initform  *sapnwrfc-connection-pool-max-connections*)
   (connections :accessor connections :initarg :connections :initform (make-hash-table :test 'user-designator))
   (connection-pool-manager :reader connection-pool-manager :initarg :connection-pool-manager :initform (make-instance *default-sapnwrfc-connection-pool-manager-class*))))

(defun make-sapnwrfc-connection-pool (keyword &key (uuid (uuid:make-v4-uuid)) (max-connections *sapnwrfc-connection-pool-max-connections*))
  (make-instance 'sapnwrfc-connection-pool
		 :identifier (net.goenninger.baldr.core::make-identifier keyword uuid)
		 :max-connections max-connections))

(defmethod find-connection-by-user-designator ((self sapnwrfc-connection-pool) user-designator)
  (check-type user-designator string)
  (gethash user-designator (connections self)))

(defmethod nr-connections ((self sapnwrfc-connection-pool))
  (hash-table-count (connections self)))

(defmethod nr-active-connections ((self sapnwrfc-connection-pool))
  (nr-active (connections self)))

(defmethod add-connection ((self sapnwrfc-connection-pool) (new-connection sapnwrfc-connection))
  (if (> (nr-connections self) (1- (max-connections self)))
      (progn
	(prune-sapnwrfc-connection-pool self :force t)
	(if (> (nr-connections self) (1- (max-connections self)))
	    (error "~S: BUSY: Too many connections open!"))))
  (with-slots (connections) self
    (with-slots (user-designator) new-connection
      (setf (gethash user-designator connections) new-connection)))
  self)

(defmethod remove-connection ((self sapnwrfc-connection-pool) (connection sapnwrfc-connection))
  (with-sapnwrfc-connection-pool-manager-locked (self)
    (remhash (user-designator connection) (connections self)))
  self)

;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — compat: weak tables, weak pointers, and finalizers (over
;;; trivial-garbage). Used for caches that must not pin their keys/values and for
;;; releasing GPU/native handles when their Lisp wrappers die (§ resource
;;; lifetime). Finalizers are a backstop — explicit with-* release stays primary.

(in-package #:net.goenninger.freya.compat)

(optimize-safe)

(declaim (ftype (function (&key (:test t) (:weakness symbol)) hash-table)
                make-weak-hash-table)
         (ftype (function (t) t) make-weak-pointer weak-pointer-value)
         (ftype (function (t) t) weak-pointer-p cancel-finalization)
         (ftype (function (t function) t) finalize))

(defun make-weak-hash-table (&key (test 'eql) (weakness :key))
  "A hash table whose entries may be GC'd. WEAKNESS is one of
:key :value :key-and-value :key-or-value."
  (trivial-garbage:make-weak-hash-table :test test :weakness weakness))

(defun make-weak-pointer (object)
  (trivial-garbage:make-weak-pointer object))

(defun weak-pointer-value (weak-pointer)
  "The referent, or NIL if it has been collected. Secondary value: T if live."
  (trivial-garbage:weak-pointer-value weak-pointer))

(defun weak-pointer-p (object)
  (trivial-garbage:weak-pointer-p object))

(defun finalize (object function)
  "Call FUNCTION (no args) after OBJECT is GC'd. FUNCTION must not close over OBJECT."
  (trivial-garbage:finalize object function))

(defun cancel-finalization (object)
  (trivial-garbage:cancel-finalization object))

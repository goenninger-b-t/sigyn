;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — compat: the domain type vocabulary (PLAN §17.1, ADR-0009). Signatures
;;; across Freya use these names rather than bare fixnum/double-float so intent is
;;; explicit and the compiler derives tight types.

(in-package #:net.goenninger.freya.compat)

(optimize-safe)

;;; Machine integers
(deftype octet () '(unsigned-byte 8))
(deftype u8  () '(unsigned-byte 8))
(deftype u16 () '(unsigned-byte 16))
(deftype u32 () '(unsigned-byte 32))
(deftype u64 () '(unsigned-byte 64))
(deftype i8  () '(signed-byte 8))
(deftype i16 () '(signed-byte 16))
(deftype i32 () '(signed-byte 32))
(deftype i64 () '(signed-byte 64))

;;; Floats (GPU-facing f32, CL-internal f64)
(deftype f32 () 'single-float)
(deftype f64 () 'double-float)

;;; Indices / sizes
(deftype index () "A valid array index."
  '(integer 0 #.(1- array-dimension-limit)))
(deftype nonneg-fixnum () '(integer 0 #.most-positive-fixnum))

;;; CLIM / rendering domain types
(deftype coordinate () "A CLIM coordinate (double-float, per the McCLIM convention)."
  'double-float)
(deftype dimension () "A non-negative extent." '(double-float 0d0 *))
(deftype unit-real () "A normalized value in [0,1]." '(double-float 0d0 1d0))
(deftype device-pixel () "An integer device-pixel coordinate." '(signed-byte 32))
(deftype rgba8 () "A packed 8-bit-per-channel RGBA color." '(unsigned-byte 32))

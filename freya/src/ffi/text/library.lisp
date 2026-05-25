;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — ffi.text: foreign-library discovery + load for the default text stack,
;;; FreeType (rasterization/hinting/metrics) + HarfBuzz (shaping). Optional: a
;;; pure-CL font engine is the fallback (ADR-0003). Point FREYA_FREETYPE_LIB_DIR /
;;; FREYA_HARFBUZZ_LIB_DIR (or the shared FREYA_TEXT_LIB_DIR) at the pinned builds.

(in-package #:net.goenninger.freya.ffi.text)

(net.goenninger.freya.compat:optimize-safe)

(declaim (ftype (function (string) t) %register-search-path)
         (ftype (function (&key (:force t)) t) load-libfreetype load-libharfbuzz))

(defun %register-search-path (env-var)
  (dolist (var (list env-var "FREYA_TEXT_LIB_DIR"))
    (let ((dir (uiop:getenv var)))
      (when (and dir (plusp (length dir)))
        (pushnew (uiop:ensure-directory-pathname dir)
                 cffi:*foreign-library-directories*
                 :test #'equal)))))

(cffi:define-foreign-library libfreetype
  (:darwin (:or "libfreetype.dylib" "libfreetype.6.dylib"))
  (:unix (:or "libfreetype.so" "libfreetype.so.6"))
  (:windows (:or "freetype.dll"))
  (t (:default "libfreetype")))

(cffi:define-foreign-library libharfbuzz
  (:darwin (:or "libharfbuzz.dylib" "libharfbuzz.0.dylib"))
  (:unix (:or "libharfbuzz.so" "libharfbuzz.so.0"))
  (:windows (:or "harfbuzz.dll"))
  (t (:default "libharfbuzz")))

(defvar *freetype-loaded* nil)
(defvar *harfbuzz-loaded* nil)

(defun load-libfreetype (&key force)
  (when (or force (not *freetype-loaded*))
    (%register-search-path "FREYA_FREETYPE_LIB_DIR")
    (cffi:use-foreign-library libfreetype)
    (setf *freetype-loaded* t))
  *freetype-loaded*)

(defun load-libharfbuzz (&key force)
  (when (or force (not *harfbuzz-loaded*))
    (%register-search-path "FREYA_HARFBUZZ_LIB_DIR")
    (cffi:use-foreign-library libharfbuzz)
    (setf *harfbuzz-loaded* t))
  *harfbuzz-loaded*)

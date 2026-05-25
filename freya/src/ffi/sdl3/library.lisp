;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — ffi.sdl3: foreign-library discovery + load for SDL3. SDL3 is used for
;;; windowing/input/IME/clipboard/HiDPI only — never for rendering. Point
;;; FREYA_SDL3_LIB_DIR at the directory holding the pinned SDL3 build.

(in-package #:net.goenninger.freya.ffi.sdl3)

(net.goenninger.freya.compat:optimize-safe)

(defparameter +pinned-version+ "3.2.0"
  "The minimum SDL3 release these bindings target.")

(declaim (ftype (function () t) %register-search-path)
         (ftype (function (&key (:force t)) t) load-libsdl3))

(defun %register-search-path ()
  (let ((dir (uiop:getenv "FREYA_SDL3_LIB_DIR")))
    (when (and dir (plusp (length dir)))
      (pushnew (uiop:ensure-directory-pathname dir)
               cffi:*foreign-library-directories*
               :test #'equal))))

(cffi:define-foreign-library libsdl3
  (:darwin (:or "libSDL3.dylib" "libSDL3.0.dylib"))
  (:unix (:or "libSDL3.so" "libSDL3.so.0"))
  (:windows (:or "SDL3.dll"))
  (t (:default "libSDL3")))

(defvar *loaded* nil)

(defun load-libsdl3 (&key force)
  "Load SDL3 (idempotent). Searches $FREYA_SDL3_LIB_DIR first."
  (when (or force (not *loaded*))
    (%register-search-path)
    (cffi:use-foreign-library libsdl3)
    (setf *loaded* t))
  *loaded*)

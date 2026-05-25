;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — ffi.wgpu: foreign-library discovery + load for wgpu-native.
;;;
;;; The native library is NEVER vendored or searched on world-writable paths
;;; (Sigyn ethos, PLAN §7): point FREYA_WGPU_LIB_DIR at the directory holding the
;;; pinned wgpu-native build. The raw bindings (generated from the pinned headers
;;; via c2ffi — see scripts/gen-bindings.sh) and the ergonomic wrapper land on top
;;; of this in Phase 0/1.

(in-package #:net.goenninger.freya.ffi.wgpu)

(net.goenninger.freya.compat:optimize-safe)

(defparameter +pinned-version+ "v25.0.2.1"
  "The wgpu-native release these bindings target. The generator pins the matching
headers; a runtime version check guards against ABI drift.")

(declaim (ftype (function () t) %register-search-path)
         (ftype (function (&key (:force t)) t) load-libwgpu))

(defun %register-search-path ()
  "Add $FREYA_WGPU_LIB_DIR to CFFI's foreign-library search path, if set."
  (let ((dir (uiop:getenv "FREYA_WGPU_LIB_DIR")))
    (when (and dir (plusp (length dir)))
      (pushnew (uiop:ensure-directory-pathname dir)
               cffi:*foreign-library-directories*
               :test #'equal))))

(cffi:define-foreign-library libwgpu-native
  (:darwin (:or "libwgpu_native.dylib"))
  (:unix (:or "libwgpu_native.so"))
  (:windows (:or "wgpu_native.dll"))
  (t (:default "libwgpu_native")))

(defvar *loaded* nil "True once the wgpu-native shared library is loaded.")

(defun load-libwgpu (&key force)
  "Load wgpu-native (idempotent). Searches $FREYA_WGPU_LIB_DIR first. Signals a
CFFI error if the library cannot be found."
  (when (or force (not *loaded*))
    (%register-search-path)
    (cffi:use-foreign-library libwgpu-native)
    (setf *loaded* t))
  *loaded*)

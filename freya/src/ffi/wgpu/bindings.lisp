;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — ffi.wgpu: hand-written minimal binding sample + the optional load of
;;; the c2ffi-generated full bindings (scripts/gen-bindings.sh).
;;;
;;; The sample exercises the FFI plumbing end-to-end once libwgpu_native is
;;; available via FREYA_WGPU_LIB_DIR — without requiring c2ffi to have been run.
;;; When generated-bindings.lisp is present (gitignored), it loads on top.

(in-package #:net.goenninger.freya.ffi.wgpu)

(net.goenninger.freya.compat:optimize-safe)

;;; --- Sample binding -------------------------------------------------------

(cffi:defcfun ("wgpuGetVersion" %wgpu-get-version) :uint32)

(declaim (ftype (function () (or null (unsigned-byte 32))) wgpu-get-version))
(defun wgpu-get-version ()
  "The wgpu-native library's compile-time version (packed 32-bit). NIL until
LOAD-LIBWGPU has been called successfully (the library is otherwise not mapped)."
  (when *loaded*
    (the (unsigned-byte 32) (%wgpu-get-version))))

;;; --- Optional generated bindings -----------------------------------------
;;; If scripts/gen-bindings.sh has been run, generated-bindings.lisp exists next
;;; to this file. Load it at LOAD time of the fasl, not at compile time.

(declaim (ftype (function () (or null pathname)) load-generated-bindings))
(defun load-generated-bindings ()
  "Load the c2ffi-generated raw bindings if present; return the path loaded
or NIL when none have been generated."
  (let* ((here (asdf:system-source-directory "net.goenninger.freya/ffi-wgpu"))
         (gen  (merge-pathnames "generated-bindings.lisp" here)))
    (when (probe-file gen)
      (load gen)
      gen)))

(eval-when (:load-toplevel :execute)
  (load-generated-bindings))

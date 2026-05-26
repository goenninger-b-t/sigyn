;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — ffi.sdl3: hand-written minimal binding sample + optional generated
;;; bindings (scripts/gen-bindings.sh). SDL3's SDL_GetVersion() returns the
;;; linked SDL version as a packed int, which is enough to verify the FFI
;;; plumbing once SDL3 is available via FREYA_SDL3_LIB_DIR.

(in-package #:net.goenninger.freya.ffi.sdl3)

(net.goenninger.freya.compat:optimize-safe)

(cffi:defcfun ("SDL_GetVersion" %sdl-get-version) :int)

(declaim (ftype (function () (or null integer)) sdl-get-version))
(defun sdl-get-version ()
  "The linked SDL3 version (packed int), or NIL until LOAD-LIBSDL3 has run."
  (when *loaded*
    (%sdl-get-version)))

(declaim (ftype (function () (or null pathname)) load-generated-bindings))
(defun load-generated-bindings ()
  (let* ((here (asdf:system-source-directory "net.goenninger.freya/ffi-sdl3"))
         (gen  (merge-pathnames "generated-bindings.lisp" here)))
    (when (probe-file gen)
      (load gen)
      gen)))

(eval-when (:load-toplevel :execute)
  (load-generated-bindings))

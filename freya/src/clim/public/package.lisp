;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — public CLIM packages with their spec-mandated names. The internal
;;; net.goenninger.freya.<module> packages export their symbols INTO `clim` (and
;;; the satellites) via this umbrella, so applications see one conformant CLIM.
;;; SKELETON: defines the packages only; symbol re-export is wired up per phase.

(in-package #:cl-user)

(defpackage #:clim-lisp
  (:use #:cl)
  (:documentation "CLIM-LISP: the Lisp substrate CLIM code is written in (CL + CLIM tweaks)."))

(defpackage #:clim-sys
  (:use #:cl)
  (:documentation "CLIM-SYS: portable concurrency, resources, and system utilities."))

(defpackage #:clim
  (:use #:cl)
  (:documentation "CLIM: the public Common Lisp Interface Manager 2 API surface."))

(defpackage #:clim-extensions
  (:use #:cl)
  (:nicknames #:clime)
  (:documentation "CLIM-EXTENSIONS: documented, non-spec extensions (scope: ADR-0005)."))

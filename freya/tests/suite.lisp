;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-
;;; Freya — top-level test suite. Portable across the supported Lisps (AllegroCL
;;; is the target; SBCL/CCL/ECL run in CI). No implementation-specific code here.

(in-package #:net.goenninger.freya.tests)

(fiveam:def-suite freya
  :description "All Freya tests (Phase 0: compat + telemetry foundations).")

(fiveam:in-suite freya)

;;; --- Packages -------------------------------------------------------------

(fiveam:test packages-present
  "The module packages defined by the skeleton exist."
  (dolist (name '("NET.GOENNINGER.FREYA.COMPAT"
                  "NET.GOENNINGER.FREYA.TELEMETRY"
                  "NET.GOENNINGER.FREYA.SCENE"
                  "NET.GOENNINGER.FREYA.RENDER"
                  "NET.GOENNINGER.FREYA.GEOMETRY"
                  "NET.GOENNINGER.FREYA.SILICA"
                  "NET.GOENNINGER.FREYA.BACKEND"
                  "CLIM"))
    (fiveam:is (find-package name)
               "Expected package ~A to exist." name)))

;;; --- compat: domain types -------------------------------------------------

(fiveam:test domain-types
  "The domain type vocabulary classifies values as intended."
  (fiveam:is-true  (typep 1.5d0 'net.goenninger.freya.compat:coordinate))
  (fiveam:is-false (typep 1.5f0 'net.goenninger.freya.compat:coordinate))
  (fiveam:is-true  (typep 255  'net.goenninger.freya.compat:octet))
  (fiveam:is-false (typep 256  'net.goenninger.freya.compat:octet))
  (fiveam:is-true  (typep 0    'net.goenninger.freya.compat:index))
  (fiveam:is-true  (typep #xFFFFFFFF 'net.goenninger.freya.compat:rgba8))
  (fiveam:is-true  (typep 0.5d0 'net.goenninger.freya.compat:unit-real))
  (fiveam:is-false (typep 1.5d0 'net.goenninger.freya.compat:unit-real)))

;;; --- compat: atomic counters ---------------------------------------------

(fiveam:test atomic-counter
  "Atomic counters increment, decrement and reset."
  (let ((c (net.goenninger.freya.compat:make-atomic-counter)))
    (fiveam:is (= 1 (net.goenninger.freya.compat:atomic-incf c)))
    (fiveam:is (= 6 (net.goenninger.freya.compat:atomic-incf c 5)))
    (fiveam:is (= 4 (net.goenninger.freya.compat:atomic-decf c 2)))
    (fiveam:is (= 4 (net.goenninger.freya.compat:atomic-counter-value c)))
    (net.goenninger.freya.compat:atomic-counter-reset c)
    (fiveam:is (= 0 (net.goenninger.freya.compat:atomic-counter-value c)))))

(fiveam:test atomic-counter-threadsafe
  "Concurrent increments don't lose updates."
  (let ((c (net.goenninger.freya.compat:make-atomic-counter))
        (threads '()))
    (dotimes (i 8)
      (push (net.goenninger.freya.compat:make-thread
             (lambda () (dotimes (k 10000)
                          (net.goenninger.freya.compat:atomic-incf c))))
            threads))
    (mapc #'net.goenninger.freya.compat:join-thread threads)
    (fiveam:is (= 80000 (net.goenninger.freya.compat:atomic-counter-value c)))))

;;; --- compat: locks & memory ----------------------------------------------

(fiveam:test lock-runs-body
  (let ((lock (net.goenninger.freya.compat:make-lock))
        (ran nil))
    (net.goenninger.freya.compat:with-lock-held (lock) (setf ran t))
    (fiveam:is-true ran)))

(fiveam:test weak-pointer-roundtrip
  (let* ((obj (cons 1 2))
         (wp (net.goenninger.freya.compat:make-weak-pointer obj)))
    (fiveam:is-true (net.goenninger.freya.compat:weak-pointer-p wp))
    (fiveam:is (eq obj (net.goenninger.freya.compat:weak-pointer-value wp)))))

(fiveam:test policy-releasep-is-boolean
  (fiveam:is-true (typep (net.goenninger.freya.compat:releasep) 'boolean)))

;;; --- telemetry ------------------------------------------------------------
;;; Default/release builds: :freya-telemetry is OFF, so the layer is inert —
;;; WITH-TIMER still runs its body, but instrumentation calls are no-ops.

#-freya-telemetry
(fiveam:test telemetry-disabled-is-zero-cost
  (fiveam:is-false (net.goenninger.freya.telemetry:telemetry-enabled-p))
  (fiveam:is (= 42 (net.goenninger.freya.telemetry:with-timer
                       (net.goenninger.freya.telemetry:*frame-build-seconds*)
                     42)))
  (fiveam:is-false (net.goenninger.freya.telemetry:counter-incf
                    net.goenninger.freya.telemetry:*frames-total*))
  (fiveam:is-false (net.goenninger.freya.telemetry:metrics-text)))

;;; Telemetry build: the layer records and exposes the canonical metric set.
#+freya-telemetry
(fiveam:test telemetry-enabled-records
  (fiveam:is-true (net.goenninger.freya.telemetry:telemetry-enabled-p))
  (fiveam:is (= 42 (net.goenninger.freya.telemetry:with-timer
                       (net.goenninger.freya.telemetry:*frame-build-seconds*)
                     42)))
  (net.goenninger.freya.telemetry:counter-incf
   net.goenninger.freya.telemetry:*frames-total* 2)
  (let ((txt (net.goenninger.freya.telemetry:metrics-text)))
    (fiveam:is-true (stringp txt))
    (fiveam:is-true (search "freya_frames_total" txt))))

(defun run-all ()
  "Run the full Freya test suite. Returns T on success, NIL otherwise."
  (fiveam:run! 'freya))

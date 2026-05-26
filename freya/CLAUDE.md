# CLAUDE.md — Freya project memory

Operational context for future Claude Code sessions in this project. The
authoritative docs live in `docs/`; this file is a fast on-ramp.

## Identity

- **Project:** Freya — a clean-room **CLIM 2** in Common Lisp with a
  **GPU-only WebGPU backend** (`wgpu-native` + SDL3). Unrelated to the
  surrounding Sigyn (SAP NetWeaver RFC) code.
- **Slug:** `freya`. Internal packages: `net.goenninger.freya.*`.
  Public CLIM packages keep their spec-mandated names
  (`clim`, `clim-lisp`, `clim-sys`, `clim-extensions`).
- **Currently lives under `freya/` of the `goenninger-b-t/sigyn` repo**,
  on branch `claude/clim2-gpu-backend-plan-IFPVz`, pending extraction to its
  own GitHub repo via `git subtree split` (see README).

## Lisp target (important)

- **AllegroCL is the deployment target** (ADR-0011).
- **SBCL is the open dev/CI reference**; CCL/ECL/LispWorks kept green.
- **No unconditional implementation specifics.** `#+sbcl`/`#+allegro`/… code is
  allowed **only inside `src/compat/`**, and every such branch has a portable
  path that AllegroCL takes. The portable algorithms (lock-based atomic
  counter, thread-based timer fallback) are correctness-tested.

## Build & test (everything verified on SBCL 2.2.9 in CI)

Two optimization profiles (PLAN §17, ADR-0009):
- `checked` (default): `(speed 1) (safety 3) (debug 2)` — full runtime + compile
  type checks; the suite runs here.
- `release` (`:freya-release` pushed): `(speed 3) (safety 0)` in hot modules.
  No runtime type-check cost; declarations are verified at compile time and
  exercised under safety 3 in the checked test run.

Built-in Prometheus telemetry (ADR-0010) is **off by default** and
**zero-cost when off** (macros compile to no-ops). Push `:freya-telemetry` to
turn it on; the `prometheus` system is a feature-gated `.asd` dependency.

```sh
make checked         # strict load + the §17 warning-as-error gate (checked)
make release         # strict load (release profile)
make test            # tests in checked
make release-test    # tests in release
make telemetry-test  # tests with :freya-telemetry on
```

Scripts are implementation-agnostic — run on AllegroCL with
`alisp -L scripts/build.lisp -- release strict` etc.

**Per-profile fasl isolation:** `scripts/build.lisp` and `scripts/test.lisp`
redirect ASDF output translations to `~/.cache/freya/<profile-tag>/` so
checked/release/telemetry caches never contaminate each other. (Don't remove
this — see the earlier debugging history.)

## Where things live

- `docs/PLAN.md` — architecture (the *what & why*).
- `docs/ROADMAP.md` — phases, exit gates, performance targets, CI matrix.
- `docs/DECISIONS.md` — every significant decision as an ADR.
- `net.goenninger.freya.asd` — one primary system + per-module secondary systems.
- `src/compat/` — per-Lisp shims + the optimize policy + the domain type
  vocabulary (`coordinate`, `rgba8`, `octet`, `index`, …). The only module with
  impl-conditionals.
- `src/telemetry/` — Prometheus instrumentation (feature-gated).
- `src/ffi/{wgpu,sdl3,text}/` — CFFI loaders (env-var lib discovery,
  pinned-version constants) + hand-written sample bindings + a load-on-top hook
  for c2ffi-generated raw bindings.
- `src/render/`, `src/platform/`, `src/clim/*`, `src/backend/`, `src/remote/` —
  module skeletons (mostly packages today; implementations land per ROADMAP).
- `extlibs/include/` — vendored pinned C headers (tracked). Native `.so/.dylib`
  binaries are never vendored — provide them via `FREYA_*_LIB_DIR`.
- `scripts/` — `build.lisp` · `test.lisp` · `vendor-headers.sh` · `gen-bindings.sh`.
- `tests/` — fiveam suite; portable across SBCL/AllegroCL/etc.

## Coding conventions (PLAN §17 / ADR-0009 — these are *normative*)

- **Every function** has an `ftype` declaration (next to the definition).
- **Every variable** has a `type` declaration: special/global via `declaim`,
  struct/class slots via `:type`, hot-code locals via `(declare (type …))`.
- **Domain types** (`coordinate`, `device-pixel`, `rgba8`, …) live in
  `net.goenninger.freya.compat`; use them in signatures rather than bare
  `fixnum`/`double-float`.
- **Hot files** start with `(net.goenninger.freya.compat:optimize-hot)`; the
  rest with `optimize-safe`. Inline hot inner-loop functions with
  `(declaim (inline …))`. Cold/large functions are **not** inlined.
- **CI gate:** `scripts/build.lisp strict` recompiles only Freya's systems and
  treats non-style WARNINGs as fatal. Both profiles must pass.
- **No new SBCL specifics outside `src/compat/`.** Even inside compat, every
  `#+sbcl` branch needs a portable path (AllegroCL takes that path).

## Telemetry conventions

- Define metrics with `define-counter`/`define-gauge`/`define-histogram` (all
  compile to placeholder `defvar … nil` when telemetry is off).
- Instrument with `with-timer (METRIC) …`, `counter-incf`, `gauge-set`, `observe`.
- `*registry*` is a **defparameter** (so reloading the file makes a fresh
  registry — that's intentional, don't change to defvar).
- Canonical metrics already wired: `*frame-build-seconds*`,
  `*present-latency-seconds*`, `*frames-total*`, `*frames-dropped-total*`.

## Current status (as of this commit)

**Done & verified on SBCL — strict checked & release builds warning-clean,
40/40 tests pass in checked / release / telemetry profiles:**

- ✅ `compat` v0 (policy, types, concurrency, memory, scheduling).
- ✅ telemetry skeleton (off-path verified zero-cost; on-path verified records
  + exposes text format).
- ✅ FFI library loaders + version pinning for wgpu/SDL3/text.
- ✅ Binding pipeline: vendored `webgpu.h` + `wgpu.h` at `v25.0.2.1` under
  `extlibs/include/wgpu/`; `scripts/vendor-headers.sh` refreshes them;
  `scripts/gen-bindings.sh` drives c2ffi when present; hand-written
  `wgpuGetVersion` + `SDL_GetVersion` `defcfun` samples exercise the FFI today.
- ✅ Build profiles + strict gate + CI workflow (activates on repo extraction).

**Remaining in Phase 0 (needs a workstation with a GPU + native libs):**

- ⏳ Full c2ffi generation (upstream c2ffi tip doesn't build against LLVM 18;
  use clang/llvm 14-16 — message recorded in `gen-bindings.sh`).
- ⏳ SDL3 + wgpu-native bring-up: device/queue, surface creation, the
  cross-platform **triangle**.
- ⏳ Display-server / main-thread loop with the cross-thread request queue.
- ⏳ Full block compilation + the stricter "zero optimization notes in hot
  modules" gate (today's gate is zero non-style warnings).
- ⏳ Headless golden-image harness on a software GPU.

## Gotchas / institutional knowledge

- **Don't remove per-profile fasl isolation in the scripts.** ASDF's fasl cache
  does not key on `*features*`; without isolation, profile-A fasls get loaded
  in profile-B and break correctness (e.g. release loading a telemetry-built
  fasl when `prometheus` isn't present).
- **`make-histogram` in `prometheus` requires `:buckets`** — there's no default.
  Use `+default-latency-buckets+` (sub-second tuned) or pass explicit buckets.
- **`sb-ext:timer-p` is not exported.** Use `(typep x 'sb-ext:timer)`. Generally
  in the SBCL fast path, prefer `typep` over predicates of uncertain export.
- **AllegroCL atomics:** the lock-based `#-sbcl` path is the correctness baseline.
  An AllegroCL `excl` atomic fast path is a possible later optimization — only
  add one after verifying the API on Allegro itself.
- **License is MIT** (ADR-0008). `LICENSE` notes third-party deps with their own
  terms (notably FreeType's FTL attribution).

## When asked to keep working

Default to **continuing Phase 0** in this order:
1. Ergonomic-wrapper skeleton for wgpu (struct builders, with-* RAII, error →
   condition mapping) — software-only, mostly verifiable here.
2. Display-server / main-thread loop skeleton (no GPU bring-up; cross-thread
   request queue + event pump shape).
3. Native bring-up & the triangle — **needs a workstation with a GPU**; ask
   before assuming hardware is available.

Always run `make checked && make test && make release-test && make telemetry-test`
before committing. Strict gate must stay green.

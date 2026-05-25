# Freya — Architecture Decision Records

A living log of significant decisions. Each ADR is short: context, the decision,
and consequences. Status ∈ {Accepted, Open, Superseded}.

| ADR | Topic | Status |
|---|---|---|
| [0001](#adr-0001--foundational-direction) | Foundational direction | Accepted |
| [0002](#adr-0002--project-name--package-root) | Project name & package root | Accepted |
| [0003](#adr-0003--font-dependency-posture) | Font dependency posture | Accepted |
| [0004](#adr-0004--tier-2-renderer-build-vs-borrow) | Tier-2 renderer: build vs. borrow | Accepted |
| [0005](#adr-0005--clim-extensions-scope-for-v1) | CLIM-EXTENSIONS scope for v1 | Accepted |
| [0006](#adr-0006--v1-conformance-bar-the-clim-core-profile) | v1 conformance bar | Accepted |
| [0007](#adr-0007--headlessremote-rendering) | Headless/remote rendering | Accepted |
| [0008](#adr-0008--project-license) | Project license | Accepted |
| [0009](#adr-0009--type-safety--performance-discipline) | Type-safety & performance discipline | Accepted |
| [0010](#adr-0010--built-in-prometheus-telemetry) | Built-in Prometheus telemetry | Accepted |

---

## ADR-0001 — Foundational direction
**Status:** Accepted.

**Context.** Building a full CLIM 2 with a GPU-only backend admits several
high-level strategies that reshape the whole effort.

**Decision.**
- **CLIM strategy:** clean-room, **spec-guided**. The CLIM II specification is
  normative; McCLIM is used only as a *behavioral oracle* (run the same program
  and compare), never copied.
- **Lisp targets:** **broad portability** (SBCL, CCL, ECL, LispWorks, …), with
  **SBCL as the performance reference**. Per-Lisp differences are isolated in
  `…/compat`.
- **Platforms:** **cross-platform from day one** — Linux (X11+Wayland), macOS
  (Metal), Windows (D3D12/Vulkan).
- **Runtime stack:** **SDL3** (windowing/input/IME/clipboard/HiDPI) **+
  wgpu-native** (WebGPU C ABI), both via CFFI.

**Consequences.** Maximum ambition combination; mitigated by developing each
phase SBCL-on-Linux first, then fanning out via CI at phase gates. See
`PLAN.md` §3 and `ROADMAP.md`.

---

## ADR-0002 — Project name & package root
**Status:** Accepted.

**Context.** The name gates directory, ASDF system, and package naming.

**Decision.** The project is **Freya** (slug `freya`). Internal packages and
ASDF systems use the **reverse-DNS root `net.goenninger.freya`** (one primary
system + `net.goenninger.freya/<module>` secondaries). The public CLIM packages
keep their spec-mandated names (`clim`, `clim-lisp`, `clim-sys`,
`clim-extensions`).

**Consequences.** Collision-proof, matches the house style; apps see a
spec-conformant `clim` package. Codename references in the docs were renamed
accordingly.

---

## ADR-0003 — Font dependency posture
**Status:** Accepted.

**Context.** Text quality vs. dependency footprint. Options: (a) FreeType +
HarfBuzz via CFFI as default — best coverage, hinting, shaping, color emoji;
(b) pure-CL default (`zpb-ttf` + `cl-vectors`) — zero C font deps, weaker
shaping/coverage; (c) both, with one as default.

**Decision.** Default to **FreeType (rasterization/hinting/metrics) + HarfBuzz
(shaping/kerning/complex scripts)** via CFFI, behind a `font-engine` protocol. A
**pure-CL fallback** (`zpb-ttf` + `cl-vectors`) is kept available for no-C-deps
builds. Consistent with already depending on SDL3 + wgpu-native (C libs).

**Consequences.** `…/render` depends on `…/ffi-text` for glyph rasterization;
the pure-CL path is an optional, swappable engine. Native FreeType/HarfBuzz libs
are discovered via env vars (`FREYA_*_LIB_DIR`), never vendored. FreeType's FTL
attribution clause is noted in `LICENSE`. Matches ROADMAP Phase 2.

---

## ADR-0004 — Tier-2 renderer: build vs. borrow
**Status:** Accepted.

**Context.** The high-performance renderer (compute-coverage rasterizer) is the
biggest technical risk. Options: (a) build from scratch in CL+WGSL; (b) borrow an
existing Rust engine (Vello/Lyon) via a C ABI; (c) defer the choice to the
Phase-10 gate. The Scene API makes any of these a localized swap.

**Decision.** **Build Tier-2 from scratch** — a fully-native CL + WGSL
compute-coverage rasterizer. No Rust/C rasterizer ships in the product. Binding
Vello/Lyon-via-C is retained **only as an emergency contingency** behind the
Scene API if the from-scratch effort stalls against perf/quality targets. Tier-1
(tessellation + MSAA) remains the correctness oracle throughout.

**Consequences.** Highest effort/risk, but maximal "100% native CL rendering."
ROADMAP Phase 10 is now a committed build (not a decision gate); PLAN §5.3
updated.

---

## ADR-0005 — CLIM-EXTENSIONS scope for v1
**Status:** Accepted.

**Context.** Beyond the spec, real CLIM apps rely on de-facto extensions.

**Decision.** v1 includes a **broad** extension set, in three groups:
- **Renderer-native** (nearly free from the GPU engine): raster images /
  `draw-image` / image inks, linear & radial **gradient** inks, and
  **bezier/arbitrary paths**.
- **Interaction:** **drag-and-drop** presentation translators and a
  **tab-layout** pane.
- **clim-sys + clime niceties:** concurrency/resource helpers and stream/pane
  quality-of-life (e.g. pointer-documentation conveniences).

**Consequences.** The `clim-extensions` (`clime`) package is a first-class v1
surface. Folded into ROADMAP Phases 1/3 (renderer-native), 6 (drag-and-drop),
7 (tab-layout), and across clim-sys.

---

## ADR-0006 — v1 conformance bar (the "CLIM core profile")
**Status:** Accepted.

**Context.** Full CLIM 2 is enormous; we needed a precise definition of "done"
for v1.

**Decision.** v1's bar is **full CLIM 2 conformance** — ROADMAP Phases 0–11,
including formatting and incremental redisplay, plus the ADR-0005 extension set.
The "CLIM core profile" (Phase-7 gate) is retained as an **intermediate
milestone** that de-risks the program, not the release bar.

**Consequences.** Largest-scope target (~60–180 EM); ROADMAP estimates and the
scope-risk mitigation updated to frame core-profile as a checkpoint.

---

## ADR-0007 — Headless/remote rendering
**Status:** Accepted.

**Context.** The display-server model makes offscreen rendering nearly free, and
golden-image CI needs it anyway. Question: how early is headless — and remote
streaming — a first-class target?

**Decision.** **Both early, first-class.** Headless offscreen render targets are
a **Phase-1 deliverable** (and CI renders golden images headless). A
**remote/streaming transport** (frame encode/diff out, input events in) is a
dedicated **parallel track from Phase 4** in a new `…/remote` module.

**Consequences.** Adds the `…/remote` ASDF system + package and ROADMAP
"Phase R"; adds a cross-cutting "Headless & remote" concern and a scope-creep
risk row. The wire protocol is versioned and security-hardened (Sigyn ethos).

---

## ADR-0008 — Project license
**Status:** Accepted.

**Context.** The repo initially shipped a provisional proprietary `LICENSE`. A
reusable CLIM framework benefits from a permissive license. Runtime deps carry
their own licenses (wgpu-native MIT/Apache-2.0; SDL3 zlib; FreeType FTL/GPL;
HarfBuzz MIT) — none force the choice.

**Decision.** **MIT.** Maximally permissive, simplest for adoption as a
framework.

**Consequences.** `LICENSE` replaced with the MIT text (© Gönninger B&T UG and
the Freya contributors) plus a third-party-components note (FreeType's FTL
attribution clause called out). README updated.

---

## ADR-0009 — Type-safety & performance discipline
**Status:** Accepted.

**Context.** Requirement: all variables and all functions must carry type
declarations; hot-path functions must be inlined; type checks must happen at
compile time with **no runtime penalty**. These reinforce the high-performance
goal and catch errors before they reach the GPU/FFI boundary.

**Decision.**
- **Declarations everywhere.** Every function has an `ftype`; every variable
  (special/global, struct/class slot, and hot-code local) has a `type`; domain
  types are named via `deftype` and used in signatures. Boundaries validate once
  with `the`/`check-type`.
- **Inlining.** A curated `:freya-hot` set is `(declaim (inline …))` + the hot
  modules are **block-compiled** so types and inline bodies propagate; cold/large
  functions are not inlined; `dynamic-extent` + per-frame arenas keep the hot
  path allocation-free.
- **Two optimize profiles.** *Checked* (`safety 3`) runs all compile-time **and**
  runtime checks — tests run here. *Release* (`speed 3 / safety 0` in hot
  modules) makes the compiler trust the already-verified declarations, emitting
  **no runtime type checks**. Compile-time verification + the checked test run
  are what make `safety 0` sound.
- **CI gate.** Release build must compile with zero type warnings and zero
  optimization notes in `:freya-hot` modules; checked build must pass the suite;
  both profiles run in CI. A lint asserts each definition has declarations.

**Consequences.** Applies to all modules; SBCL is the type-derivation reference.
The shared optimize policy + declaration helpers live in `…/compat`. PLAN §17
specifies it; ROADMAP Phase 0 stands up the profiles, block compilation, and the
CI gate. Cost: more declaration ceremony and discipline in reviews.

---

## ADR-0010 — Built-in Prometheus telemetry
**Status:** Accepted.

**Context.** Requirement: Prometheus instrumentation must be built in — not a
later add-on — so frame timing, GPU/atlas/event/FFI/GC behavior is observable in
development and production, including headless/remote servers (ADR-0007).

**Decision.** Add a `…/telemetry` module wrapping the CL `prometheus` client: a
registry, a **canonical engine metric set** (frame/render/submit/present timings,
fps, dropped frames, scene-encode time, draw-call/instance counts, atlas
hit/miss/evict, GPU memory, event-queue depth, input→present latency, command
latency, incremental-redisplay patch size/time, FFI call counts/time, GC/process
stats), and macros (`with-timer`, `observe`, `counter-incf`, `gauge-set`).
- **Zero-cost when disabled:** without the `:freya-telemetry` feature the macros
  expand to nothing. When enabled, counters are fixnum atomics and histograms are
  preallocated, so the hot path is lock-free/allocation-free and obeys ADR-0009.
- **Pluggable exposers:** optional embedded HTTP scrape (off by default),
  pushgateway, or file/socket sink — chosen by the host; a GUI toolkit must not
  force a web server.

**Consequences.** Adds the `…/telemetry` ASDF system (+ `prometheus` deps);
`…/render`, `…/platform`, `…/backend`, `…/frames` carry instrumentation points;
the primary system depends on telemetry so it is built in; headless/remote
servers expose `/metrics`. ROADMAP Phase 0 adds the exporter skeleton; later
phases populate metrics as subsystems land.

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

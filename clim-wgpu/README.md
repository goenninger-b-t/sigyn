# Bifröst — a clean-room CLIM 2 with a GPU-only (WGPU) backend

> **Codename `bifrost`** (placeholder — rename at will).
> **Status: planning only.** No implementation yet. This directory currently
> holds design/brainstorm documents.

## What this is

A plan for a **full, high-performance, native Common Lisp implementation of the
CLIM 2 specification** whose **only** rendering/interaction backend is the GPU,
via **WebGPU** (the `wgpu-native` C ABI) with **SDL3** for windowing and input.

The goal is a CLIM that draws every pixel itself on the GPU — no X11 drawing
primitives, no native OS widgets, no CPU software rasterizer in the hot path —
while remaining a faithful, conformant CLIM 2 (so existing CLIM programs run).

## Relationship to Sigyn

**None.** This is an independent project that merely *incubates on this branch*
of the `sigyn` repository for convenience. It does not depend on, extend, or
relate to Sigyn's SAP NetWeaver RFC functionality. It only borrows Sigyn's
*house conventions* where helpful (ASDF-per-module layout, reverse-DNS package
names, security-conscious CFFI library loading).

## Locked design decisions

| Decision | Choice |
|---|---|
| CLIM layer strategy | **Clean-room, spec-guided** (CLIM II spec is the contract; McCLIM is a behavioral oracle only) |
| Common Lisp targets | **Broad portability** (SBCL, CCL, ECL, LispWorks, …; SBCL is the performance reference) |
| Platforms | **Cross-platform from day one** (Linux X11+Wayland, macOS Metal, Windows D3D12/Vulkan) |
| Runtime stack | **SDL3** (windowing/input/IME/clipboard/HiDPI) **+ wgpu-native** (WebGPU C ABI) |

## Documents

- [`docs/PLAN.md`](docs/PLAN.md) — the brainstorm + full architecture and subsystem design.
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — phased execution plan, milestones, risks, testing, and performance targets.

## A word on scope

A complete CLIM 2 is one of the largest GUI specifications ever written, and a
GPU-only backend means building a small 2D vector+text rendering engine (think a
minimal Skia/Vello) underneath it. This is a multi-person, multi-year effort.
The roadmap is therefore organized so that a **usable "CLIM core profile" demo**
arrives early and the surface area grows in conformance-driven phases.

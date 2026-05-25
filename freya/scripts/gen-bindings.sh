#!/usr/bin/env bash
# Freya — regenerate the raw CFFI bindings for wgpu-native and SDL3 from PINNED
# headers using c2ffi (PLAN §7). Placeholder for Phase 0: wire this up once the
# pinned headers are vendored under extlibs/include/.
#
# The generated files (src/ffi/**/generated-*.lisp) are .gitignored and produced
# reproducibly here; only the ergonomic wrappers and library loaders are tracked.
#
# Prerequisites: c2ffi on PATH, and the pinned headers available.
#
# Pins (keep in sync with the +pinned-version+ constants in the loaders):
#   wgpu-native : v25.0.2.1   (webgpu.h + wgpu.h)
#   SDL3        : 3.2.0
set -euo pipefail

echo "TODO(Phase 0): generate raw bindings with c2ffi from pinned headers."
echo "  - vendor headers under extlibs/include/{wgpu,sdl3}/ (pinned versions)"
echo "  - c2ffi <header> -o src/ffi/<lib>/generated-spec.json"
echo "  - convert spec -> src/ffi/<lib>/generated-bindings.lisp"
echo "  - run the ergonomic-wrapper smoke test"
exit 0

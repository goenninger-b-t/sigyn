#!/usr/bin/env bash
# Freya — download the pinned upstream C headers under extlibs/include/.
# Idempotent: skips downloads that already match.
#
# Update the version variables here AND the matching +pinned-version+ constants
# in src/ffi/<lib>/library.lisp when bumping a pin (PLAN §7).
set -euo pipefail

WGPU_NATIVE_VERSION="v25.0.2.1"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INCLUDE="${ROOT}/extlibs/include"

vendor_wgpu() {
    local dest="${INCLUDE}/wgpu"
    local url="https://github.com/gfx-rs/wgpu-native/releases/download/${WGPU_NATIVE_VERSION}/wgpu-linux-x86_64-release.zip"
    mkdir -p "${dest}"
    local tmp
    tmp="$(mktemp -d)"
    echo "==> Fetching wgpu-native ${WGPU_NATIVE_VERSION} headers"
    curl -fsSL -o "${tmp}/wgpu.zip" "${url}"
    unzip -j -o "${tmp}/wgpu.zip" 'include/webgpu/*.h' -d "${dest}" >/dev/null
    rm -rf "${tmp}"
    echo "    -> $(ls "${dest}" | tr '\n' ' ')"
}

vendor_wgpu

cat <<EOF

Headers vendored under: ${INCLUDE}
Next: install a c2ffi compatible with your system clang/llvm, then run
      scripts/gen-bindings.sh
EOF

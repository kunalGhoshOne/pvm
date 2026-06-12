#!/usr/bin/env bash
# Build every supported PHP version for every architecture.
# Runs builds sequentially to avoid overwhelming the host machine.
# Pass a specific minor version as $1 to build only that version.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/versions.sh"

# Detect native arch; cross-arch PHP builds require QEMU — skip silently if unsupported
NATIVE_ARCH="$(uname -m)"
[[ "$NATIVE_ARCH" == "x86_64" ]] && NATIVE_ARCH="amd64"
[[ "$NATIVE_ARCH" == "aarch64" ]] && NATIVE_ARCH="arm64"

ARCHS=("amd64" "arm64")
TARGET_MINOR="${1:-all}"

for MINOR in $(echo "${!PHP_VERSIONS[@]}" | tr ' ' '\n' | sort); do
    if [[ "$TARGET_MINOR" != "all" && "$MINOR" != "$TARGET_MINOR" ]]; then
        continue
    fi
    for ARCH in "${ARCHS[@]}"; do
        if [[ "$ARCH" != "$NATIVE_ARCH" ]] && ! docker buildx version &>/dev/null; then
            echo "⚠ Skipping ${ARCH} — cross-arch requires Docker buildx + QEMU (CI will handle it)"
            continue
        fi
        echo "══════════════════════════════════════"
        echo " PHP ${MINOR}  •  ${ARCH}"
        echo "══════════════════════════════════════"
        "${SCRIPT_DIR}/build.sh" "$MINOR" "$ARCH"
    done
done

echo ""
echo "All builds complete. Artifacts in server/dist/"

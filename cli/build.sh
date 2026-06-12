#!/usr/bin/env bash
# Build the pvm CLI binary using Docker (no buildx required).
#
# Usage: ./build.sh [arch]
#   arch  amd64 (default) | arm64

set -euo pipefail

ARCH="${1:-amd64}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/../dist"
IMAGE="pvm-cli-builder-${ARCH}"

mkdir -p "$OUT_DIR"

echo "▶ Building pvm CLI for linux/${ARCH}"

docker build \
    --target builder \
    --build-arg "TARGETARCH=${ARCH}" \
    -t "${IMAGE}" \
    "${SCRIPT_DIR}/"

docker run --rm "${IMAGE}" cat /out/pvm > "${OUT_DIR}/pvm-linux-${ARCH}"
chmod +x "${OUT_DIR}/pvm-linux-${ARCH}"

echo "✓ Created: ${OUT_DIR}/pvm-linux-${ARCH}"

#!/usr/bin/env bash
# Build a single PHP version for a single architecture and output a tar.gz.
#
# Usage: ./build.sh <minor_version> <arch>
#   minor_version  e.g. 8.3
#   arch           amd64 | arm64

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${SCRIPT_DIR}/versions.sh"

MINOR="${1:?Usage: build.sh <minor_version> <arch>}"
ARCH="${2:?Usage: build.sh <minor_version> <arch>}"
FULL="${PHP_VERSIONS[$MINOR]:?Unknown PHP version: $MINOR}"

DOCKERFILE="${SCRIPT_DIR}/../dockerfiles/Dockerfile"
DIST_DIR="${REPO_ROOT}/server/dist"
OUTPUT="${DIST_DIR}/php-${FULL}-linux-${ARCH}.tar.gz"

mkdir -p "$DIST_DIR"

IMAGE="pvm-php-builder-${MINOR}-${ARCH}"

echo "▶ Building PHP ${FULL} for linux/${ARCH}"

docker build \
    --target builder \
    --build-arg "PHP_FULL_VERSION=${FULL}" \
    --build-arg "PHP_MINOR_VERSION=${MINOR}" \
    -t "${IMAGE}" \
    -f "${DOCKERFILE}" \
    "${REPO_ROOT}/server"

# Extract /pvm from the container, renaming it to php/ so the CLI
# can strip that prefix on extraction.
docker run --rm "${IMAGE}" \
    tar -C / --transform 's|^pvm|php|' -czf - pvm > "${OUTPUT}"

echo "✓ Created: ${OUTPUT}"

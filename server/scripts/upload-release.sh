#!/usr/bin/env bash
# Upload built tarballs to GitHub Releases.
# Requires: gh CLI authenticated, GITHUB_REPO set.
#
# Usage: ./upload-release.sh <minor_version>
#   e.g. ./upload-release.sh 8.3

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${SCRIPT_DIR}/versions.sh"

MINOR="${1:?Usage: upload-release.sh <minor_version>}"
FULL="${PHP_VERSIONS[$MINOR]:?Unknown PHP version: $MINOR}"
TAG="php-${MINOR}"
DIST_DIR="${REPO_ROOT}/server/dist"

echo "▶ Uploading PHP ${FULL} builds to release tag ${TAG}"

# Create or update the release
gh release create "${TAG}" \
    --title "PHP ${MINOR}" \
    --notes "PHP ${MINOR} (${FULL}) — linux/amd64 and linux/arm64" \
    --repo "${GITHUB_REPO:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}" \
    2>/dev/null || true

for ARCH in amd64 arm64; do
    FILE="${DIST_DIR}/php-${FULL}-linux-${ARCH}.tar.gz"
    if [[ ! -f "$FILE" ]]; then
        echo "✗ Missing: ${FILE} — run build.sh first"
        continue
    fi
    echo "  → Uploading ${FILE##*/}"
    gh release upload "${TAG}" "${FILE}" --clobber \
        --repo "${GITHUB_REPO:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
done

echo "✓ Upload complete"

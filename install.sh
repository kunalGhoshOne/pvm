#!/usr/bin/env bash
set -euo pipefail

REPO="kunalGhoshOne/pvm"
INSTALL_DIR="/usr/local/bin"
BINARY="pvm"

# ── Detect architecture ────────────────────────────────────────────────────────
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64)  ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    *)
        echo "Error: unsupported architecture: $ARCH"
        exit 1
        ;;
esac

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
if [[ "$OS" != "linux" ]]; then
    echo "Error: pvm only supports Linux (detected: $OS)"
    exit 1
fi

ASSET="pvm-linux-${ARCH}"
URL="https://github.com/${REPO}/releases/latest/download/${ASSET}"

# ── Download ───────────────────────────────────────────────────────────────────
echo "Detected: linux/${ARCH}"
echo "Downloading pvm from ${URL} ..."

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

if command -v curl &>/dev/null; then
    curl -fsSL "$URL" -o "$TMP"
elif command -v wget &>/dev/null; then
    wget -qO "$TMP" "$URL"
else
    echo "Error: curl or wget is required"
    exit 1
fi

chmod +x "$TMP"

# ── Install ────────────────────────────────────────────────────────────────────
if [[ -w "$INSTALL_DIR" ]]; then
    mv "$TMP" "${INSTALL_DIR}/${BINARY}"
else
    echo "Installing to ${INSTALL_DIR} (requires sudo)..."
    sudo mv "$TMP" "${INSTALL_DIR}/${BINARY}"
fi

# ── Verify ─────────────────────────────────────────────────────────────────────
echo ""
echo "pvm installed to ${INSTALL_DIR}/${BINARY}"
echo ""
echo "Next steps:"
echo "  1. Run: pvm init"
echo "  2. Add the printed line to your ~/.bashrc or ~/.zshrc"
echo "  3. Restart your shell, then: pvm install 8.3"

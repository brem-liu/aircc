#!/bin/bash
# AirCC Agent - User Installation Script
# Usage: curl -fsSL https://raw.githubusercontent.com/brem-liu/aircc/main/install.sh | sh

set -e

BASE_URL="${AIRCC_BASE_URL:-https://github.com/brem-liu/aircc/releases/latest/download}"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="aircc"

# Clean up temp files on exit
TMP_FILE="/tmp/${BINARY_NAME}-$$"
TMP_CHECKSUMS="/tmp/aircc-checksums-$$"
cleanup() { rm -f "$TMP_FILE" "$TMP_CHECKSUMS"; }
trap cleanup EXIT

echo ""
echo "╭────────────────────────────────────╮"
echo "│  AirCC Agent Installation          │"
echo "╰────────────────────────────────────╯"
echo ""

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

echo "Detected: ${OS}/${ARCH}"

# Download binary
BINARY_URL="${BASE_URL}/${BINARY_NAME}-${OS}-${ARCH}"

echo "Downloading from $BINARY_URL"

# Download to temp location
if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$BINARY_URL" -o "$TMP_FILE"
elif command -v wget >/dev/null 2>&1; then
    wget -q "$BINARY_URL" -O "$TMP_FILE"
else
    echo "Error: curl or wget required"
    exit 1
fi

# Verify checksum
echo "Verifying checksum..."
CHECKSUM_URL="${BASE_URL}/checksums.sha256"

CHECKSUM_OK=false
if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$CHECKSUM_URL" -o "$TMP_CHECKSUMS" 2>/dev/null || true
elif command -v wget >/dev/null 2>&1; then
    wget -q "$CHECKSUM_URL" -O "$TMP_CHECKSUMS" 2>/dev/null || true
fi

if [ -f "$TMP_CHECKSUMS" ] && [ -s "$TMP_CHECKSUMS" ]; then
    EXPECTED=$(grep "${BINARY_NAME}-${OS}-${ARCH}" "$TMP_CHECKSUMS" | awk '{print $1}')
    if [ -n "$EXPECTED" ]; then
        if command -v sha256sum >/dev/null 2>&1; then
            ACTUAL=$(sha256sum "$TMP_FILE" | awk '{print $1}')
        elif command -v shasum >/dev/null 2>&1; then
            ACTUAL=$(shasum -a 256 "$TMP_FILE" | awk '{print $1}')
        else
            echo "  Warning: No sha256sum or shasum available, skipping verification"
            CHECKSUM_OK=true
        fi

        if [ "$CHECKSUM_OK" != "true" ]; then
            if [ "$EXPECTED" = "$ACTUAL" ]; then
                echo "  Checksum verified"
                CHECKSUM_OK=true
            else
                echo "  Error: Checksum verification failed!"
                echo "  Expected: $EXPECTED"
                echo "  Actual:   $ACTUAL"
                exit 1
            fi
        fi
    else
        echo "  Warning: No checksum entry for ${BINARY_NAME}-${OS}-${ARCH}"
    fi
else
    echo "  Warning: Could not download checksums, skipping verification"
fi

# Install binary
echo "Installing to $INSTALL_DIR/$BINARY_NAME"
if [ -w "$INSTALL_DIR" ]; then
    mv "$TMP_FILE" "$INSTALL_DIR/$BINARY_NAME"
    chmod +x "$INSTALL_DIR/$BINARY_NAME"
else
    sudo mv "$TMP_FILE" "$INSTALL_DIR/$BINARY_NAME"
    sudo chmod +x "$INSTALL_DIR/$BINARY_NAME"
fi

echo "Binary installed"
echo ""
echo "Installation complete!"
echo ""
echo "Get your device key from the App/Web, then run:"
echo "  aircc start -k YOUR_KEY        # foreground"
echo "  aircc start -k YOUR_KEY -d     # background daemon"

echo ""

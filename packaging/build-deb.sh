#!/usr/bin/env bash
set -e

# Usage: ./packaging/build-deb.sh <binary_path> <version> <arch: amd64|arm64> [output_dir]

BINARY_PATH="${1:-bin/ipchat}"
VERSION="${2:-0.1.0}"
ARCH="${3:-amd64}"
OUTPUT_DIR="${4:-.}"

if [ ! -f "$BINARY_PATH" ]; then
    echo "Error: Binary not found at $BINARY_PATH"
    exit 1
fi

BUILD_DIR=$(mktemp -d /tmp/ipchat-deb-XXXXXX)
trap 'rm -rf "$BUILD_DIR"' EXIT

mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/bin"

# Copy binary
cp "$BINARY_PATH" "$BUILD_DIR/usr/bin/ipchat"
chmod 755 "$BUILD_DIR/usr/bin/ipchat"

# Generate control file
cat <<EOF > "$BUILD_DIR/DEBIAN/control"
Package: ipchat
Version: $VERSION
Section: net
Priority: optional
Architecture: $ARCH
Maintainer: Mahamudul-Dev <https://github.com/Mahamudul-Dev>
Description: Secure, anonymous, zero-knowledge terminal E2EE group chat over UDP.
 IPChat allows private, peer-like group chats in the terminal using AES-256-GCM
 and a zero-knowledge UDP relay. Traffic operates over port 443 to blend with QUIC/HTTP3.
EOF

mkdir -p "$OUTPUT_DIR"
DEB_NAME="ipchat_${VERSION}_${ARCH}.deb"
dpkg-deb --build --root-owner-group "$BUILD_DIR" "$OUTPUT_DIR/$DEB_NAME"

echo "Successfully built Debian package: $OUTPUT_DIR/$DEB_NAME"

#!/usr/bin/env bash
set -e

# IPChat Universal Installer for Linux & macOS
# Usage: curl -fsSL https://raw.githubusercontent.com/Mahamudul-Dev/ipchat/main/install.sh | bash

REPO="Mahamudul-Dev/ipchat"
BINARY_NAME="ipchat"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

printf "${BLUE}${BOLD}"
cat << 'EOF'
    ____  ____  ________          __ 
   /  _/ / __ \/ ____/ /_  ____ _/ /_
   / /  / /_/ / /   / __ \/ __ `/ __/
 _/ /  / ____/ /___/ / / / /_/ / /_  
/___/ /_/    \____/_/ /_/\__,_/\__/  
EOF
printf "${NC}\n"
printf "${BLUE}Installing IPChat - Secure Terminal E2EE Chat...${NC}\n\n"

# 1. Detect Operating System
OS="$(uname -s)"
case "$OS" in
    Linux)
        OS_TARGET="linux"
        ;;
    Darwin)
        OS_TARGET="macos"
        ;;
    *)
        printf "${RED}✖ Unsupported Operating System: %s${NC}\n" "$OS"
        printf "For Windows, please download the .zip release manually from:\n"
        printf "https://github.com/%s/releases\n" "$REPO"
        exit 1
        ;;
esac

# 2. Detect CPU Architecture
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64|amd64)
        ARCH_TARGET="x64"
        ;;
    aarch64|arm64)
        ARCH_TARGET="arm64"
        ;;
    *)
        printf "${RED}✖ Unsupported CPU Architecture: %s${NC}\n" "$ARCH"
        exit 1
        ;;
esac

ASSET_NAME="ipchat-${OS_TARGET}-${ARCH_TARGET}.tar.gz"
DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/${ASSET_NAME}"

# Fallback for linux-arm64 if x64 is available
if [ "$OS_TARGET" = "linux" ] && [ "$ARCH_TARGET" = "arm64" ]; then
    # Default to linux-x64 if specific arm64 build is not published yet
    ASSET_NAME="ipchat-linux-x64.tar.gz"
    DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/${ASSET_NAME}"
fi

printf "Detected: ${BOLD}%s (%s)${NC}\n" "$OS_TARGET" "$ARCH_TARGET"
printf "Downloading: ${BLUE}%s${NC}...\n\n" "$DOWNLOAD_URL"

TMP_DIR="$(mktemp -d /tmp/ipchat-install-XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

# 3. Download the Release Archive
if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$DOWNLOAD_URL" -o "$TMP_DIR/$ASSET_NAME" || {
        printf "${RED}✖ Failed to download %s${NC}\n" "$DOWNLOAD_URL"
        printf "Make sure a release exists at https://github.com/%s/releases\n" "$REPO"
        exit 1
    }
elif command -v wget >/dev/null 2>&1; then
    wget -qO "$TMP_DIR/$ASSET_NAME" "$DOWNLOAD_URL" || {
        printf "${RED}✖ Failed to download %s${NC}\n" "$DOWNLOAD_URL"
        exit 1
    }
else
    printf "${RED}✖ Error: curl or wget is required to install IPChat.${NC}\n"
    exit 1
fi

# 4. Extract Archive
tar -xzf "$TMP_DIR/$ASSET_NAME" -C "$TMP_DIR"
if [ ! -f "$TMP_DIR/$BINARY_NAME" ]; then
    printf "${RED}✖ Error: %s binary not found in downloaded archive.${NC}\n" "$BINARY_NAME"
    exit 1
fi

chmod +x "$TMP_DIR/$BINARY_NAME"

# 5. Determine Install Destination (/usr/local/bin or ~/.local/bin)
INSTALL_DIR="/usr/local/bin"
USE_SUDO=false

if [ ! -w "$INSTALL_DIR" ]; then
    if [ "$EUID" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
        USE_SUDO=true
    else
        INSTALL_DIR="$HOME/.local/bin"
        mkdir -p "$INSTALL_DIR"
    fi
fi

# 6. Install Binary
printf "Installing to ${BOLD}%s/%s${NC}...\n" "$INSTALL_DIR" "$BINARY_NAME"

if [ "$USE_SUDO" = true ]; then
    sudo mv "$TMP_DIR/$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"
else
    mv "$TMP_DIR/$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"
fi

printf "\n${GREEN}${BOLD}✔ IPChat installed successfully!${NC}\n\n"

# Verify PATH
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    printf "${YELLOW}⚠ Warning: %s is not in your system PATH.${NC}\n" "$INSTALL_DIR"
    printf "Add it to your ~/.bashrc or ~/.zshrc:\n"
    printf "  export PATH=\"%s:\$PATH\"\n\n" "$INSTALL_DIR"
fi

printf "Run ${BOLD}ipchat${NC} to start your first secure chat session!\n"

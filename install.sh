#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LABEL="com.user.powerbottom"
BINARY="/usr/local/bin/PowerBottom"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

echo "==> Compiling PowerBottom..."
swiftc -O -o PowerBottom "$SCRIPT_DIR/PowerBottom.swift" -framework Cocoa

echo "==> Installing binary to $BINARY..."
sudo cp PowerBottom "$BINARY"
sudo chmod 755 "$BINARY"
rm PowerBottom

echo "==> Installing LaunchAgent..."
mkdir -p "$HOME/Library/LaunchAgents"
cp "$SCRIPT_DIR/$LABEL.plist" "$PLIST"

# Unload if already running
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true

echo "==> Loading LaunchAgent..."
launchctl bootstrap "gui/$(id -u)" "$PLIST"

echo ""
echo "Done! PowerBottom is now running in the background."
echo "  Logs: /tmp/PowerBottom.log"
echo "  To stop:      launchctl bootout gui/$(id -u)/$LABEL"
echo "  To uninstall: $SCRIPT_DIR/uninstall.sh"

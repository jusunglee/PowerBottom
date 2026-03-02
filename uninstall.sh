#!/bin/bash
set -euo pipefail

LABEL="com.user.powerbottom"
BINARY="/usr/local/bin/PowerBottom"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

echo "==> Stopping PowerBottom..."
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true

echo "==> Removing LaunchAgent plist..."
rm -f "$PLIST"

echo "==> Removing binary..."
sudo rm -f "$BINARY"

echo "Done! PowerBottom has been uninstalled."

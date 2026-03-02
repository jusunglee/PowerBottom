# PowerBottom

A macOS menu bar utility that automatically arranges your external display above your laptop screen when plugged in.

## What it does

When you connect an external monitor, PowerBottom:

1. Detects the new display
2. Places the external monitor at the top (making it the primary display with menu bar and dock)
3. Centers the laptop screen below it

No more dragging displays around in System Settings every time you plug in.

## Install

```bash
./install.sh
```

This compiles the Swift source, installs the binary to `/usr/local/bin/PowerBottom`, and sets up a LaunchAgent so it starts automatically on login.

## Uninstall

```bash
./uninstall.sh
```

## Usage

PowerBottom runs as a menu bar app with a peach icon. Click it to:

- **Disable/Enable** — toggle automatic arrangement
- **Quit** — stop PowerBottom

Logs are written to `/tmp/PowerBottom.log`.

## Requirements

- macOS
- Xcode Command Line Tools (`xcode-select --install`)

#!/bin/bash
# Install/refresh the OrbStack watchdog LaunchAgent for the logged-in user (no sudo).
# Usage (on the Mac mini): hosts/mac-mini/host/orbstack-watchdog/install.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
label=com.homelab.orbstack-watchdog
dest="$HOME/Library/LaunchAgents/$label.plist"
chmod +x "$here/orbstack-watchdog.sh"
mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
sed "s#__SCRIPT__#$here/orbstack-watchdog.sh#" "$here/$label.plist" > "$dest"
launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$dest"
launchctl print "gui/$(id -u)/$label" | grep -E "state|run interval|program|arguments" | head -4
echo "Installed $dest (log: ~/Library/Logs/homelab-orbstack-watchdog.log)"

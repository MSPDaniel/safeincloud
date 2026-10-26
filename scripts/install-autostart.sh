#!/usr/bin/env bash
set -Eeuo pipefail
mkdir -p /config/.config/autostart
cat >/config/.config/autostart/safeincloud.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=SafeInCloud
Exec=/opt/safeincloud/delayed-autostart.sh
Terminal=false
StartupNotify=false
DESKTOP

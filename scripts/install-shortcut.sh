#!/usr/bin/env bash
set -Eeuo pipefail
# Webtop XFCE uses /config as the persistent home for user abc.
DESKTOP_DIR="${XDG_DESKTOP_DIR:-/config/Desktop}"
mkdir -p "$DESKTOP_DIR"
cat > "$DESKTOP_DIR/SafeInCloud.desktop" <<'DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=SafeInCloud
Comment=Launch SafeInCloud password manager
Exec=/opt/safeincloud/launch.sh
Icon=dialog-password
Terminal=false
Categories=Utility;
StartupNotify=false
DESKTOP
chmod 755 "$DESKTOP_DIR/SafeInCloud.desktop"

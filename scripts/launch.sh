#!/usr/bin/env bash
set -Eeuo pipefail
mkdir -p /config/safeincloud
# Apply XFCE setting in the desktop session before launching Wine.
/opt/safeincloud/configure-xfce.sh || { echo "XFCE preparation failed; see /config/safeincloud/xfce-startup.log" >&2; exit 1; }
/opt/safeincloud/initialize.sh || { echo "SafeInCloud installation failed; see /config/safeincloud/install.log" >&2; exit 1; }
/opt/safeincloud/install-shortcut.sh
/opt/safeincloud/sync-app.sh
cd /config/safeincloud/app
export WINEPREFIX=/config/safeincloud/wine
export PATH="/usr/lib/x86_64-linux-gnu/wine:$PATH"
export WINESERVER=/usr/lib/x86_64-linux-gnu/wine/wineserver
unset LD_PRELOAD WINEARCH
# Apply WPF software rendering on every launch, including existing Wine prefixes.
# Avoids X11 BadMatch (X_CopyArea) failures seen with SafeInCloud under Webtop.
wine reg add 'HKCU\Software\Microsoft\Avalon.Graphics' /v DisableHWAcceleration /t REG_DWORD /d 1 /f >/dev/null
exec wine SafeInCloud.exe

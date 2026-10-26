#!/usr/bin/env bash
set -Eeuo pipefail
export WINEPREFIX=/config/safeincloud/wine
export PATH="/usr/lib/x86_64-linux-gnu/wine:$PATH"
export WINESERVER=/usr/lib/x86_64-linux-gnu/wine/wineserver
unset LD_PRELOAD WINEARCH
APP=/config/safeincloud/app
SOURCE=/opt/safeincloud/source
STATE=/config/safeincloud/.ready
LOG=/config/safeincloud/install.log
mkdir -p /config/safeincloud
if [[ ! -f "$STATE" ]]; then
  exec 9>/config/safeincloud/.install.lock
  flock 9
  if [[ ! -f "$STATE" ]]; then
    { 
      echo "Starting fresh SafeInCloud initialization: $(date -Is)"
      test -f "$SOURCE/SafeInCloud.exe" || { echo "ERROR: place SafeInCloud.exe and all companion files in source/"; exit 1; }
      /opt/safeincloud/sync-app.sh
      mkdir -p "$WINEPREFIX"
      test -x "$WINESERVER" || { echo "ERROR: wineserver missing: $WINESERVER"; exit 1; }
      wineboot --init
      winetricks -q dotnet48
      winetricks -q corefonts
      wine reg add 'HKCU\Software\Microsoft\Avalon.Graphics' /v DisableHWAcceleration /t REG_DWORD /d 1 /f
      release_line=$(wine reg query 'HKLM\Software\Microsoft\NET Framework Setup\NDP\v4\Full' /v Release)
      echo "$release_line"
      release_hex=$(printf '%s\n' "$release_line" | grep -Eo '0[xX][0-9a-fA-F]+' | tail -1)
      [[ "$release_hex" =~ ^0x[[:xdigit:]]+$ ]] || { echo "ERROR: .NET release value missing"; exit 1; }
      (( 16#${release_hex#0x} >= 528040 )) || { echo "ERROR: .NET 4.8 not installed ($release_hex)"; exit 1; }
      winetricks list-installed | grep -Eiq '(^|[[:space:]])corefonts([[:space:]]|$)' || { echo "ERROR: corefonts not recorded by winetricks"; exit 1; }
      touch "$STATE"
      echo "Installation completed: $(date -Is)"
    } >>"$LOG" 2>&1 || { echo "Initialization failed. See $LOG"; exit 1; }
  fi
fi

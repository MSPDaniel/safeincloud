#!/usr/bin/env bash
# Run from XFCE autostart; defer the first SafeInCloud launch until the
# graphical session has settled. Desktop shortcut still launches immediately.
set -Eeuo pipefail
LOG=/config/safeincloud/xfce-autostart.log
mkdir -p /config/safeincloud
exec >>"$LOG" 2>&1
stamp() { printf '[%s] %s\n' "$(date -Is)" "$*"; }
trap 'stamp "ERROR: delayed autostart failed at line $LINENO (exit $?)"' ERR
stamp "Autostart wrapper started (DISPLAY=${DISPLAY:-unset})"
# Verify readiness and persistent compositor setting first. The existing
# configure script also logs any failure to xfce-startup.log.
/opt/safeincloud/configure-xfce.sh
stamp "XFCE ready and compositor disabled; waiting 5 seconds"
sleep 5
# Re-verify immediately before launch; configure-xfce.sh already includes
# a final 2-second settle and check.
/opt/safeincloud/configure-xfce.sh
stamp "Launching SafeInCloud after delayed startup"
exec /opt/safeincloud/launch.sh

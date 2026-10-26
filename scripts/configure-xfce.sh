#!/usr/bin/env bash
# Called inside the XFCE desktop session. Do not start Wine until xfwm4 and
# xfconfd are alive and compositing is verifiably disabled.
set -Eeuo pipefail
LOG=/config/safeincloud/xfce-startup.log
mkdir -p /config/safeincloud
exec >>"$LOG" 2>&1
printf '\n[%s] Checking XFCE desktop readiness (DISPLAY=%s)\n' "$(date -Is)" "${DISPLAY:-unset}"
fail() { echo "[$(date -Is)] ERROR: $*" >&2; exit 1; }
command -v xfconf-query >/dev/null 2>&1 || fail 'xfconf-query unavailable'
[[ -n "${DISPLAY:-}" ]] || fail 'DISPLAY is unset'
# The processes can appear before xfconf's D-Bus session becomes responsive.
ready=false
for i in $(seq 1 60); do
  if pgrep -u "$(id -u)" -x xfwm4 >/dev/null && \
     pgrep -u "$(id -u)" -x xfconfd >/dev/null && \
     xfconf-query -c xfwm4 -p /general/use_compositing >/dev/null 2>&1; then
    ready=true
    break
  fi
  sleep 1
done
[[ "$ready" == true ]] || fail 'xfwm4/xfconfd or xfconf property not ready after 60 seconds'
# xfconf-query writes the setting to the user's persistent XFCE configuration.
if ! xfconf-query -c xfwm4 -p /general/use_compositing -s false; then
  fail 'could not set XFCE compositing to false'
fi
value=$(xfconf-query -c xfwm4 -p /general/use_compositing) || fail 'could not read back compositing state'
[[ "$value" == false ]] || fail "compositing verification failed (got: $value)"
echo "[$(date -Is)] Compositing disabled and verified; waiting 2 seconds"
sleep 2
# Recheck immediately before Wine starts, in case the desktop changed it.
value=$(xfconf-query -c xfwm4 -p /general/use_compositing) || fail 'final compositing verification failed'
[[ "$value" == false ]] || fail "compositing was re-enabled (got: $value)"
echo "[$(date -Is)] XFCE ready; SafeInCloud may launch"

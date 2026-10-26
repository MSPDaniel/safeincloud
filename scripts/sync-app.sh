#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=/config/safeincloud
SOURCE=/opt/safeincloud/source
APP="$ROOT/app"
STATE="$ROOT/.source.sha256"
mkdir -p "$ROOT"
[[ -f "$SOURCE/SafeInCloud.exe" ]] || { echo "Missing $SOURCE/SafeInCloud.exe" >&2; exit 1; }
# Hash contents and relative paths, not timestamps, to detect added/changed/deleted files.
source_hash() {
  ( cd "$SOURCE" && find . -type f -print0 | LC_ALL=C sort -z | while IFS= read -r -d '' f; do
      printf '%s\0' "$f"
      sha256sum < "$f"
    done ) | sha256sum | awk '{print $1}'
}
exec 8>"$ROOT/.app-sync.lock"
flock 8
NEW_HASH=$(source_hash)
OLD_HASH=$(cat "$STATE" 2>/dev/null || true)
if [[ -d "$APP" && "$NEW_HASH" == "$OLD_HASH" ]]; then
  exit 0
fi
# For an existing install with no recorded source hash, do not overwrite it silently.
if [[ -d "$APP" && ! -f "$STATE" ]]; then
  echo "Existing app has no source fingerprint; recording current source without replacing app." >&2
  printf '%s\n' "$NEW_HASH" > "$STATE"
  exit 0
fi
STAMP=$(date +%Y%m%d-%H%M%S)
STAGING="$ROOT/.app-new-$$"
BACKUP="$ROOT/app-backups/app-$STAMP-$$"
mkdir -p "$STAGING" "$ROOT/app-backups"
trap 'rm -rf -- "$STAGING"' EXIT
cp -a "$SOURCE"/. "$STAGING"/
[[ -f "$STAGING/SafeInCloud.exe" ]] || exit 1
# Data contains the user database and settings. Never replace it with Data
# bundled in an updated portable application. Keep the existing Data directory
# intact in the new application before swapping the directories.
if [[ -e "$APP/Data" || -L "$APP/Data" ]]; then
  [[ -d "$APP/Data" && ! -L "$APP/Data" ]] || {
    echo "ERROR: existing app/Data is not a regular directory; refusing update" >&2
    exit 1
  }
  rm -rf -- "$STAGING/Data"
  cp -a -- "$APP/Data" "$STAGING/Data"
  echo "Preserved existing SafeInCloud Data directory during application update"
fi
chmod -R u+rwX "$STAGING"
if [[ -d "$APP" ]]; then
  mv "$APP" "$BACKUP"
  if ! mv "$STAGING" "$APP"; then
    mv "$BACKUP" "$APP"
    exit 1
  fi
  echo "Application updated. Previous application saved in $BACKUP"
else
  mv "$STAGING" "$APP"
  echo "Application installed from source"
fi
printf '%s\n' "$NEW_HASH" > "$STATE"

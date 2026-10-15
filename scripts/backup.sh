#!/usr/bin/env bash
# Cold backup of one stack: stop it, archive its folder (compose, .env, data/config), start it again.
# Usage: scripts/backup.sh <host> <stack> [destination]   (default destination: ./backups)
# Example (cron on the Pi): scripts/backup.sh raspberry-pi portainer /mnt/unraid-backups/pi
set -euo pipefail

host=${1:?host required}
stack=${2:?stack required}
dest=${3:-./backups}

repo=$(cd "$(dirname "$0")/.." && pwd)
dir="$repo/hosts/$host/$stack"
[[ -f "$dir/compose.yaml" ]] || { echo "No compose.yaml in $dir" >&2; exit 1; }

mkdir -p "$dest"
archive="$dest/${host}_${stack//\//-}_$(date +%Y%m%d-%H%M%S).tar.gz"

compose=(docker compose --project-directory "$dir" -f "$dir/compose.yaml")
"${compose[@]}" stop
trap '"${compose[@]}" start' EXIT

# sudo may be needed when containers wrote files as another UID.
tar -czf "$archive" -C "$(dirname "$dir")" "$(basename "$dir")"
echo "Backup written: $archive"

# Keep the 7 newest archives for this stack.
ls -1t "$dest/${host}_${stack//\//-}_"*.tar.gz | tail -n +8 | xargs -r rm --

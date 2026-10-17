#!/usr/bin/env bash
# Prepare the Home Assistant OS disk image for the `homeassistant` VM on Unraid.
# Downloads the official KVM image (haos_ova-<version>.qcow2.xz), verifies its SHA-256,
# decompresses it into the `domains` share and grows it to the target size. HAOS expands its
# data partition to fill the disk on first boot. The VM itself is created in the Unraid UI
# (hosts/unraid/README.md → Home Assistant OS VM).
# Usage (on Unraid, as root): hosts/unraid/host/homeassistant/prepare-disk.sh [version sha256 [size]]
#   e.g.  hosts/unraid/host/homeassistant/prepare-disk.sh 18.3 fae6a728…4090 64G
# The SHA-256 is the `digest` of haos_ova-<version>.qcow2.xz on the GitHub release page.
# Only for a fresh install: upgrades happen inside Home Assistant (Settings → System → Updates).
set -euo pipefail

version=${1:-18.3}
sha256=${2:-fae6a728768cc10aff60d4820bfcd40d64cd77fab82c8bd92af13b3d9d414090}
size=${3:-64G}
asset="haos_ova-$version.qcow2.xz"
url="https://github.com/home-assistant/operating-system/releases/download/$version/$asset"
dir=/mnt/user/domains/homeassistant
disk=$dir/haos.qcow2

if [ -e "$disk" ]; then
  echo "$disk already exists; refusing to overwrite an installed Home Assistant." >&2
  exit 1
fi
command -v qemu-img >/dev/null || { echo "qemu-img missing: enable VMs in Settings → VM Manager" >&2; exit 1; }

mkdir -p "$dir"
tmp=$(mktemp -d -p "$dir"); trap 'rm -rf "$tmp"' EXIT   # same share: no 1 GB download into RAM
curl -fL --progress-bar -o "$tmp/$asset" "$url"
echo "$sha256  $tmp/$asset" | sha256sum -c -

xz -dc "$tmp/$asset" > "$tmp/haos.qcow2"
qemu-img resize "$tmp/haos.qcow2" "$size"
mv "$tmp/haos.qcow2" "$disk"
chown nobody:users "$disk"

qemu-img info "$disk"
echo "Ready: $disk (HAOS $version). Create the VM in the Unraid UI next."

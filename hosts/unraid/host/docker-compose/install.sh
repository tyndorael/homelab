#!/usr/bin/env bash
# Install the official Docker Compose CLI plugin on Unraid and keep it across reboots.
# Unraid's root filesystem lives in RAM, so the binary is stored on the flash drive and the
# boot script (/boot/config/go) copies it into place at every start.
# Usage (on Unraid, as root): hosts/unraid/host/docker-compose/install.sh [version]
#   e.g.  hosts/unraid/host/docker-compose/install.sh v5.6.0
# Re-runnable: run it again with a newer version to upgrade.
set -euo pipefail

version=${1:-v5.6.0}
arch=$(uname -m)                       # x86_64
asset="docker-compose-linux-$arch"
base="https://github.com/docker/compose/releases/download/$version"
store=/boot/config/plugins/docker-compose
target=/usr/libexec/docker/cli-plugins/docker-compose
go=/boot/config/go
marker="# homelab: docker compose CLI plugin"

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/$asset" "$base/$asset"
curl -fsSL -o "$tmp/$asset.sha256" "$base/$asset.sha256"
(cd "$tmp" && sha256sum -c "$asset.sha256")   # official checksum from the same release

mkdir -p "$store"
cp "$tmp/$asset" "$store/docker-compose"
echo "$version" > "$store/VERSION"
install -D -m 0755 "$store/docker-compose" "$target"

if ! grep -qF "$marker" "$go"; then
  cp "$go" "$go.bak.$(date +%Y%m%d%H%M%S)"
  cat >> "$go" <<EOF

$marker (hosts/unraid/host/docker-compose/install.sh)
install -D -m 0755 $store/docker-compose $target
EOF
fi

docker compose version

#!/usr/bin/env bash
# Install Cockpit on the Pi host and bind it to loopback + the Docker `proxy` gateway only.
# Usage (on the Pi): hosts/raspberry-pi/host/cockpit/install.sh <domain>
#   e.g.  hosts/raspberry-pi/host/cockpit/install.sh tyndorael.duckdns.org
# Re-runnable: it re-renders the config and restarts the socket.
set -euo pipefail

domain=${1:?domain required, e.g. tyndorael.duckdns.org}
here=$(cd "$(dirname "$0")" && pwd)
gateway=$(docker network inspect proxy --format '{{range .IPAM.Config}}{{.Gateway}}{{end}}')
[[ -n "$gateway" ]] || { echo "Docker network 'proxy' not found (make network HOST=raspberry-pi)" >&2; exit 1; }

# No cockpit-packagekit: updates stay with apt/unattended-upgrades (and PackageKit's cache
# refreshes would add SD-card writes).
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
  cockpit cockpit-networkmanager cockpit-storaged

sudo install -d /etc/cockpit /etc/systemd/system/cockpit.socket.d
sed "s/__DOMAIN__/$domain/g" "$here/cockpit.conf.template" | sudo tee /etc/cockpit/cockpit.conf >/dev/null
sed "s/__GATEWAY__/$gateway/g" "$here/cockpit.socket.d/listen.conf.template" \
  | sudo tee /etc/systemd/system/cockpit.socket.d/listen.conf >/dev/null

sudo systemctl daemon-reload
sudo systemctl enable --now cockpit.socket
sudo systemctl restart cockpit.socket
echo "Cockpit listening on 127.0.0.1:9090 and $gateway:9090"
echo "NPM proxy host: cockpit.$domain -> https://$gateway:9090 (websockets on)"

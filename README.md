# Homelab

Docker Compose definitions for a small homelab, one folder per stack, all state in local bind mounts.

> Earlier setups are preserved as git tags: `v1-proxmox` (Proxmox + Terraform + Ansible) and `v1-ubuntu` (single-host Docker stacks, the previous `main`).

## Hosts (phase 1)
| Host | Role | Stacks |
|---|---|---|
| [Raspberry Pi 4 · 8 GB · microSD](hosts/raspberry-pi/README.md) | Edge / control | `nginx-proxy-manager`, `portainer`, `homepage`, `glance`, `gatus`, `dozzle`, `termix`, `adguard-home`, `tailscale` + Cockpit on the host |
| [Unraid](hosts/unraid/README.md) | Storage / media | `portainer-agent`, `media` (Jellyfin, Sonarr, Radarr, Prowlarr, qBittorrent) |
| [Mac mini](hosts/mac-mini/README.md) | Development / apps | `portainer-agent`, `apps/*` |

```
LAN ──► Pi :443 Nginx Proxy Manager ──► Pi containers (proxy network)
                                     ├─► Unraid  <ip>:<port>
                                     └─► Mac mini <ip>:<port>
         Pi Portainer ──agent :9001──► Unraid, Mac mini
```

## Layout
```
hosts/<host>/<stack>/   compose.yaml, .env.example, local data/ + config/ (gitignored)
templates/service/      starting point for new stacks
docs/                   conventions, network/DNS, backups
scripts/backup.sh       cold backup of a stack folder
Makefile                docker compose wrapper
```

## Quick start
On each host, after cloning the repo:
```bash
cp hosts/<host>/<stack>/.env.example hosts/<host>/<stack>/.env   # fill it in
make up HOST=<host> STACK=<stack>
```
Start order: **Pi** (`make network`, NPM → Portainer → Homepage) → **Unraid** → **Mac mini**. Use the same `AGENT_SECRET` in Portainer and every agent.

Other targets: `down`, `restart`, `pull`, `update`, `logs`, `ps`, `config`, `validate`.

## Docs
- [Conventions & good practices](docs/conventions.md)
- [Network, DNS & TLS](docs/network.md)
- [Backups](docs/backups.md)

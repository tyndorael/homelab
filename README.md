# Homelab

Docker Compose definitions for a small homelab, one folder per stack, all state in local bind mounts.

> Earlier setups are preserved as git tags: `v1-proxmox` (Proxmox + Terraform + Ansible) and `v1-ubuntu` (single-host Docker stacks, the previous `main`).

## Hosts (phase 1)
| Host | Role | Stacks |
|---|---|---|
| [Raspberry Pi 4 · 8 GB · microSD](hosts/raspberry-pi/README.md) | Edge / control | `nginx-proxy-manager`, `portainer`, `homepage`, `glance`, `gatus`, `dozzle`, `termix`, `rustdesk`, `adguard-home`, `tailscale` + Cockpit on the host |
| [Unraid · Dell Precision 5820 · 10GbE · herta](hosts/unraid/README.md) | Storage / media / VMs | `portainer-agent`, `media` (Jellyfin, Sonarr, Radarr, Prowlarr, qBittorrent); planned: Home Assistant OS VM |
| [Mac mini M2 · silverwolf](hosts/mac-mini/README.md) | Development / apps | `portainer-agent`, `dozzle-agent`, `apps/open-webui` + Ollama (native) |

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

## Remote desktop to the Mac mini
The Mac mini (`silverwolf`, RustDesk ID **`80340206`**) is reachable with RustDesk through our own server on the Pi; no RustDesk public servers are involved. Works at home and, through Tailscale, away from home. More options (built-in Screen Sharing, browser via Termix) in [docs/remote-desktop.md](docs/remote-desktop.md).

**1. Install the RustDesk client**

| Windows | Mac |
|---|---|
| `winget install --id RustDesk.RustDesk -e` (or the installer from [rustdesk.com](https://rustdesk.com/download)) | `brew install --cask rustdesk` (or the `.dmg` from [rustdesk.com](https://rustdesk.com/download)) |

**2. Point it at our server**, in RustDesk: **⋮ (next to your ID) → Network → ID/Relay server** (Windows), or **Settings → Network → ID/Relay server** (Mac). Unlock network settings if asked.

| Field | Value |
|---|---|
| ID server | `192.168.50.106` |
| Relay server | `192.168.50.106` |
| API server | *(leave empty)* |
| Key | output of `ssh tyndorael@192.168.50.106 cat ~/homelab/hosts/raspberry-pi/rustdesk/data/id_ed25519.pub` |

Click OK. The status at the bottom should read **Ready**.

**3. Connect**: type `80340206` in *Control Remote Desktop* → **Connect** → enter the Mac mini's RustDesk permanent password.

**Away from home**: connect Tailscale on the client first, then use RustDesk as usual. The Pi routes `192.168.50.0/24`; on Windows/Mac the Tailscale app accepts subnet routes by default (Linux: `tailscale up --accept-routes`).

**Mac-only alternative**: Finder → *Go → Connect to Server…* → `vnc://192.168.50.206` (built-in Screen Sharing, choose *High Performance*). **Windows alternative**: RealVNC Viewer → `192.168.50.206` with the Mac's macOS login.

## Docs
- [Conventions & good practices](docs/conventions.md)
- [Network, DNS & TLS](docs/network.md)
- [Backups](docs/backups.md)
- [Remote desktop](docs/remote-desktop.md)

# Homelab

Docker-based homelab on an Ubuntu host, backed by TrueNAS storage over NFS.

## Architecture

```
LAN
 │
 ├── Homepage       :3001  ← start here
 ├── Portainer      :9000  (container management)
 ├── NPM            :81    (reverse proxy)
 ├── Dozzle         :8082  (container logs)
 ├── Uptime Kuma    :3002  (uptime monitoring)
 ├── Beszel         :8090  (server monitoring)
 ├── Scrutiny       :8083  (disk SMART health)
 ├── Glances        :61208 (host metrics)
 ├── Speedtest      :8765  (internet speed)
 ├── ComfyUI        :8188  (AI image generation, GPU)
 ├── Ollama         :11434 (local LLM serving, GPU)
 ├── Open WebUI     :3080  (LLM chat frontend)
 ├── faster-whisper :10300 (speech-to-text, GPU)
 ├── qBittorrent    :8080  (torrents)
 ├── Bazarr         :6767  (subtitles)
 ├── Navidrome      :4533  (music)
 ├── Plex           :32400 (video)
 ├── Jellyfin       :8096  (video)
 ├── Tautulli       :8181  (Plex analytics)
 └── Watchtower      —     (auto image updates, no UI)
```

All containers share a Docker bridge network called `homelab`. NFS shares from TrueNAS are mounted on the Ubuntu host and passed into containers as bind mounts.

## Prerequisites

- [Docker Engine](https://docs.docker.com/engine/install/ubuntu/) installed and running on Ubuntu
- TrueNAS reachable over the local network
- For the AI stack only: an NVIDIA GPU with drivers installed, plus the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) (see [Start the AI stack](#8-start-the-ai-stack))

## First-time Setup

### 1. Mount TrueNAS media share (NFS)

Install NFS client tools and create mount points:

```bash
sudo apt install nfs-common
sudo mkdir -p /mnt/media /mnt/music /mnt/downloads
```

Mount your TrueNAS shares:

```bash
sudo mount -t nfs <truenas-ip>:/mnt/<pool>/media /mnt/media
sudo mount -t nfs <truenas-ip>:/mnt/<pool>/music /mnt/music
sudo mount -t nfs <truenas-ip>:/mnt/<pool>/downloads /mnt/downloads
```

To make them persistent across reboots, add to `/etc/fstab`:

```
<truenas-ip>:/mnt/<pool>/media     /mnt/media     nfs defaults,soft 0 0
<truenas-ip>:/mnt/<pool>/music     /mnt/music     nfs defaults,soft 0 0
<truenas-ip>:/mnt/<pool>/downloads /mnt/downloads nfs defaults,soft 0 0
```

> **Note:** `/mnt/media` and `/mnt/music` are mounted **read-only** inside containers. `/mnt/downloads` is mounted **read-write** so qBittorrent can write completed torrents there. Make sure the TrueNAS dataset permissions allow writes from your host's `PUID`/`PGID`.

Verify:

```bash
ls /mnt/media
ls /mnt/downloads
```

### 2. Create the shared Docker network

```bash
make network
```

### 3. Configure environment variables

```bash
# Core stack
cp stacks/core/.env.example stacks/core/.env

# Media stack
cp stacks/media/.env.example stacks/media/.env
```

Edit each `.env` file and fill in your values (host IP, Plex claim, media path, etc.).

### 4. Start the core stack

```bash
make core-up
```

Services started:
| Service | URL |
|---|---|
| Homepage dashboard | `http://localhost:3001` |

### 5. Configure the Homepage dashboard

The dashboard config lives in `stacks/core/config/homepage/` and is version-controlled. Fill in the `HOMEPAGE_VAR_*` variables in `stacks/core/.env` to enable live service widgets:

| Variable | Where to find it |
|---|---|
| `HOMEPAGE_VAR_HOST_IP` | Your Ubuntu host's local IP (`ip addr show`) |
| `HOMEPAGE_VAR_PLEX_TOKEN` | [How to find your Plex token](https://support.plex.tv/articles/204059436) |
| `HOMEPAGE_VAR_JELLYFIN_API_KEY` | Jellyfin → Dashboard → API Keys |
| `HOMEPAGE_VAR_NAVIDROME_USER` / `_TOKEN` / `_SALT` | Navidrome Subsonic credentials (see Navidrome docs) |
| `HOMEPAGE_VAR_PORTAINER_URL` | Portainer URL (e.g. `http://host-ip:9000`) |
| `HOMEPAGE_VAR_NPM_URL` | NPM admin UI URL (e.g. `http://host-ip:81`) |
| `HOMEPAGE_VAR_NPM_EMAIL` / `_PASSWORD` | NPM admin credentials |
| `HOMEPAGE_VAR_QBITTORRENT_URL` | qBittorrent URL (e.g. `http://host-ip:8080`) |
| `HOMEPAGE_VAR_QBITTORRENT_USERNAME` / `_PASSWORD` | qBittorrent web UI credentials |
| `HOMEPAGE_VAR_BESZEL_URL` | Beszel hub URL (e.g. `http://host-ip:8090`) |
| `HOMEPAGE_VAR_COMFYUI_URL` | ComfyUI URL (e.g. `http://host-ip:8188`) |
| `HOMEPAGE_VAR_DOZZLE_URL` | Dozzle URL (e.g. `http://host-ip:8082`) |
| `HOMEPAGE_VAR_UPTIMEKUMA_URL` | Uptime Kuma URL (e.g. `http://host-ip:3002`) |
| `HOMEPAGE_VAR_SCRUTINY_URL` | Scrutiny URL (e.g. `http://host-ip:8083`) |
| `HOMEPAGE_VAR_GLANCES_URL` | Glances URL (e.g. `http://host-ip:61208`) |
| `HOMEPAGE_VAR_BAZARR_URL` / `_KEY` | Bazarr URL + API key (Bazarr → Settings → General) |
| `HOMEPAGE_VAR_TAUTULLI_URL` / `_KEY` | Tautulli URL + API key (Tautulli → Settings → Web Interface) |
| `HOMEPAGE_VAR_OPENWEBUI_URL` | Open WebUI URL (e.g. `http://host-ip:3080`) |

Widgets are optional — the dashboard works as a plain launcher without them.

> The **Uptime Kuma** widget needs a public status page with the slug `homelab` (create one
> in Uptime Kuma → Status Pages); otherwise the tile still links but shows no live data.

### 6. Start the media stack

Get a Plex claim token from [plex.tv/claim](https://www.plex.tv/claim) (expires in 4 minutes) and set it in `stacks/media/.env`, then:

```bash
make media-up
```

Services started:
| Service | URL |
|---|---|
| Plex | `http://localhost:32400/web` |
| Jellyfin | `http://localhost:8096` |
| Navidrome | `http://localhost:4533` |
| qBittorrent | `http://localhost:8080` |
| Bazarr | `http://localhost:6767` |
| Tautulli | `http://localhost:8181` |

> **Bazarr** mounts the media tree **read-write** (it writes subtitle files next to the
> videos), unlike Plex/Jellyfin which mount it read-only. After first start, point Bazarr at
> your Sonarr/Radarr or add paths manually, and connect Tautulli to Plex with your Plex token.

### 7. Start the tools stack

```bash
cp stacks/tools/.env.example stacks/tools/.env
# edit stacks/tools/.env (generate the Speedtest APP_KEY as noted in the file)
make tools-up
```

Services started:
| Service | URL |
|---|---|
| Speedtest Tracker | `http://localhost:8765` |
| Beszel (hub) | `http://localhost:8090` |
| Scrutiny | `http://localhost:8083` |
| Glances | `http://localhost:61208` |
| Watchtower | _(no UI — runs in the background)_ |

> **Scrutiny** needs the physical disks mapped into the container. The compose file's
> `devices:` list is set to this host's NVMe drives (`/dev/nvme0n1`, `/dev/nvme1n1`) — run
> `lsblk -d` and adjust it if your drives differ. Every device listed must exist or the
> container won't start.
>
> Devices only appear after the first collector scan (default schedule: every 24 h). Trigger
> one immediately after startup so disks show up right away:
> ```bash
> docker exec scrutiny /opt/scrutiny/bin/scrutiny-collector-metrics run
> ```
> To shorten the scan interval, create `stacks/tools/config/scrutiny/scrutiny.yaml`
> (the directory is gitignored, so create it by hand):
> ```yaml
> log:
>   level: INFO
>
> collector:
>   schedule: "@every 6h"
> ```
>
> **Watchtower** runs in label-enable mode: it only updates containers carrying
> `com.centurylinklabs.watchtower.enable=true`. Every service in this homelab is labeled, so
> all are auto-updated on the `WATCHTOWER_SCHEDULE` cron (default: daily at 04:00). Remove the
> label from a service to opt it out. Labels apply once you recreate the containers
> (`make <stack>-up`).

#### Beszel two-step setup

Beszel ships as a **hub** (the dashboard) plus an **agent** that reports this host's
metrics. The agent needs a key and token that the hub only generates after you add a
system, so bring it up in two passes:

1. After the first `make tools-up`, open the hub at `http://<host-ip>:8090` and create
   the admin account.
2. Click **Add System** and fill in:
   - **Host/IP:** `host.docker.internal`
   - **Port:** `45876`
3. Copy the generated **public key** and **token** into `BESZEL_KEY` and `BESZEL_TOKEN`
   in `stacks/tools/.env`.
4. Run `make tools-up` again to (re)start the agent. The system should turn green in the
   hub within a few seconds.

> The agent runs with `network_mode: host` so it reports the host's CPU, memory, disk,
> and network — not the container's. The hub reaches it back over `host.docker.internal`.

### 8. Start the AI stack

ComfyUI runs on the host NVIDIA GPU. The GPU driver alone is **not** enough — Docker
needs the **NVIDIA Container Toolkit** to pass the GPU into the container. Install it once:

```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
  | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

Verify Docker can see the GPU:

```bash
docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi
```

This should print your GPU. Then bring up the stack:

```bash
cp stacks/ai/.env.example stacks/ai/.env
# edit stacks/ai/.env if you want a different port or data path
make ai-up
```

Services started:
| Service | URL |
|---|---|
| ComfyUI | `http://localhost:8188` |
| Ollama | `http://localhost:11434` (API only) |
| Open WebUI | `http://localhost:3080` |
| faster-whisper | `tcp://localhost:10300` (Wyoming protocol) |

> First run pulls a large CUDA image and populates `stacks/ai/data/comfyui/` with the
> ComfyUI base dir (`models/`, `output/`, `input/`, `custom_nodes/`). Drop model
> checkpoints into the `models/checkpoints/` subfolder, then refresh the UI.
>
> **Ollama, Open WebUI, and faster-whisper all share the GPU** with ComfyUI. Ollama has no
> web UI — pull a model with `docker exec -it ollama ollama pull llama3`, then use it from
> **Open WebUI** (preconfigured to reach Ollama at `http://ollama:11434`). faster-whisper
> exposes the Wyoming speech-to-text protocol on `10300` for clients like Home Assistant.
> Set the model size and language via `WHISPER_MODEL` / `WHISPER_LANG` in `stacks/ai/.env`.

## Day-to-day Commands

```bash
make core-up       # Start core stack
make core-down     # Stop core stack
make media-up      # Start media stack
make media-down    # Stop media stack
make tools-up      # Start tools stack
make tools-down    # Stop tools stack
make ai-up         # Start AI stack
make ai-down       # Stop AI stack
make pull          # Pull latest images for all stacks
make logs-core     # Tail logs for core stack
make logs-media    # Tail logs for media stack
make logs-tools    # Tail logs for tools stack
make logs-ai       # Tail logs for AI stack
make ps            # Show running containers
```

## Directory Structure

```
homelab/
├── .gitignore
├── .env.example          # Shared env vars template
├── Makefile
├── README.md
└── stacks/
    ├── core/
    │   ├── docker-compose.yml
    │   ├── .env.example
    │   ├── config/homepage/   # dashboard config (version-controlled)
    │   └── data/              # ← gitignored (uptime-kuma)
    ├── media/
    │   ├── docker-compose.yml
    │   ├── .env.example
    │   ├── config/            # ← gitignored (plex, jellyfin, qbittorrent, bazarr, tautulli)
    │   └── cache/             # ← gitignored (jellyfin)
    ├── tools/
    │   ├── docker-compose.yml
    │   ├── .env.example
    │   ├── config/            # ← gitignored (speedtest, scrutiny)
    │   └── data/              # ← gitignored (beszel, scrutiny)
    └── ai/
        ├── docker-compose.yml
        ├── .env.example
        └── data/              # ← gitignored (comfyui, ollama, open-webui, faster-whisper)
```

## Updating Services

```bash
make pull          # Pull new images
make core-up       # Recreate core containers
make media-up      # Recreate media containers
make tools-up      # Recreate tools containers
make ai-up         # Recreate AI containers
```

> With **Watchtower** running (tools stack), image updates also happen automatically on a
> schedule. `make pull` + `make <stack>-up` remains the manual path if you'd rather control
> timing yourself.

## Next Tools to Add

A roadmap of services to consider adding, organized by stack. Existing stacks first, then a
few new stacks worth standing up. Curated picks only — one line of "why" each.

> **Heads-up:** Portainer and NPM appear in the architecture diagram and Homepage widgets but
> were added out-of-band (no tracked compose file yet). A good first cleanup is to bring them
> under version control as their own stack before adding more.

### Done — added to existing stacks

These roadmap picks are now implemented (compose + `.env` + Homepage widgets where supported):

- **Core** — **Dozzle** (container logs), **Uptime Kuma** (uptime + status page)
- **Media** — **Bazarr** (subtitles), **Tautulli** (Plex analytics)
- **Tools** — **Scrutiny** (disk SMART), **Glances** (host metrics), **Watchtower** (auto image updates, label-enable mode), plus **Beszel** earlier
- **AI** — **Ollama** (local LLM), **Open WebUI** (chat frontend), **faster-whisper** (speech-to-text)

> Heavier media automation (Prowlarr/Sonarr/Radarr/Jellyseerr) is intentionally left for its
> own `stacks/arr/` stack — see below.

### Proposed new stacks

**`stacks/arr/` — media automation** (drives the existing qBittorrent, lands files in `/mnt/media`)
- **Prowlarr** — indexer manager feeding Sonarr/Radarr.
- **Sonarr + Radarr** — TV/movie automation; natural next step now that a torrent client is in place.
- **Jellyseerr** — request UI for Plex/Jellyfin; integrates with the `*arr` stack.

**`stacks/network/` — remote access & DNS**
- **Tailscale** — secure remote access to the whole homelab without exposing ports.
- **AdGuard Home** (or Pi-hole) — network-wide DNS-based ad/tracker blocking.
- **Authelia / Authentik** _(optional)_ — SSO and 2FA in front of NPM to protect exposed services.

**`stacks/apps/` — personal data & utilities** (good fit for TrueNAS-backed storage)
- **Vaultwarden** — self-hosted Bitwarden-compatible password manager.
- **Immich** — self-hosted photo/video backup (Google Photos alternative); pairs well with NFS storage.
- **Paperless-ngx** _(optional)_ — document scanning, archive, and OCR.

## Troubleshooting

**Containers can't reach each other:** Make sure the `homelab` network exists (`docker network ls`) and that you ran `make network`.

**Permission errors on media files:** Check that `PUID`/`PGID` in `.env` match your user (`id` command).

**NFS mount lost after reboot:** Add the mounts to `/etc/fstab` as shown in the setup step above.

**Plex can't find media:** Verify the NFS mount is active (`ls /mnt/media`) and that `TRUENAS_MEDIA_PATH` in `stacks/media/.env` points to the correct path.

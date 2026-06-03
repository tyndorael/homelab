# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Docker Compose homelab running on an Ubuntu host, backed by TrueNAS storage over NFS. Independent stacks are managed from a single `Makefile`.

## Stack layout

| Stack | Directory | Services |
|---|---|---|
| Core | `stacks/core/` | Homepage dashboard |
| Media | `stacks/media/` | Plex, Jellyfin, Navidrome, qBittorrent |
| Tools | `stacks/tools/` | Speedtest Tracker, Beszel (hub + agent) |
| AI | `stacks/ai/` | ComfyUI (GPU image generation) |

All stacks attach to an external Docker bridge network named `homelab`.

The `ai` stack uses the host NVIDIA GPU, which requires the **NVIDIA Container Toolkit** installed on the host (`nvidia-ctk runtime configure --runtime=docker`, then restart Docker) — the GPU driver alone is not enough for containers to see the GPU.

## Common commands

```bash
make network       # Create the shared Docker network (idempotent)
make core-up       # Start core stack (creates network first)
make core-down     # Stop core stack
make media-up      # Start media stack (creates network first)
make media-down    # Stop media stack
make tools-up      # Start tools stack (creates network first)
make tools-down    # Stop tools stack
make ai-up         # Start AI stack (creates network first)
make ai-down       # Stop AI stack
make pull          # Pull latest images for all stacks
make logs-core     # Tail core stack logs
make logs-media    # Tail media stack logs
make logs-tools    # Tail tools stack logs
make logs-ai       # Tail AI stack logs
make ps            # Show all running containers
```

Each `docker compose` call explicitly passes `--env-file` from the stack's own `.env`.

## Environment files

Each stack has its own `.env.example` → `.env` workflow. The root `.env.example` holds shared vars (`TZ`, `PUID`, `PGID`) but is not consumed directly by any compose file — it's reference only.

- `stacks/core/.env` — Homepage port, allowed hosts, `HOMEPAGE_VAR_*` widget credentials
- `stacks/media/.env` — `PUID`/`PGID`, NFS mount paths, Plex claim token
- `stacks/tools/.env` — `PUID`/`PGID`, Speedtest Tracker `APP_KEY`/`APP_URL`, test schedule, port; Beszel hub port/data dir and agent `BESZEL_KEY`/`BESZEL_TOKEN` (filled after the hub generates them on first run)
- `stacks/ai/.env` — `PUID`/`PGID`, ComfyUI port and data dir (`COMFYUI_DATA`, holds models/output/custom_nodes)

`.env` files are gitignored. Runtime data dirs (`stacks/*/data/`, `stacks/media/config/`, etc.) are also gitignored.

## Homepage dashboard config

Config lives in `stacks/core/config/homepage/` and is version-controlled. The container mounts this directory at `/app/config`.

Widget credentials are injected as `HOMEPAGE_VAR_*` environment variables and referenced in `services.yaml` via `{{HOMEPAGE_VAR_*}}` template syntax. All `HOMEPAGE_VAR_*` vars must be declared both in `stacks/core/.env` **and** in the `environment:` block of `stacks/core/docker-compose.yml` — Homepage only sees vars explicitly passed to the container.

`HOMEPAGE_ALLOWED_HOSTS` must include every hostname and `hostname:port` combination used to reach the dashboard, including the host's LAN IP with port if accessed from other devices.

## NFS mounts

TrueNAS shares are mounted on the Ubuntu host before starting the media stack:
- `/mnt/media` → mounted read-only into Plex and Jellyfin at `/media`
- `/mnt/music` → mounted read-only into Navidrome at `/music`

Paths are configured via `TRUENAS_MEDIA_PATH` and `TRUENAS_MUSIC_PATH` in `stacks/media/.env`.

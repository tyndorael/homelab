# Homelab

Docker-based homelab on an Ubuntu host, backed by TrueNAS storage over NFS.

## Architecture

```
LAN
 │
 ├── Homepage       :3001  ← start here
 ├── Portainer      :9000  (container management)
 ├── qBittorrent    :8080  (torrents)
 ├── Navidrome      :4533  (music)
 ├── Plex           :32400 (video)
 └── Jellyfin       :8096  (video)
```

All containers share a Docker bridge network called `homelab`. NFS shares from TrueNAS are mounted on the Ubuntu host and passed into containers as bind mounts.

## Prerequisites

- [Docker Engine](https://docs.docker.com/engine/install/ubuntu/) installed and running on Ubuntu
- TrueNAS reachable over the local network

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
| `HOMEPAGE_VAR_QBITTORRENT_URL` | qBittorrent URL (e.g. `http://host-ip:8080`) |
| `HOMEPAGE_VAR_QBITTORRENT_USERNAME` / `_PASSWORD` | qBittorrent web UI credentials |

Widgets are optional — the dashboard works as a plain launcher without them.

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

## Day-to-day Commands

```bash
make core-up       # Start core stack
make core-down     # Stop core stack
make media-up      # Start media stack
make media-down    # Stop media stack
make pull          # Pull latest images for all stacks
make logs-core     # Tail logs for core stack
make logs-media    # Tail logs for media stack
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
    │   └── data/          # ← gitignored, created at runtime
    └── media/
        ├── docker-compose.yml
        ├── .env.example
        ├── config/        # ← gitignored, created at runtime
        │   ├── plex/
        │   └── jellyfin/
        └── cache/         # ← gitignored, created at runtime
            └── jellyfin/
```

## Updating Services

```bash
make pull          # Pull new images
make core-up       # Recreate core containers
make media-up      # Recreate media containers
```

## Troubleshooting

**Containers can't reach each other:** Make sure the `homelab` network exists (`docker network ls`) and that you ran `make network`.

**Permission errors on media files:** Check that `PUID`/`PGID` in `.env` match your user (`id` command).

**NFS mount lost after reboot:** Add the mounts to `/etc/fstab` as shown in the setup step above.

**Plex can't find media:** Verify the NFS mount is active (`ls /mnt/media`) and that `TRUENAS_MEDIA_PATH` in `stacks/media/.env` points to the correct path.

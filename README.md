# Homelab

Docker-based homelab on a Mac Mini, backed by TrueNAS storage over NFS.

## Architecture

```
Internet
   │
DuckDNS (dynamic DNS)
   │
Nginx Proxy Manager  ←── SSL termination (Let's Encrypt)
   │
   ├── Homepage       :3000  ← start here
   ├── Portainer      :9000 / :9443
   ├── Plex           :32400
   └── Jellyfin       :8096
```

All containers share a Docker bridge network called `homelab`. NFS shares from TrueNAS are mounted on the Mac host and passed into containers as bind mounts.

## Prerequisites

- [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/) installed and running
- A [DuckDNS](https://www.duckdns.org) account with a subdomain and token
- TrueNAS reachable over the local network

## First-time Setup

### 1. Mount TrueNAS media share (NFS)

Create the mount point and mount your TrueNAS share:

```bash
sudo mkdir -p /Volumes/media
sudo mount -t nfs -o resvport,soft <truenas-ip>:/mnt/<pool>/media /Volumes/media
```

To make it persistent across reboots, add to `/etc/fstab`:

```
<truenas-ip>:/mnt/<pool>/media /Volumes/media nfs resvport,soft,auto
```

Verify:

```bash
ls /Volumes/media
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

Edit each `.env` file and fill in your values (DuckDNS token, Plex claim, media path, etc.).

### 4. Start the core stack

```bash
make core-up
```

Services started:
| Service | URL |
|---|---|
| Homepage dashboard | `http://localhost:3000` |
| Nginx Proxy Manager admin | `http://localhost:81` |
| Portainer | `http://localhost:9000` |

**NPM default credentials:** `admin@example.com` / `changeme` — change these immediately.

### 5. Configure SSL in Nginx Proxy Manager

1. Open NPM admin at `http://localhost:81`
2. Go to **SSL Certificates → Add SSL Certificate → Let's Encrypt**
3. Enter your domain: `*.yourdomain.duckdns.org`
4. Select **DNS Challenge**, provider **DuckDNS**, paste your token
5. Add proxy hosts for each service pointing to the container name + internal port

### 6. Configure the Homepage dashboard

The dashboard config lives in `stacks/core/config/homepage/` and is version-controlled. Fill in the `HOMEPAGE_VAR_*` variables in `stacks/core/.env` to enable live service widgets:

| Variable | Where to find it |
|---|---|
| `HOMEPAGE_VAR_MAC_MINI_IP` | Your Mac Mini's local IP (`ipconfig getifaddr en0`) |
| `HOMEPAGE_VAR_PORTAINER_API_KEY` | Portainer → your user → Access tokens |
| `HOMEPAGE_VAR_NPM_USER` / `_PASS` | NPM admin credentials |
| `HOMEPAGE_VAR_PLEX_TOKEN` | [How to find your Plex token](https://support.plex.tv/articles/204059436) |
| `HOMEPAGE_VAR_JELLYFIN_API_KEY` | Jellyfin → Dashboard → API Keys |

Widgets are optional — the dashboard works as a plain launcher without them.

### 7. Start the media stack

Get a Plex claim token from [plex.tv/claim](https://www.plex.tv/claim) (expires in 4 minutes) and set it in `stacks/media/.env`, then:

```bash
make media-up
```

Services started:
| Service | URL |
|---|---|
| Plex | `http://localhost:32400/web` |
| Jellyfin | `http://localhost:8096` |

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
    │       ├── portainer/
    │       ├── npm/
    │       └── duckdns/
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

**Permission errors on media files:** Check that `PUID`/`PGID` in `.env` match your Mac user (`id` command).

**NFS mount lost after reboot:** Add the mount to `/etc/fstab` as shown in the setup step above.

**Plex can't find media:** Verify the NFS mount is active (`ls /Volumes/media`) and that `TRUENAS_MEDIA_PATH` in `stacks/media/.env` points to the correct path.

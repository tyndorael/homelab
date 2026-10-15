# Unraid — storage + media

| Stack | Port(s) |
|---|---|
| `portainer-agent` | 9001 |
| `media` | Jellyfin 8096 · Sonarr 8989 · Radarr 7878 · Prowlarr 9696 · qBittorrent 8080, 6881 tcp/udp |

## Host preparation
1. **Settings → Docker**: enable Docker, use the default `docker.img`/directory on the **cache pool**.
2. Install the **Docker Compose Manager** plugin (Apps tab) — it provides `docker compose` on the CLI.
3. Create the `data` share (cache → array, "Move" via mover) with this layout:
   ```
   /mnt/user/data/torrents/{movies,tv}
   /mnt/user/data/media/{movies,tv}
   ```
   Torrents and media on the **same share** = instant hardlinks instead of copies.
4. Clone the repo onto the cache-backed `appdata` share so every `./config` bind mount lands there:
   ```bash
   cd /mnt/user/appdata && git clone <repo> homelab
   ```
   (Install git via the NerdTools / un-get plugin if it isn't available.)

## Start
```bash
cd /mnt/user/appdata/homelab
cp hosts/unraid/portainer-agent/.env.example hosts/unraid/portainer-agent/.env   # same AGENT_SECRET as the Pi
cp hosts/unraid/media/.env.example hosts/unraid/media/.env
make up HOST=unraid STACK=portainer-agent
make up HOST=unraid STACK=media
```
Without `make`, run `docker compose up -d` inside each stack folder.

## Notes
- Containers run as `nobody:users` (`99:100`) with `UMASK=002`, matching Unraid share permissions.
- In Sonarr/Radarr use `/data/media/...` as root folders and qBittorrent saves to `/data/torrents/...` — identical paths in every container, no remote path mappings needed.
- Consider routing qBittorrent through a VPN container (e.g. gluetun) before using public trackers.
- Back up `appdata` with the **Appdata Backup** plugin, or `scripts/backup.sh` (see [docs/backups.md](../../docs/backups.md)).

# Raspberry Pi — edge / control node

Runs the always-on, lightweight services: reverse proxy, Docker management and the dashboard.

## Hardware & OS
| | |
|---|---|
| Hostname | `cyrene` |
| IP | `192.168.50.106` (DHCP reservation) |
| Board | Raspberry Pi 4 Model B Rev 1.5 |
| CPU | 4 × Cortex-A72 (`aarch64`) |
| RAM | 8 GB (7.6 GiB usable) + 2 GB zram swap |
| Storage | **128 GB SanDisk microSD** (`mmcblk0`, root mounted `noatime`) — no SSD, by design |
| OS | Debian 13 (trixie), Raspberry Pi OS Lite 64-bit, kernel `6.12-rpi-v8` |
| Docker | Engine 29.1 · Compose v5.0 |

| Stack | Port(s) | URL |
|---|---|---|
| `nginx-proxy-manager` | 80, 443, 81 (admin) | `https://npm.<domain>` |
| `portainer` | 9443 | `https://portainer.<domain>` |
| `homepage` | 3000 | `https://home.<domain>` |

## Running from an SD card
The Pi boots and runs everything from the microSD card, so the setup minimises writes and keeps the card replaceable:
- **Card**: a reputable A2 / "High Endurance" card (current: SanDisk 128 GB). Keep a spare.
- **`noatime`** on `/` (already set) — no write per file read.
- **zram swap** (already active) instead of a swap file on the card.
- **Container log rotation**: every stack uses `json-file` with `max-size: 10m`, `max-file: 3`. Optionally set the same daemon-wide default in `/etc/docker/daemon.json`:
  ```json
  { "log-driver": "json-file", "log-opts": { "max-size": "10m", "max-file": "3" } }
  ```
  then `sudo systemctl restart docker`.
- **journald size cap**: `SystemMaxUse=50M` in `/etc/systemd/journald.conf` (or `Storage=volatile` to keep logs in RAM only).
- **Only light, low-write services here.** Databases, media, downloads and anything chatty belong on Unraid.
- **Backups matter more than on an SSD**: run `scripts/backup.sh raspberry-pi <stack> <unraid-share>` regularly (see [docs/backups.md](../../docs/backups.md)); after any big change, also image the whole card (e.g. `rpi-clone` or Raspberry Pi Imager's backup) so a dead card is a 10-minute swap.
- Watch for wear: `dmesg | grep -i mmc` errors or a read-only remount mean the card is failing.

## Host preparation (fresh card)
1. Flash **Raspberry Pi OS Lite (64-bit)** with Raspberry Pi Imager (set hostname, user, SSH key, Wi-Fi off/Ethernet).
2. DHCP reservation for the Pi on the router.
3. Harden SSH: key-only auth (`PasswordAuthentication no`), enable `unattended-upgrades`.
4. Install Docker and allow your user to run it:
   ```bash
   curl -fsSL https://get.docker.com | sh
   sudo usermod -aG docker $USER   # log out/in afterwards
   ```
5. Clone the repo: `git clone -b v2 https://github.com/tyndorael/homelab.git ~/homelab && cd ~/homelab`.

## First start
```bash
make network HOST=raspberry-pi                 # creates the shared `proxy` network (once)
for s in nginx-proxy-manager portainer homepage; do
  cp hosts/raspberry-pi/$s/.env.example hosts/raspberry-pi/$s/.env   # then edit each .env
done
make up HOST=raspberry-pi STACK=nginx-proxy-manager
make up HOST=raspberry-pi STACK=portainer
make up HOST=raspberry-pi STACK=homepage
```

Then:
- **NPM** (`http://<pi-ip>:81`): wildcard certificate `*.<domain>` via DNS challenge (DuckDNS today), one proxy host per service. Pi services are reachable by container name over the `proxy` network (`portainer:9443` https, `homepage:3000`) or by `192.168.50.106:<port>`; Unraid/Mac services by `LAN_IP:port`.
- **Portainer** (`https://<pi-ip>:9443`): *Environments → Add → Agent* for Unraid and the Mac mini (`<ip>:9001`), using the same `AGENT_SECRET`.
- Once everything is proxied by container name, set `ADMIN_BIND` / `PORTAINER_BIND` / `HOMEPAGE_BIND=127.0.0.1` so the raw ports are no longer exposed on the LAN.

## Migration log (2026-10-14)
NPM (2.16.0, 18 proxy hosts + DuckDNS wildcard cert) and Portainer (2.33.6 → 2.45.2) were moved from Docker volumes / `/opt/portainer/data` into `./data` and `./letsencrypt` of these stacks. The old volumes `npm_npm-data`, `npm_npm-letsencrypt` and `/opt/portainer/data` were left in place as a backup — remove them once you're happy:
```bash
docker volume rm npm_npm-data npm_npm-letsencrypt
sudo rm -rf /opt/portainer
```
Portainer still lists the old `npm` stack it used to manage; delete that stack entry in the UI (*Stacks → npm → Delete*) **after** confirming it no longer controls the running `nginx-proxy-manager` container.

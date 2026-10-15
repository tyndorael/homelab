# Raspberry Pi — edge / control node

Runs the always-on, lightweight services: reverse proxy, Docker management and the dashboard.

## Hardware & OS
| | |
|---|---|
| Hostname | `cyrene` |
| IP | `192.168.50.106` (DHCP reservation, Ethernet only — Wi-Fi disabled) |
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
| `adguard-home` | 53 tcp/udp, 3001 (setup), 8083 (UI) | `https://adguard.<domain>` |
| `glance` | 8084 | `https://glance.<domain>` |
| `tailscale` | host network (41641/udp) | tailnet node `cyrene`, subnet router for `192.168.50.0/24` |

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
- **Ethernet only**: Wi-Fi is disabled (`dtoverlay=disable-wifi` in `/boot/firmware/config.txt`, plus `nmcli radio wifi off`) so DNS/NPM always answer on `192.168.50.106`. The original config is kept as `config.txt.bak-20261014`.
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
for s in nginx-proxy-manager portainer homepage glance adguard-home tailscale; do
  cp hosts/raspberry-pi/$s/.env.example hosts/raspberry-pi/$s/.env   # then edit each .env
done
make up HOST=raspberry-pi STACK=nginx-proxy-manager
make up HOST=raspberry-pi STACK=portainer
make up HOST=raspberry-pi STACK=homepage
make up HOST=raspberry-pi STACK=glance
make up HOST=raspberry-pi STACK=adguard-home
make up HOST=raspberry-pi STACK=tailscale
```

Then:
- **NPM** (`http://<pi-ip>:81`): wildcard certificate `*.<domain>` via DNS challenge (DuckDNS today), one proxy host per service. Pi services are reachable by container name over the `proxy` network (`portainer:9443` https, `homepage:3000`) or by `192.168.50.106:<port>`; Unraid/Mac services by `LAN_IP:port`.
- **Portainer** (`https://<pi-ip>:9443`): *Environments → Add → Agent* for Unraid and the Mac mini (`<ip>:9001`), using the same `AGENT_SECRET`.
- **AdGuard Home**: see [AdGuard Home](#adguard-home) below.
- **Tailscale**: see [Tailscale](#tailscale) below.
- Once everything is proxied by container name, set `ADMIN_BIND` / `PORTAINER_BIND` / `HOMEPAGE_BIND=127.0.0.1` so the raw ports are no longer exposed on the LAN.

## Dashboards
- **Homepage** (`home.<domain>`) is the services panel: status, container stats and service widgets.
  Widget credentials go in `homepage/.env` (see `.env.example`) — use low-privilege accounts:
  - NPM: *Users → Add user* with **View Only** permissions → `NPM_USERNAME` / `NPM_PASSWORD`.
  - Portainer: *My account → Access tokens → Add* → `PORTAINER_KEY`; `PORTAINER_ENV` is the number in the local environment's URL.
  - AdGuard Home: `ADGUARD_USERNAME` / `ADGUARD_PASSWORD`.
  Then `make up HOST=raspberry-pi STACK=homepage`.
- **Glance** (`glance.<domain>`) is the personal start page: search, weather, calendar, r/selfhosted, r/homelab, Hacker News, selfh.st, release notes for the homelab apps and a service monitor. Edit `glance/config/glance.yml` — it reloads on save, no restart needed. It's stateless and runs read-only, so it never writes to the SD card.

## AdGuard Home
1. Open `http://192.168.50.106:3001` and run the wizard. Keep its defaults: admin UI on port **80** and DNS on **53** (container ports, published as 8083 and 53). Create the admin user.
2. The UI is then at `http://192.168.50.106:8083`. In NPM add `adguard.<domain>` → `adguard-home:80` (http).
3. *Filters → DNS rewrites*: add `*.<domain>` → `192.168.50.106` and `<domain>` → `192.168.50.106`. Every service name now resolves to NPM on the LAN.
4. *Settings → DNS settings*: upstreams e.g. `https://dns.cloudflare.com/dns-query` and `https://dns.quad9.net/dns-query`, enable *parallel requests* and the cache.
5. SD card: *Settings → General* → query log retention **24 h** (or keep it in memory only via *Query logs → Disable log* / anonymise), statistics **24 h–7 days**.
6. Router DHCP: primary DNS `192.168.50.106`, **secondary a public resolver** (e.g. `1.1.1.1`) so the internet keeps working if the Pi is down. (The secondary bypasses blocking when used; accept that trade-off or add a second AdGuard instance on Unraid later.)

The Pi itself keeps the router (`192.168.50.1`) as its resolver so Docker pulls and Tailscale never depend on a container that might be down.

## Tailscale
1. Admin console → *Settings → Keys → Generate auth key* (one-off, not reusable). Put it in `tailscale/.env` as `TS_AUTHKEY`, then `make up HOST=raspberry-pi STACK=tailscale`. (The browser-login link printed without a key is only valid for ~60 s before the container restarts with a new one, so the key is the reliable path.) After the node shows up, the key can be deleted from `.env`; the node key in `./data` is reused.
2. Admin console → *Machines → cyrene → Edit route settings* → approve `192.168.50.0/24`. Optionally *Disable key expiry* for this always-on node.
3. Remote DNS (optional): *DNS → Nameservers → Add → Custom* `192.168.50.106` with *Restrict to domain* `<domain>` (split DNS) — remote devices then resolve `*.<domain>` through AdGuard and reach NPM over the subnet route.
4. Clients on the LAN itself don't need routes: on Linux clients use `--accept-routes` only when away from home.

State lives in `tailscale/data` (node key); back it up with the other stacks. IPv4 forwarding is already enabled on the Pi (Docker does it); IPv6 forwarding is off, so only IPv4 LAN routes are advertised.

## Migration log (2026-10-14)
NPM (2.16.0, 18 proxy hosts + DuckDNS wildcard cert) and Portainer (2.33.6 → 2.45.2) were moved from Docker volumes / `/opt/portainer/data` into `./data` and `./letsencrypt` of these stacks. The old volumes `npm_npm-data`, `npm_npm-letsencrypt` and `/opt/portainer/data` were left in place as a backup — remove them once you're happy:
```bash
docker volume rm npm_npm-data npm_npm-letsencrypt
sudo rm -rf /opt/portainer
```
Portainer still lists the old `npm` stack it used to manage; delete that stack entry in the UI (*Stacks → npm → Delete*) **after** confirming it no longer controls the running `nginx-proxy-manager` container.

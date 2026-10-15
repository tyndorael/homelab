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
| `gatus` | 8085 | `https://status.<domain>` |
| `dozzle` | 8086 | `https://logs.<domain>` |
| `termix` (+ `guacd`) | 8087 | `https://termix.<domain>` |
| `rustdesk` | 21115–21117 (host network) | RustDesk clients → `192.168.50.106` |
| Cockpit (host, not a container) | 9090 | `https://cockpit.<domain>` |
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
5. Clone the repo: `git clone https://github.com/tyndorael/homelab.git ~/homelab && cd ~/homelab`.

## First start
```bash
make network HOST=raspberry-pi                 # creates the shared `proxy` network (once)
for s in nginx-proxy-manager portainer homepage glance gatus dozzle termix rustdesk adguard-home tailscale; do
  cp hosts/raspberry-pi/$s/.env.example hosts/raspberry-pi/$s/.env   # then edit each .env
done
make up HOST=raspberry-pi STACK=nginx-proxy-manager
make up HOST=raspberry-pi STACK=portainer
make up HOST=raspberry-pi STACK=homepage
make up HOST=raspberry-pi STACK=glance
make up HOST=raspberry-pi STACK=gatus
make up HOST=raspberry-pi STACK=dozzle      # after creating dozzle/data/users.yml (see Monitoring & logs)
make up HOST=raspberry-pi STACK=termix
make up HOST=raspberry-pi STACK=rustdesk
hosts/raspberry-pi/host/cockpit/install.sh <domain>   # Cockpit on the host (see Server admin)
make up HOST=raspberry-pi STACK=adguard-home
make up HOST=raspberry-pi STACK=tailscale
```

Then:
- **NPM** (`http://<pi-ip>:81`): wildcard certificate `*.<domain>` via DNS challenge (DuckDNS today), one proxy host per service. Pi services are reachable by container name over the `proxy` network (`portainer:9443` https, `homepage:3000`) or by `192.168.50.106:<port>`; Unraid/Mac services by `LAN_IP:port`.
- **Portainer** (`https://<pi-ip>:9443`): *Environments → Add → Agent* for Unraid and the Mac mini (`<ip>:9001`), using the same `AGENT_SECRET`.
- **AdGuard Home**: see [AdGuard Home](#adguard-home) below.
- **Tailscale**: see [Tailscale](#tailscale) below.
- Once everything is proxied by container name, set `ADMIN_BIND`, `PORTAINER_BIND`, `HOMEPAGE_BIND`, `GLANCE_BIND`, `ADGUARD_SETUP_BIND` and `ADGUARD_UI_BIND` to `127.0.0.1` and `make up` each stack, so the raw ports are no longer exposed on the LAN. **Done on cyrene (2026-10-14)**: from the LAN only 22 (SSH), 53 (DNS) and 80/443 (NPM) answer.

### Reaching an admin UI when NPM is down
The UIs still listen on the Pi's loopback, so tunnel them over SSH, e.g. NPM's admin:
```bash
ssh -L 8081:127.0.0.1:81 tyndorael@192.168.50.106    # then open http://localhost:8081
```
Same pattern for Portainer (`-L 9443:127.0.0.1:9443`, open `https://localhost:9443`), Homepage (`3000`), Glance (`8084`) and AdGuard (`8083`).

## Dashboards
- **Homepage** (`home.<domain>`) is the services panel: status, container stats and service widgets.
  Widget credentials go in `homepage/.env` (see `.env.example`) — use low-privilege accounts:
  - NPM: *Users → Add user* with **View Only** permissions → `NPM_USERNAME` / `NPM_PASSWORD`.
  - Portainer: *My account → Access tokens → Add* → `PORTAINER_KEY`; `PORTAINER_ENV` is the number in the local environment's URL.
  - AdGuard Home: `ADGUARD_USERNAME` / `ADGUARD_PASSWORD`.
  Then `make up HOST=raspberry-pi STACK=homepage`.
- **Glance** (`glance.<domain>`) is the personal start page: search, weather, calendar, homelab blogs (noted.lol, Jeff Geerling, ServeTheHome), Hacker News, Lobsters, selfh.st, release notes for the homelab apps and a service monitor. Edit `glance/config/glance.yml` — it reloads on save, no restart needed. It's stateless and runs read-only, so it never writes to the SD card.

## Monitoring & logs
- **Gatus** (`status.<domain>`) checks every service three ways: through NPM over HTTPS (also alerting on certificates with < 20 days left), directly on the `proxy` network, and DNS (local records, ad blocking, upstream), plus router, internet and Tailscale reachability. Checks live in `gatus/config/config.yaml` — edit, commit, `make up HOST=raspberry-pi STACK=gatus`. History is kept **in memory** (no SD writes) and resets on restart. Alerting is not configured yet; add an `alerting:` block (Telegram/ntfy/Discord) when wanted. Unraid/Mac checks are pre-written as comments.
- **Dozzle** (`logs.<domain>`) streams container logs, read-only (actions and shell disabled), through its own socket proxy. Logs can contain secrets, so it requires a login. Create the user file once on the Pi. The password is read silently and piped in, so it never lands in shell history (don't use `docker run -it … > users.yml`: with a TTY the prompt and errors end up inside the file):
  ```bash
  mkdir -p ~/homelab/hosts/raspberry-pi/dozzle/data
  read -rs -p "Dozzle password: " PW; echo
  printf '%s\n' "$PW" | docker run -i --rm amir20/dozzle:v11.3.2 generate <username> --name "<Your Name>" --email <you@example.com> \
    > ~/homelab/hosts/raspberry-pi/dozzle/data/users.yml; unset PW
  head -3 ~/homelab/hosts/raspberry-pi/dozzle/data/users.yml   # should start with "users:"
  ```
  **Other hosts** run a Dozzle agent (`hosts/<host>/dozzle-agent`) and are listed in `REMOTE_AGENTS` in `dozzle/.env` (today: the Mac mini, `192.168.50.206:7007|mac-mini`). Hub and agents share a **private certificate pair** so agents accept only this Dozzle (the image's built-in cert is the same for everyone). Create/rotate it on the Pi and copy it to each agent:
  ```bash
  mkdir -p ~/homelab/hosts/raspberry-pi/dozzle/data/certs
  docker run --rm -v ~/homelab/hosts/raspberry-pi/dozzle/data/certs:/out amir20/dozzle:v11.3.2 \
    generate-certs --cert-out /out/dozzle_cert.pem --key-out /out/dozzle_key.pem
  # copy both files to hosts/<host>/dozzle-agent/data/certs/ on each agent, then restart hub and agents
  ```
- NPM proxy hosts: `status.<domain>` → `gatus:8080`, `logs.<domain>` → `dozzle:8080` (enable **Websockets** for Dozzle).

## Server admin
- **Cockpit** (`cockpit.<domain>`) runs on the Pi **host** (Debian package, socket-activated: no RAM used until you open it). Log in with your Linux user. Installed and configured by [`host/cockpit/install.sh`](host/cockpit/install.sh): packages `cockpit`, `cockpit-networkmanager`, `cockpit-storaged` (no `cockpit-packagekit` — updates stay with apt/unattended-upgrades). It listens only on `127.0.0.1:9090` and the `proxy` network gateway (`172.19.0.1:9090`), never on the LAN. NPM proxy host: `cockpit.<domain>` → **https** `172.19.0.1:9090`, websockets on. If the `proxy` network is ever recreated, re-run the script (the gateway may change) and update NPM + `PROXY_GATEWAY` in `gatus/.env`.
- **Termix** (`termix.<domain>`) is browser SSH for every host. **Register immediately after the first start** — the first account becomes admin. Then add hosts: the Pi as `192.168.50.106:22` (user `tyndorael`, your SSH key), later Unraid and the Mac mini. NPM proxy host: `termix.<domain>` → `termix:8080`, websockets on.

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

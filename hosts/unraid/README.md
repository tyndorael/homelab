# Unraid (herta) — storage + media

| Stack | Port(s) |
|---|---|
| `portainer-agent` | 9001 |
| `dozzle-agent` | 7007 (logs show in `logs.<domain>`; cert pair in `dozzle-agent/data/certs`, copied from the Pi) |
| `media` | Jellyfin 8096 · Navidrome 4533 · Sonarr 8989 · Radarr 7878 · Prowlarr 9696 · qBittorrent 8080, 6881 tcp/udp |
| `immich` | 2283 (`photos.<domain>`), see [Photos (Immich)](#photos-immich) |
| `changedetection` | 5000 (`changes.<domain>`), see [Website watcher (changedetection.io)](#website-watcher-changedetectionio) |
| `homeassistant` VM | 80 (8123 redirects), 4357 on `192.168.50.217` (`br0`), see [Home Assistant OS VM](#home-assistant-os-vm) |

## Hardware — Dell Precision 5820 Tower
Previously `iono`, the Proxmox host of the `v1-proxmox` setup.

| Part | Detail | Unraid role / notes |
|---|---|---|
| CPU | Intel Xeon W-2133, 6C/12T, no iGPU | Docker, media stack, HAOS VM |
| RAM | 6 × 16 GB DDR4-2133 (DIMM1–6; DIMM7–8 empty), 96 GB | Plenty. Adding 2 × 16 GB fills all 4 channels evenly |
| GPU | NVIDIA GeForce RTX 3050 6 GB (GA107) | Jellyfin NVENC/NVDEC transcoding (H.264, HEVC, AV1 decode) via the **Nvidia Driver** plugin. Keep it for Docker, don't pass it through to a VM |
| NIC | Aquantia AQC107 10GBASE-T (RJ45) | `eth0`, to a 10G port on the GT-AXE16000, Cat6a |
| NIC | Intel I219-LM 1G (onboard) | Fallback / initial install |
| HDD | WD Red Plus 8 TB (WD80EFPX), CMR | Array **parity** |
| HDD | WD Red Plus 8 TB (WD80EFZZ), CMR | Array **disk 1** (XFS). Both Reds came from the old TrueNAS mirror, wiped |
| SSD | Micron M600 1 TB SATA | Pool `cache` (ZFS, single device): `appdata`, `system`, `domains` |
| HDD | WD Blue 1 TB (WD10EZEX) | Unused (old, small); optional disk 2 for scratch data |

No onboard M.2: an NVMe cache needs a PCIe adapter. That's the upgrade that lets the 10G link reach full speed; the SATA SSD tops out at about 4.4 Gbps.

## Before installing
**Router (GT-AXE16000)**
- If the internet plan is ≤ 2.5 Gbps, move the WAN to the 2.5G port so both 10G ports are LAN.
- After first boot, add a DHCP reservation for the AQC107's MAC address.
- Leave jumbo frames off.

**Back up the old Proxmox data.** The ZFS pool on the HDD and the VMs on the SSD are wiped by the install.

**BIOS (F2)**: update the BIOS first, then set:

| Setting | Value |
|---|---|
| System Configuration → SATA Operation | AHCI |
| Intel VMD (Storage / Slot settings) | Disabled: it hides NVMe drives behind the VMD RAID controller |
| Secure Boot | Off |
| Boot | UEFI, USB first |
| Virtualization Support | Virtualization + VT for Direct I/O on |
| Power Management → AC Recovery | Power On |
| Power Management → Deep Sleep Control | Disabled (needed for Wake-on-LAN) |
| Power Management → Wake on LAN | LAN Only |
| POST Behavior → Keyboard Errors | Disabled |
| POST Behavior → Warnings and Errors | Continue on Warnings and Errors |
| PCIe bifurcation | x4x4x4x4 only if a multi-M.2 card is added |

**Other**
- Run memtest86+ overnight and a SMART extended test on both drives.
- Write the USB stick (good 16–32 GB stick, e.g. SanDisk Cruzer Fit / Samsung Bar Plus) with the **Unraid USB Creator**, and boot from a rear USB 2.0 port.

**After first boot**
- **Settings → Network → Interface Rules**: make the AQC107 `eth0`.
- Install the **Nvidia Driver** plugin.
- Set a disk spin-down delay (e.g. 30 min) in **Settings → Disk Settings**.

## Web UI
NPM proxy host: `herta.<domain>` → `http://192.168.50.153:80`, websockets on, Force SSL on.

## Storage setup
Step-by-step UI guide (disks, pool, shares, Docker, VMs, plugins): **[SETUP.md](SETUP.md)**.

## Host preparation
1. **Settings → Docker**: enable Docker with data-root **directory** at `/mnt/user/system/docker/` (cache pool), see [SETUP.md](SETUP.md) part 5.
2. `docker compose`: the **official Compose CLI plugin**, kept on the flash drive and installed at boot by `/boot/config/go`. Install or upgrade with `hosts/unraid/host/docker-compose/install.sh <version>` (checksum-verified; currently **v5.6.0**). The *Docker Compose Manager* app is deprecated and hidden in Apps.
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
Deployed on herta 2026-10-17 from `/mnt/user/appdata/homelab` (cache, exclusive share).
```bash
cd /mnt/user/appdata/homelab && git pull
# .env files (gitignored): portainer-agent needs the Pi's AGENT_SECRET; dozzle-agent needs the
# Pi's Dozzle cert pair in data/certs; media uses DATA_ROOT=/mnt/user/data.
for s in portainer-agent dozzle-agent media immich changedetection; do (cd hosts/unraid/$s && docker compose up -d); done
```
Unraid has no `make`, so run `docker compose` inside each stack folder.

Media folders (owned `nobody:users`, `775`): `/mnt/user/data/{torrents,media}/{movies,tv}`.

Jellyfin uses the RTX 3050 through the nvidia runtime (NVENC H.264/HEVC verified). Enable it in *Dashboard → Playback → Transcoding → Hardware acceleration: NVIDIA NVENC*.

## Music (Navidrome)
Added 2026-10-17. [Navidrome](https://www.navidrome.org/) (GPL-3) streams `/mnt/user/data/media/audio` (read-only, rescanned hourly; music currently under `audio/Music`) and speaks the **Subsonic API**, so any Subsonic app works. Chosen over Jellyfin's music library: purpose-built for music, ~50 MB RAM, far more (and better) mobile clients.

1. Open `http://192.168.50.153:4533` and create the **admin** user on the first visit (password manager). Add a normal user per person in *Settings → Users*.
2. NPM proxy host `music.<domain>` → `http://192.168.50.153:4533`, wildcard cert, *Force SSL*, *HTTP/2*, websockets on.
3. Mobile apps, server `https://music.<domain>` + Navidrome user/password (works away from home over Tailscale):

   | Platform | App | |
   |---|---|---|
   | Android | **Tempus** (F-Droid / GitHub) | Free, open source, Material You, offline downloads |
   | Android | Symfonium | Paid (one-time, best-in-class), not open source |
   | iOS | **Amperfy** | Free, open source, offline, CarPlay |
   | iOS | play:Sub / substreamer | Free alternatives |
   | Desktop | Feishin | Open source; or just the web UI |

Drop new albums into `audio/Music/<Artist>/<Album>/` (tagged files; `Cover.jpg` is picked up as art). Trigger an immediate rescan from the web UI (*Activity* icon → *Quick scan*).

## Photos (Immich)
Added 2026-10-29. [Immich](https://immich.app/) v3.3.3 (AGPL-3): phone photo/video backup with face recognition, smart search and shared albums. Separate stack in [`immich/`](immich/compose.yaml), all four containers (server, machine learning, Valkey, Postgres) running as `nobody:users`.

| What | Where | Notes |
|---|---|---|
| Originals, encoded video, daily DB dumps | `/mnt/user/data/photos` (`UPLOAD_LOCATION`) | Array, parity. **Back this up off-site**: it's the only copy of your photos. Don't edit files here over SMB; Immich owns the layout |
| Postgres | `immich/data/postgres` | Cache SSD (network shares not supported) |
| Thumbnails | `immich/data/thumbs` | Cache SSD, regenerable; keeps the timeline fast while the array sleeps |
| ML models, Valkey | `immich/data/{model-cache,redis}` | Cache SSD, regenerable |

GPU: the RTX 3050 is shared with Jellyfin through the nvidia runtime. Machine learning uses the `-cuda` image; enable NVENC in *Administration → Settings → Video Transcoding → Hardware Acceleration*.

**First deploy** (as root on herta):
```bash
cd /mnt/user/appdata/homelab/hosts/unraid/immich
cp .env.example .env && sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=$(openssl rand -hex 24)/" .env
mkdir -p data/{postgres,thumbs,model-cache,redis} /mnt/user/data/photos
chown -R 99:100 data /mnt/user/data/photos
docker compose up -d
```
1. Open `http://192.168.50.153:2283` and create the **admin** account on the first visit (password manager). Add a user per person in *Administration → Users*.
2. NPM proxy host `photos.<domain>` → `http://192.168.50.153:2283`, wildcard cert, *Force SSL*, *HTTP/2*, websockets on. In the *Advanced* tab add the following, so large video uploads don't fail:
   ```nginx
   client_max_body_size 50000M;
   proxy_read_timeout 600s;
   proxy_send_timeout 600s;
   send_timeout 600s;
   ```
3. *Administration → Settings → Server → External domain*: `https://photos.<domain>` (used in shared links).
4. Mobile app (iOS / Android, F-Droid too): server `https://photos.<domain>`, then turn on *Backup* for the albums to upload. Works away from home over Tailscale.
5. Import an existing library (e.g. Google Takeout) with [immich-go](https://github.com/simulot/immich-go) and an API key from *Account settings → API keys*.

Upgrades: Immich ships breaking changes in minor releases. Read the release notes before bumping, and when a release changes the Postgres or Valkey image, copy the new digest from its `docker-compose.yml`.

## Website watcher (changedetection.io)
Added 2026-10-30. [changedetection.io](https://changedetection.io/) 0.60.9 (Apache-2.0) checks web pages on a schedule and notifies when they change: new products in a shop category, "Add to cart" appearing on an out-of-stock page, price drops. Stack in [`changedetection/`](changedetection/compose.yaml): the app (runs as `nobody:users`, state in `changedetection/data`) plus `sockpuppetbrowser`, a headless Chrome that renders JavaScript-heavy pages. The browser has no published port and is capped at 2 GB RAM.

**First deploy** (as root on herta):
```bash
cd /mnt/user/appdata/homelab/hosts/unraid/changedetection
cp .env.example .env   # set BASE_URL=https://changes.<domain>
mkdir -p data && chown 99:100 data
docker compose up -d
```
1. NPM proxy host `changes.<domain>` → `http://192.168.50.153:5000`, wildcard cert, *Force SSL*, *HTTP/2*, websockets on.
2. *Settings → General*: set a password (the UI is open by default).
3. *Settings → Notifications*: add an [Apprise URL](https://github.com/caronc/apprise/wiki), e.g. `ntfys://ntfy.sh/<long-random-topic>` (ntfy app on the phone, subscribe to the same topic) or `tgram://<bot-token>/<chat-id>`. Use *Send test notification*.
4. Add a watch per page. Useful settings for "new product" alerts:
   - *Request → Fetch method*: **Playwright Chromium** when the product list is rendered by JavaScript (the plain HTTP fetcher shows an empty list), otherwise the faster plain fetcher.
   - *Filters & Triggers → CSS/JSONPath filter*: only the product grid (e.g. `.product-grid`), or use the *Visual Filter Selector* to click it, so banners and timestamps don't trigger alerts.
   - *Filters & Triggers → Only trigger when unique lines appear*: alerts on products never seen before, not on reordering.
   - Or set the watch type to **Re-stock & price detection** for a single product page.
   - Check interval: hours, not minutes, to stay polite and avoid getting blocked.
## SMB
Only `data` is exported (Private, `tyndorael` Read/Write); macOS support (*fruit*), Bonjour and WSD discovery are on. Extra global settings live in [`host/samba/smb-extra.conf`](host/samba/smb-extra.conf), applied 2026-10-29:
```bash
cat hosts/unraid/host/samba/smb-extra.conf | ssh root@192.168.50.153 'cat > /boot/config/smb-extra.conf && testparm -s >/dev/null && smbcontrol smbd reload-config'
```
- `ntlm auth = ntlmv2-only` (Unraid's default still allows NTLMv1).
- `readdir_attr:aapl_max_access = no` and a few `fruit:` options: faster Finder listings in big folders like `media/movies`.
- Array writes use **reconstruct write** (*Settings → Disk Settings → md_write_method*), set 2026-10-29.
- Clients are 1 GbE (Mac mini) or Wi-Fi, so SMB tops out around 110 MB/s; multichannel and TCP tuning don't help until a client has 10 GbE.

On each Mac (optional): stop `.DS_Store` files on shares with `defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true`, and turn off client-side signing (faster) with `printf '[default]\nsigning_required=no\n' | sudo tee /etc/nsmb.conf`.

## Notes
- Containers run as `nobody:users` (`99:100`) with `UMASK=002`, matching Unraid share permissions.
- In Sonarr/Radarr use `/data/media/...` as root folders and qBittorrent saves to `/data/torrents/...` — identical paths in every container, no remote path mappings needed.
- Consider routing qBittorrent through a VPN container (e.g. gluetun) before using public trackers.
- Back up `appdata` with the **Appdata Backup** plugin, or `scripts/backup.sh` (see [docs/backups.md](../../docs/backups.md)).

## Home Assistant OS VM
Decided 2026-10-15: Home Assistant runs here as a **Home Assistant OS (HAOS) VM**, not on the Pi. HAOS keeps add-ons (Mosquitto, Zigbee2MQTT, ESPHome…), and its constant database writes stay off the Pi's SD card. Home Assistant Container was the alternative (no add-ons).

| | |
|---|---|
| VM | `homeassistant`, 2 vCPU, 4 GB RAM, Q35 + OVMF (UEFI) |
| Disk | `/mnt/user/domains/homeassistant/haos.qcow2`, 64 GB, VirtIO (cache pool) |
| Network | `br0`, `192.168.50.217` (DHCP reservation) → `HA_IP` |
| Ports | **80** web UI (8123 answers with a redirect to 80) · 4357 Observer (Supervisor health) |
| URL | `https://ha.<domain>` (NPM on the Pi) |

### 1. Prepare the disk (SSH, as root)
VMs must be enabled with `br0` as default network ([SETUP.md](SETUP.md) part 6). If `br0` is missing, set *Settings → Network → Enable bridging: Yes* (array stopped).
```bash
cd /mnt/user/appdata/homelab && git pull
hosts/unraid/host/homeassistant/prepare-disk.sh            # HAOS 18.3, checksum-verified, 64G
```
For a newer release pass `<version> <sha256>` (the `digest` of `haos_ova-<version>.qcow2.xz` on the GitHub release page). This only matters for a fresh install; HAOS updates itself afterwards.

### 2. Create the VM (SSH)
The VM definition is tracked in [`host/homeassistant/homeassistant.xml`](host/homeassistant/homeassistant.xml) (Unraid's own libvirt format, so it shows and edits normally in the **VMs** tab):

| Setting | Value |
|---|---|
| CPU | Host passthrough, 2 threads pinned to **5 / 11** (one core + its hyperthread; Unraid keeps core 0) |
| Memory | 4096 MB, no balloon |
| Machine / BIOS | Q35 / **OVMF** (HAOS only boots UEFI) |
| Disk | `haos.qcow2`, **VirtIO**, writeback, discard |
| Network | **br0**, virtio-net |
| USB | qemu XHCI (for dongles, step 6) · VNC console |

```bash
virsh define hosts/unraid/host/homeassistant/homeassistant.xml
virsh autostart homeassistant && virsh start homeassistant
virsh domiflist homeassistant          # MAC for the DHCP reservation
```
Created 2026-10-17: MAC `52:54:00:b6:ff:3f`, IP `192.168.50.217`.

### 3. First boot
1. The IP shows in the HAOS banner (VMs tab → `homeassistant` → **VNC Remote**) or `ip neigh show dev br0 | grep -i <mac>` on Unraid.
2. Router (GT-AXE16000): DHCP reservation for that MAC (the banner or VM *Edit* shows it). Write the IP into `docs/network.md` and `HA_IP` below.
3. Open `http://<ha-ip>/` (HAOS 18 serves the UI on port 80; `:8123` redirects there): setup downloads Core (a few minutes), then **Create my smart home** → owner account, location (Santiago), units metric, time zone `America/Santiago`. Store the password in the password manager.

### 4. Reverse proxy (NPM on the Pi)
1. NPM proxy host `ha.<domain>` → **`http://<ha-ip>:80`**, wildcard cert, *Force SSL*, *HTTP/2*, **Websockets support on** (HA's UI is a websocket app).
2. **Trust the Pi.** Since 2026.10 Home Assistant keeps its HTTP settings (port, proxies, SSL) in `.storage/http`, not in `configuration.yaml`: once `yaml_migration_done` is set, an `http:` block in YAML is **ignored**. Without the Pi in `trusted_proxies`, HA answers **400 Bad Request** through NPM and logs *"A request from a reverse proxy was received from 192.168.50.106…"*. Set (done 2026-10-17, from Unraid over the QEMU guest agent):
   ```json
   "stable": {
     "server_port": 80,
     "use_x_forwarded_for": true,
     "trusted_proxies": ["192.168.50.106"],
     …
   ```
   Prefer the UI if your version exposes these settings (*Settings → System → Network*). Otherwise edit the file with Core **stopped** (`ha core stop`, edit `/mnt/data/supervisor/homeassistant/.storage/http`, `ha core start`). The original is kept as `http.bak-20261017`.
   From Unraid, a command runs inside HAOS with `virsh qemu-agent-command homeassistant '{"execute":"guest-exec","arguments":{"path":"/bin/sh","arg":["-c","<cmd>"],"capture-output":true}}'` (then `guest-exec-status` with the returned pid; output is base64).
3. `https://ha.<domain>` now works, also away from home over Tailscale.

### 5. Monitoring (Pi)
Set `HA_IP=<ha-ip>` in the Pi's `gatus/.env`, `glance/.env` and `homepage/.env` (**required** in Gatus and Glance: they refuse to start without it). For the Homepage widget, create a non-admin HA user `homepage`, log in as it, *Profile → Security → Long-lived access tokens* → `HA_TOKEN` in `homepage/.env`. Then:
```bash
make up HOST=raspberry-pi STACK=gatus && make up HOST=raspberry-pi STACK=glance && make up HOST=raspberry-pi STACK=homepage
```
Gatus checks HA through NPM (*1. Web*) and directly, plus the Supervisor's Observer (*8. Home Assistant*). Dozzle/Portainer don't see it: HAOS's containers live inside the VM.

### 6. Radios: Bluetooth, Zigbee, Thread
The Pi's onboard Bluetooth can't reach a VM on another machine.
- **Bluetooth**: **ESPHome Bluetooth proxies** (ESP32 boards around the house; best range) or a USB Bluetooth adapter passed to the VM.
- **Zigbee / Thread**: a USB coordinator (e.g. SONOFF ZBDongle-E / Home Assistant Connect ZBT-1) on a **USB extension cable** away from the case and USB 3 ports. *VM → Edit → USB Devices*, tick it, **Update**; it reappears by vendor/product ID after reboots. Then the ZHA integration, or the Mosquitto + Zigbee2MQTT add-ons.

### 7. Backups
1. Unraid: **Add Share** `backups` (primary **Array**, no cache; SMB `Yes`, Security *Private*, user `tyndorael` Read/Write, see SETUP.md part 8). Create a dedicated Unraid user `homeassistant` with Read/Write on it rather than reusing yours.
2. HA: *Settings → System → Storage → Add network storage* → Usage **Backup**, Server `192.168.50.153`, Protocol Samba/Windows, Share `backups`, the user above.
3. *Settings → System → Backups → Configure automatic backups*: daily, keep 7, location the network storage (and local). **Save the backup encryption key** to the password manager: restores are impossible without it.
4. The vdisk itself is not backed up by *Appdata Backup*; HA's own backups are what you restore from (fresh VM from step 1–2, then *Restore from backup* on the onboarding screen).

### Notes
- Updates (OS, Supervisor, Core, add-ons) happen in *Settings → Updates*; take a backup first (it's the default). Renovate doesn't track the VM.
- 4 GB RAM is plenty for HA + a few add-ons; raise it if heavier add-ons come later. The RTX 3050 stays with Docker (Jellyfin), never passed to this VM.
- Stopping the array or rebooting Unraid shuts the VM down first; HAOS handles the ACPI shutdown cleanly.

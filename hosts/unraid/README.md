# Unraid — storage + media

| Stack | Port(s) |
|---|---|
| `portainer-agent` | 9001 |
| `media` | Jellyfin 8096 · Sonarr 8989 · Radarr 7878 · Prowlarr 9696 · qBittorrent 8080, 6881 tcp/udp |

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

## Planned: Home Assistant OS VM
Decided 2026-10-15: Home Assistant runs here as a **Home Assistant OS VM**, not on the Pi. HAOS keeps add-ons (Mosquitto, Zigbee2MQTT, ESPHome…), and its constant database writes stay off the Pi's SD card. Home Assistant Container on the Pi was the alternative (it meets the requirements, but has no add-ons and would wear the card).

When Unraid is up:
1. **Settings → VM Manager**: enable VMs (libvirt image on the cache pool).
2. Download the HAOS **`generic-x86-64` KVM image** (`haos_ova-<version>.qcow2.xz`) from the Home Assistant releases, extract it into the `domains` share, e.g. `/mnt/user/domains/homeassistant/haos.qcow2`.
3. New VM, template **Linux**: BIOS **OVMF (UEFI)**, machine Q35, 2 vCPU, 4 GB RAM, primary vDisk = the qcow2 above (bus **VirtIO** or SATA), network **br0** so it gets its own LAN IP (DHCP reservation on the router).
4. Autostart the VM. Then `ha.<domain>` in NPM → `http://<ha-ip>:8123` (websockets on), and in Home Assistant `configuration.yaml`:
   ```yaml
   http:
     use_x_forwarded_for: true
     trusted_proxies:
       - 192.168.50.106   # the Pi (NPM)
   ```
5. **Bluetooth**: the Pi's onboard chip can't be used by a VM on another machine. Use either a **USB Bluetooth adapter** passed through to the VM (VM settings → USB devices), or **ESPHome Bluetooth proxies** (cheap ESP32 boards placed around the house; best range). Same for Zigbee/Thread: pass a USB coordinator through to the VM.
6. Add checks/entries: Gatus (`https://ha.<domain>/`), Homepage (`homeassistant` widget with a long-lived token), Glance monitor.
7. Backups: HAOS's own backups to a Samba/NFS share on Unraid (Settings → System → Backups → network storage), plus the VM vdisk in the regular Unraid backup.

# herta — Unraid storage setup, step by step

Written for Unraid **7.3.3** on the Dell Precision 5820 (`192.168.50.153`). Follow the parts in order: each one says what to click, what to choose and what you should see afterwards.

**Target layout**

| Device | Model / serial | Role | File system |
|---|---|---|---|
| Parity | WD Red Plus 8 TB `WD80EFPX` · **RD07AGGE** | protects the array | — |
| Disk 1 | WD Red Plus 8 TB `WD80EFZZ` · **CA3KD0EL** | data | XFS |
| Pool `cache` | Micron M600 1 TB · **15170F67663F** | appdata, Docker, VMs, new downloads | ZFS |
| Flash | SanDisk USB stick | Unraid OS + config | (FAT32) |

The **format** step (part 4) erases disk 1 and the Micron. The Micron still holds the old Proxmox install, which is expected to go.

**Finding pages.** The top menu has *Main · Shares · Users · Settings · Plugins · Docker · VMs · Apps · Tools*. In a narrow window it collapses into a **☰** icon. Every page below also has a direct link.

---

## Part 0 — Before you start (5 min)
1. Open `http://192.168.50.153` and log in as `root`.
2. Confirm the top-right shows **Trial** with days left. If it asks you to start the trial or sign in, do that first.
3. **Settings → Date and Time** (`/Settings/DateTime`): time zone `America/Santiago`, NTP on. *(Already set.)*
4. **Settings → Identification** (`/Settings/Identification`): server name `herta`, description `Dell Precision 5820`. **Apply**.

## Part 1 — Disk settings (array still stopped)
**Settings → Disk Settings** (`/Settings/DiskSettings`)

| Field | Set to | Why |
|---|---|---|
| Enable auto start | **Yes** | the array starts by itself after a power cut |
| Default file system | **xfs** | already set |
| Default spin down delay | **30 minutes** | HDDs sleep when idle (currently *Never*) |
| Default warning / critical disk utilization | 90 / 95 % | leave defaults |
| Tunable (enable NCQ / md_write_method) | leave defaults | |

Click **Apply**.

## Part 2 — Global share settings
**Settings → Global Share Settings** (`/Settings/ShareSettings`)

| Field | Set to |
|---|---|
| Enable user shares | Yes |
| Permit exclusive shares | **Yes** (already set). Shares that live only on one pool skip the user-share layer, which is faster for Docker/VMs |
| Included / excluded disks | All / None |
| Tunable (support hard links) | **Yes**. The media stack needs hardlinks between `torrents/` and `media/` |

Click **Apply**.

## Part 3 — Assign the disks
Go to **Main** (`/Main`). The *Array Devices* table has slots **Parity**, **Parity 2**, **Disk 1**, **Disk 2**…

1. **Parity** dropdown → choose `WDC_WD80EFPX-…_WD-RD07AGGE`.
2. **Disk 1** dropdown → choose `WDC_WD80EFZZ-…_WD-CA3KD0EL`.
3. Leave **Parity 2** and **Disk 2+** as *no device*.
4. Click the blue word **Disk 1** (the slot name) → **File system type: `xfs`** → **Apply** → **Done**.

Create the pool, under *Pool Devices* further down:

5. Click **Add Pool** → Name `cache` → Number of slots `1` → **Add**.
6. In the new `cache` row, choose `Micron_M600_MTFDDAK1T0MBF_15170F67663F`.
7. Click the blue word **cache** → set:
   - **File system type:** `zfs`
   - **Compression:** `on`
   - Leave *Autotrim* `on` and *Enable user share assignment* `yes`.
   - **Apply** → **Done**.

**Check before continuing:** Parity = RD07AGGE, Disk 1 = CA3KD0EL, cache = Micron. Nothing else assigned. Under *Unassigned Devices* there's only the DVD drive and the SD card reader.

## Part 4 — Start the array and format
1. At the bottom of **Main**, *Array Operation* section → click **Start**.
2. After a few seconds **Disk 1** and **cache** show **"Unmountable: Unsupported or no file system"**. This is expected for new or foreign disks.
3. Next to the **Format** button, read the list of devices it will format. It must say exactly **disk1** and **cache**.
4. Tick **Yes, I want to do this** → **Format** → confirm.
5. After 1–2 minutes both show a size and free space (disk1 ≈ 8 TB, cache ≈ 1 TB), and **Parity-Sync** starts automatically.

**Parity sync** takes **about 15–20 h** for 8 TB. During it:
- You can keep setting up (parts 5–9) and use the server. Everything is just slower.
- **Don't** stop the array, reboot or power off. If that happens, it restarts from zero.
- Progress: *Main → Array Operation* (`/Main`), shows speed and ETA.

## Part 5 — Docker
**Settings → Docker** (`/Settings/DockerSettings`)

| Field | Set to |
|---|---|
| Enable Docker | **Yes** |
| Docker data-root | **directory** (no fixed-size image to fill up). Path `/mnt/user/system/docker/` |
| Default appdata storage location | `/mnt/user/appdata/` |
| Docker LOG rotation | **Yes**, max size `10` MB, files `3` (same as the repo's compose files) |
| Template authoring mode / custom networks | leave defaults |

Click **Apply**. The **Docker** tab now appears, and so do the shares `appdata` and `system`.

## Part 6 — VMs
**Settings → VM Manager** (`/Settings/VMSettings`)

| Field | Set to |
|---|---|
| Enable VMs | **Yes** |
| Libvirt storage location | `/mnt/user/system/libvirt/libvirt.img` (default) |
| Default VM storage path | `/mnt/user/domains/` |
| Default ISO storage path | `/mnt/user/isos/` |
| Default network source | **br0** (VMs get their own LAN IP, needed for Home Assistant) |

Click **Apply**. The shares `domains` and `isos` appear.

## Part 7 — Shares
Open **Shares** (`/Shares`). For each share click its name, set the fields and click **Apply**.

**`appdata`**, **`system`**, **`domains`**: these hold container configs, the Docker data and VM disks.

| Field | Set to |
|---|---|
| Primary storage | **cache** |
| Secondary storage | **None** |
| Export (SMB) | `No` (`appdata`: optionally *Yes / Hidden / Private* to edit configs from the Mac) |

The share should then show **Exclusive access: Yes**.

**`isos`**

| Field | Set to |
|---|---|
| Primary storage | **Array** |
| Secondary storage | None |

**`data`**: media library and downloads. Create it with **Add Share**:

| Field | Set to |
|---|---|
| Share name | `data` (exactly; the repo's media stack expects `/mnt/user/data`) |
| Primary storage | **cache** |
| Minimum free space | `50GB`. When the cache has less, new files go straight to the array |
| Secondary storage | **Array** |
| Allocation method | High-water |
| Split level | Automatically split any directory as required |
| Mover action | **cache → Array** |
| Export (SMB) | `Yes`, Security `Private` (see part 8) |

Click **Add Share**.

## Part 8 — A user for SMB (optional, to browse `data` from the Mac/PC)
1. **Users** (`/Users`) → **Add User** → name `tyndorael`, password → **Add**.
2. **Shares → data → SMB Security Settings** → user `tyndorael` = **Read/Write** → **Apply**.
3. On the Mac: Finder → *Go → Connect to Server* → `smb://192.168.50.153/data`.

## Part 9 — Mover, plugins, notifications
**Settings → Scheduler** (`/Settings/Scheduler`)
- **Mover schedule:** Daily, `03:40` (already set). **Apply**.

**Apps** (`/Apps`). Search and **Install** each:

| Plugin | Why |
|---|---|
| **Nvidia Driver** (ich777) | RTX 3050 for Jellyfin. After install open *Settings → Nvidia Driver*, keep *latest production*, then **reboot after parity sync finishes** |
| **Docker Compose Manager** | `docker compose` on the CLI, used by this repo |
| **Unassigned Devices** + **Unassigned Devices Plus** | mount USB drives and shares outside the array |
| **Fix Common Problems** | scans for misconfigurations. Run it once at the end and read its warnings |
| **Appdata Backup** | scheduled backup of `appdata` (configure later) |

**Settings → Notification Settings** (`/Settings/Notifications`): enable browser notifications. Parity errors and disk SMART warnings appear there.

## Part 10 — Back up the flash drive
**Main → Flash** (click *Flash*) → **Flash Backup** → download the zip and keep it off the server. Redo after big config changes.

## Part 11 — Final checks
- **Main:** parity, disk1 and cache are green; Parity-Sync is running or finished.
- **Shares:** `appdata`, `system`, `domains` on *cache* (Exclusive: Yes); `isos` on *Array*; `data` on *cache → Array*.
- **Docker** and **VMs** tabs are visible.
- Homepage's Unraid widget shows **Started**, array free ≈ 8 TB and cache free ≈ 1 TB.

Then tell Claude it's done. The next steps run over SSH:
1. Verify all of the above.
2. Create `/mnt/user/data/{torrents,media}/{movies,tv}`.
3. Clone the repo to `/mnt/user/appdata/homelab`.
4. Deploy the Portainer agent and the media stack (Jellyfin on the RTX 3050).
5. Add Unraid to NPM, Gatus, Dozzle and Homepage.

## If something looks wrong
| Symptom | Fix |
|---|---|
| A disk is missing from the dropdowns | Check its SATA/power cable; *Tools → System Devices* should list it |
| Format list shows a device other than disk1/cache | **Don't format.** Stop, recheck the assignments |
| Disk shows a red ✖ or "disabled" | Stop. Check cables and SMART (*click the disk → Self-Test / Attributes*) before anything else |
| Parity sync very slow (< 80 MB/s) | Normal at the end of the disk (inner tracks); otherwise check that nothing heavy is copying |
| Can't find a menu | Widen the window or use the ☰ icon, or the direct links above |

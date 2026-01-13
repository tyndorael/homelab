# Media Players Stack Setup Guide

This guide covers the deployment and configuration of Plex, Jellyfin, and Navidrome media servers in your homelab environment.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Architecture](#architecture)
- [Directory Structure](#directory-structure)
- [Initial Setup](#initial-setup)
- [Plex Configuration](#plex-configuration)
- [Jellyfin Configuration](#jellyfin-configuration)
- [Navidrome Configuration](#navidrome-configuration)
- [Hardware Transcoding](#hardware-transcoding)
- [Reverse Proxy Setup](#reverse-proxy-setup)
- [Troubleshooting](#troubleshooting)

---

## Overview

This stack provides three media server solutions:

### Plex Media Server
- **Purpose**: Commercial media streaming platform with excellent client support
- **Port**: 32400 (web UI)
- **Network Mode**: Bridge (for Nginx Proxy Manager compatibility)
- **Best For**: Users who want polished clients and easy sharing

### Jellyfin
- **Purpose**: Open-source media server, completely free
- **Port**: 8096 (HTTP), 8920 (HTTPS)
- **Network Mode**: Bridge (can be reverse proxied)
- **Best For**: Privacy-conscious users, no premium features locked

### Navidrome
- **Purpose**: Modern music server and streamer with Subsonic API
- **Port**: 4533
- **Network Mode**: Bridge
- **Best For**: Dedicated music streaming with mobile app support

### Storage Architecture
- **Config Storage**: NFS shared storage (`/nfs/vm_shares/cyrene/apps/`)
- **Media Files**: CIFS/SMB mount (`/mnt/media/`)
- **Benefits**: Centralized config backup, shared media library

---

## Prerequisites

### 1. NFS Share
Ensure NFS is configured and mounted (from `setup-homelab.sh`):
```bash
# Verify NFS mount
df -h | grep cyrene
```

### 2. CIFS Media Share
Configure CIFS/SMB mount for media files:
```bash
# Run the CIFS setup script
sudo bash setup-cifs-media.sh

# Verify CIFS mount
df -h | grep media
ls -la /mnt/media
```

Expected media structure:
```
/mnt/media/
├── tv/         # TV Shows
├── movies/     # Movies
├── music/      # Music
├── books/      # Audiobooks/Ebooks
└── downloads/  # Downloads from *arr apps
```

### 3. Directory Preparation
Create necessary directories on NFS share:
```bash
# Plex directories
sudo mkdir -p /nfs/vm_shares/cyrene/apps/plex/{config,transcode}
sudo chown -R 1000:1000 /nfs/vm_shares/cyrene/apps/plex
sudo chmod -R 755 /nfs/vm_shares/cyrene/apps/plex

# Jellyfin directories
sudo mkdir -p /nfs/vm_shares/cyrene/apps/jellyfin/{config,cache}
sudo chown -R 1000:1000 /nfs/vm_shares/cyrene/apps/jellyfin
sudo chmod -R 755 /nfs/vm_shares/cyrene/apps/jellyfin
```

**Navidrome:**
```bash
sudo mkdir -p /nfs/vm_shares/cyrene/apps/navidrome
sudo chown -R 1000:1000 /nfs/vm_shares/cyrene/apps/navidrome
sudo chmod -R 755 /nfs/vm_shares/cyrene/apps/navidrome
```

### 4. Firewall Configuration
Open required ports:
```bash
# Plex
sudo ufw allow 32400/tcp comment 'Plex Media Server'

# Jellyfin
sudo ufw allow 8096/tcp comment 'Jellyfin HTTP'
sudo ufw allow 8920/tcp comment 'Jellyfin HTTPS'

# Navidrome
sudo ufw allow 4533/tcp comment 'Navidrome'

# Optional: Discovery protocols
sudo ufw allow 7359/udp comment 'Jellyfin Discovery'
sudo ufw allow 1900/udp comment 'DLNA Discovery'

# Verify
sudo ufw status
```

---

## Architecture

### Network Design
```
┌─────────────────────────────────────────────────────────┐
│                    Internet / LAN                        │
└────────────────────┬────────────────────────────────────┘
                     │
          ┌──────────▼──────────┐
          │  Nginx Proxy Mgr    │ (ports 80/443)
          │  (Different VM)     │
          └──────────┬──────────┘
                     │
        ┌────────────┴──────────────┬──────────────┐
        │                           │              │
   ┌────▼────┐              ┌──────▼─────┐  ┌─────▼──────┐
   │  Plex   │              │  Jellyfin  │  │ Navidrome  │
   │ (32400) │              │   (8096)   │  │   (4533)   │
   │ bridge  │              │   bridge   │  │   bridge   │
   └────┬────┘              └──────┬─────┘  └─────┬──────┘
        │                          │              │
        └────────────┬─────────────┴──────────────┘
                     │
        ┌────────────▼──────────────┐
        │     Media Storage         │
        │  /mnt/media (CIFS/SMB)    │
        │  - tv/                    │
        │  - movies/                │
        │  - music/                 │
        │  - music/                 │
        │  - books/                 │
        └───────────────────────────┘
```

### Storage Mapping
| Service   | Config Location                         | Media Location        |
|-----------|----------------------------------------|-----------------------|
| Plex      | /nfs/vm_shares/cyrene/apps/plex/        | /mnt/media (read-only)|
| Jellyfin  | /nfs/vm_shares/cyrene/apps/jellyfin/    | /mnt/media (read-only)|

---

## Initial Setup

### 1. Environment Variables (Optional)
Create `.env` file in the stack directory:
```bash
cd stacks/media-players

cat > .env << 'EOF'
# Plex Claim Token (get from https://www.plex.tv/claim/)
# Valid for 4 minutes, used for initial setup only
PLEX_CLAIM=claim-xxxxxxxxxxxxxxxxxxxx

# Jellyfin Public URL (for reverse proxy)
JELLYFIN_URL=https://jellyfin.yourdomain.com
EOF
```

### 2. Deploy the Stack

**Option A: Using Portainer**
1. Navigate to Portainer UI
2. Go to **Stacks** → **Add Stack**
3. Name: `media-players`
4. Upload `media-players-stack.yml` or paste contents
5. Add environment variables if needed
6. Click **Deploy the stack**

**Option B: Using Docker Compose**
```bash
cd stacks/media-players
docker compose -f media-players-stack.yml up -d
```

### 3. Verify Deployment
```bash
# Check container status
docker ps | grep -E "plex|jellyfin"

# Check logs
docker logs plex
docker logs jellyfin

# Verify media mount
docker exec plex ls -la /media
docker exec jellyfin ls -la /media
```

---

## Plex Configuration

### Initial Setup

1. **Access Plex Web UI**
   ```
   http://YOUR_SERVER_IP:32400/web
   ```

2. **Sign In / Create Account**
   - Use your Plex account or create a new one
   - If you used `PLEX_CLAIM` token, server should be auto-claimed

3. **Server Settings**
   - Navigate to **Settings** → **Server**
   - Set a friendly name for your server

### Library Setup

1. **Add Movie Library**
   - Click **Add Library** → **Movies**
   - Click **Browse for Media Folder**
   - Navigate to `/media/movies`
   - Click **Add Library**

2. **Add TV Shows Library**
   - Click **Add Library** → **TV Shows**
   - Browse to `/media/tv`
   - Click **Add Library**

3. **Add Music Library** (Optional)
   - Click **Add Library** → **Music**
   - Browse to `/media/music`
   - Click **Add Library**

4. **Add Other Libraries** (Optional)
   - Audiobooks: `/media/books`
   - Photos, etc.

### Recommended Settings

**Network Settings:**
- Settings → Network → Custom server access URLs
  - Add your domain if using reverse proxy

**Transcoder Settings:**
- Settings → Transcoder
  - Transcoder temporary directory: `/transcode`
  - Transcoder quality: Automatic
  - Enable hardware transcoding if available

**Library Settings:**
- Settings → Library
  - Enable "Scan my library automatically"
  - Enable "Run a partial scan when changes are detected"

---

## Jellyfin Configuration

### Initial Setup

1. **Access Jellyfin Web UI**
   ```
   http://YOUR_SERVER_IP:8096
   ```

2. **First-Time Setup Wizard**
   - Set preferred display language
   - Create admin user account
   - Set up media libraries (next step)

### Library Setup

1. **Add Movie Library**
   - Dashboard → Libraries → **Add Media Library**
   - Content type: **Movies**
   - Display name: `Movies`
   - Folders: Click **+** and add `/media/movies`
   - Click **OK**

2. **Add TV Shows Library**
   - Content type: **Shows**
   - Display name: `TV Shows`
   - Folders: `/media/tv`
   - Click **OK**

3. **Add Music Library** (Optional)
   - Content type: **Music**
   - Display name: `Music`
   - Folders: `/media/music`
   - Click **OK**

4. **Scan Libraries**
   - Dashboard → Libraries
   - Click **Scan All Libraries**

### Recommended Settings

**Playback Settings:**
- Dashboard → Playback
  - Enable hardware acceleration (if configured)
  - Set transcoding thread count

**Networking:**
- Dashboard → Networking
  - Public HTTP port: 8096
  - Public HTTPS port: 8920
  - Known proxies: Add your Nginx Proxy Manager VM IP
  - Enable automatic port mapping if using UPnP

**Library Settings:**
- Dashboard → Libraries → Library Options
  - Enable real-time monitoring
  - Enable automatic metadata download

---

## Navidrome Configuration

### Initial Setup

1. **Access Navidrome Web UI**
   ```
   http://YOUR_SERVER_IP:4533
   ```

2. **Create Admin Account**
   - On first access, you'll be prompted to create an admin user
   - Username: Choose your admin username
   - Password: Set a strong password
   - Name: Display name
   - Click **Create Admin**

### Music Library Setup

**Automatic Scanning:**
- Navidrome automatically scans `/music` directory (mounted from `/mnt/media/music`)
- Default scan interval: 1 hour (configurable in docker-compose)
- Initial scan happens on first startup

**Manual Scan:**
1. Click your username → **Settings**
2. Scroll to **Advanced** section
3. Click **Rescan Now** to force an immediate scan

### Recommended Settings

**User Settings** (Click username → Settings):

1. **Language & Region:**
   - Display Language: Select your preference
   - Default Language: Select for search/metadata

2. **Transcoding:**
   - Max Bit Rate: Set based on your upload speed (for remote streaming)
   - Default: 128 Kbps (mobile), 320 Kbps (desktop)

3. **Last.fm Scrobbling:**
   - Connect Last.fm account (optional)
   - Username: Your Last.fm username
   - Password: Your Last.fm password
   - Click **Link**

4. **ListenBrainz:**
   - Alternative to Last.fm (optional)
   - Enter ListenBrainz token
   - Click **Save**

**Admin Settings** (Settings → Advanced):

1. **Library:**
   - Music Folder: `/music` (default, should match mount)
   - Scan Interval: `1h` (hourly)
   - Enable Folder-based Playlists: ✓

2. **Transcoding:**
   - Enable transcoding: ✓
   - Transcoding Cache Size: 100 MB (adjust based on disk space)

### Mobile App Setup

Navidrome is compatible with many Subsonic-compatible apps:

**Recommended Apps:**
- **Android**: 
  - Symfonium (paid, best UI)
  - DSub (free, feature-rich)
  - Ultrasonic (free, open-source)
  
- **iOS**:
  - play:Sub (paid, excellent UI)
  - Amperfy (free, open-source)
  - substreamer (paid)

**Connection Settings:**
```
Server URL: http://YOUR_SERVER_IP:4533
  or: https://navidrome.yourdomain.com (with reverse proxy)
Username: Your Navidrome username
Password: Your Navidrome password
```

**Legacy Authentication Token:**
- If app requires token authentication
- Settings → User → Generate New Token
- Use token instead of password

### Music Library Organization

**Recommended Folder Structure:**
```
/mnt/media/music/
├── Artist Name/
│   ├── Album Name (Year)/
│   │   ├── 01 - Track.mp3
│   │   ├── 02 - Track.mp3
│   │   └── cover.jpg
│   └── Another Album (Year)/
└── Various Artists/
    └── Compilation Album (Year)/
```

**Supported Formats:**
- FLAC (lossless, recommended)
- MP3
- M4A/AAC
- OGG/Vorbis
- OPUS
- WMA

**Metadata:**
- Navidrome reads tags from audio files
- Embedded album art supported
- Separate `cover.jpg` files also work

### Features

**Smart Playlists:**
1. Go to **Playlists**
2. Click **+ New Smart Playlist**
3. Set criteria (genre, year, rating, etc.)
4. Auto-updates based on library changes

**Radio Mode:**
- Similar Songs: Based on current track
- Artist Radio: Songs by similar artists
- Available from any playing track

**Sharing:**
1. Right-click album/song
2. Select **Share**
3. Get public share link (optional password)
4. Set expiration time

**Podcasts:**
- Settings → Podcasts
- Add Podcast → Enter RSS feed URL
- Auto-downloads new episodes

---

## Hardware Transcoding

Hardware transcoding significantly improves performance and reduces CPU usage.

### Intel Quick Sync Video (QSV)

1. **Enable in Docker Compose**
   Uncomment in `media-players-stack.yml`:
   ```yaml
   devices:
     - /dev/dri:/dev/dri
   ```

2. **Verify Device Access**
   ```bash
   # Check if device exists
   ls -la /dev/dri
   
   # Verify permissions
   docker exec jellyfin ls -la /dev/dri
   docker exec plex ls -la /dev/dri
   ```

3. **Configure in Plex**
   - Settings → Transcoder
   - Enable "Use hardware acceleration when available"

4. **Configure in Jellyfin**
   - Dashboard → Playback → Transcoding
   - Hardware acceleration: **Intel QuickSync (QSV)**

### NVIDIA GPU

1. **Install NVIDIA Container Toolkit**
   ```bash
   # Add repository
   distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
   curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
   curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
       sudo tee /etc/apt/sources.list.d/nvidia-docker.list
   
   # Install
   sudo apt-get update
   sudo apt-get install -y nvidia-container-toolkit
   sudo systemctl restart docker
   ```

2. **Enable in Docker Compose**
   Uncomment in `media-players-stack.yml`:
   ```yaml
   devices:
     - /dev/nvidia0:/dev/nvidia0
     - /dev/nvidiactl:/dev/nvidiactl
     - /dev/nvidia-modeset:/dev/nvidia-modeset
     - /dev/nvidia-uvm:/dev/nvidia-uvm
   ```

3. **Configure in Applications**
   - Similar to Intel QSV, but select NVIDIA NVENC option

---

## Reverse Proxy Setup

### Jellyfin (Recommended)

Jellyfin works better behind a reverse proxy than Plex.

**Nginx Proxy Manager Configuration:**

1. Navigate to Nginx Proxy Manager UI (port 81) on your other VM
2. **Hosts** → **Proxy Hosts** → **Add Proxy Host**

**Details Tab:**
- Domain Names: `jellyfin.yourdomain.com`
- Scheme: `http`
- Forward Hostname/IP: `YOUR_MEDIA_VM_IP` (IP address of this VM)
- Forward Port: `8096`
- ✅ Cache Assets
- ✅ Block Common Exploits
- ✅ Websockets Support

**SSL Tab:**
- ✅ Force SSL
- SSL Certificate: Request new Let's Encrypt certificate
- ✅ HTTP/2 Support

**Advanced Tab (Optional):**
```nginx
# Increase client body size for large uploads
client_max_body_size 0;

# Proxy headers
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Forwarded-Host $host;
```

### Plex (Advanced)

Plex works well behind a reverse proxy in bridge mode.

**Details Tab:**
- Domain Names: `plex.yourdomain.com`
- Scheme: `http`
- Forward Hostname/IP: `YOUR_MEDIA_VM_IP` (IP address of this VM)
- Forward Port: `32400`
- ✅ Websockets Support

**Advanced Tab:**
```nginx
# Plex-specific headers
proxy_set_header X-Plex-Client-Identifier $http_x_plex_client_identifier;
proxy_set_header X-Plex-Device $http_x_plex_device;
proxy_set_header X-Plex-Device-Name $http_x_plex_device_name;
proxy_set_header X-Plex-Platform $http_x_plex_platform;
proxy_set_header X-Plex-Platform-Version $http_x_plex_platform_version;
proxy_set_header X-Plex-Product $http_x_plex_product;
proxy_set_header X-Plex-Token $http_x_plex_token;
proxy_set_header X-Plex-Version $http_x_plex_version;

# Size limits
client_max_body_size 0;
```

### Navidrome

**Nginx Proxy Manager Configuration:**

1. **Hosts** → **Proxy Hosts** → **Add Proxy Host**

**Details Tab:**
- Domain Names: `navidrome.yourdomain.com`
- Scheme: `http`
- Forward Hostname/IP: `YOUR_MEDIA_VM_IP` (IP address of this VM)
- Forward Port: `4533`
- ✅ Cache Assets
- ✅ Block Common Exploits
- ✅ Websockets Support

**SSL Tab:**
- ✅ Force SSL
- SSL Certificate: Request new Let's Encrypt certificate
- ✅ HTTP/2 Support

**Advanced Tab (Optional):**
```nginx
# Navidrome-specific settings
client_max_body_size 50M;

# Proxy headers
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
```

**Update Navidrome Base URL:**

After configuring reverse proxy, update Navidrome settings:

1. Edit `media-players-stack.yml`
2. Update Navidrome environment:
   ```yaml
   environment:
     - ND_BASEURL=https://navidrome.yourdomain.com
   ```
3. Restart container: `docker compose restart navidrome`

---

## Troubleshooting

### Media Not Showing

**Check CIFS Mount:**
```bash
# Verify mount
df -h | grep media
mount | grep media

# Test access
ls -la /mnt/media
ls -la /mnt/media/movies
ls -la /mnt/media/tv

# Remount if needed
sudo umount /mnt/media
sudo mount /mnt/media
```

**Check Container Access:**
```bash
# Plex
docker exec plex ls -la /media
docker exec plex ls -la /media/movies

# Jellyfin
docker exec jellyfin ls -la /media
docker exec jellyfin ls -la /media/tv
```

**Check Permissions:**
```bash
# On CIFS share
ls -la /mnt/media

# Should show uid=1000, gid=1000
# If not, check CIFS mount options
cat /etc/fstab | grep media
```

### Plex Not Accessible

**Check Host Network:**
```bash
# Verify Plex is listening
sudo netstat -tulpn | grep 32400
sudo ss -tulpn | grep 32400

# Check firewall
sudo ufw status | grep 32400

# Test locally
curl -I http://localhost:32400/web
```

**Check Plex Logs:**
```bash
docker logs plex --tail 100
docker logs plex -f  # Follow logs
```

### Jellyfin Performance Issues

**Check Transcoding:**
```bash
# Monitor resources during playback
docker stats jellyfin

# Check transcoding logs
docker logs jellyfin | grep -i transcode
```

**Optimize Cache:**
```bash
# Clear Jellyfin cache
sudo rm -rf /nfs/vm_shares/cyrene/apps/jellyfin/cache/*

# Restart Jellyfin
docker restart jellyfin
```

### Hardware Transcoding Not Working

**Intel Quick Sync:**
```bash
# Check device exists
ls -la /dev/dri

# Check render group
getent group render

# Check permissions in container
docker exec jellyfin ls -la /dev/dri
docker exec plex ls -la /dev/dri
```

**NVIDIA GPU:**
```bash
# Check NVIDIA driver
nvidia-smi

# Check in container
docker exec jellyfin nvidia-smi
docker exec plex nvidia-smi
```

### Network Issues

**Test Container Connectivity:**
```bash
# Test from host
curl http://localhost:32400/web  # Plex
curl http://localhost:8096       # Jellyfin

# Test from another container
docker exec homepage curl http://jellyfin:8096

# Check network
docker network inspect media-players
docker network inspect nginx-proxy-manager
```

### Library Scan Issues

**Force Rescan:**

**Plex:**
- Settings → Library → Click library → "Scan Library Files"
- Or: Settings → Library → "Scan Library Files" (all libraries)

**Jellyfin:**
- Dashboard → Libraries → "Scan All Libraries"
- Or: Dashboard → Scheduled Tasks → "Scan Media Library" → Run Now

**Check File Permissions:**
```bash
# Files should be readable by UID 1000
sudo chown -R 1000:1000 /mnt/media
sudo chmod -R 755 /mnt/media
```

---

## Useful Commands

```bash
# View logs
docker logs plex -f
docker logs jellyfin -f

# Restart services
docker restart plex
docker restart jellyfin

# Check resource usage
docker stats plex jellyfin navidrome

# Access container shell
docker exec -it plex bash
docker exec -it jellyfin bash
docker exec -it navidrome sh

# Verify mounts inside container
docker exec plex df -h
docker exec jellyfin df -h
docker exec navidrome df -h

# Check network connectivity
docker exec jellyfin ping -c 3 nginx-proxy-manager

# Rebuild stack
cd stacks/media-players
docker compose -f media-players-stack.yml down
docker compose -f media-players-stack.yml pull
docker compose -f media-players-stack.yml up -d
```

### Navidrome Issues

**Music Not Appearing:**
```bash
# Check music folder exists and has content
ls -la /mnt/media/music

# Check permissions
ls -la /nfs/vm_shares/cyrene/apps/navidrome

# Force rescan
# Via Web UI: Settings → Rescan Now

# Check logs
docker logs navidrome --tail 100
docker logs navidrome -f
```

**Mobile App Connection Failed:**
```bash
# Test server accessibility
curl http://YOUR_SERVER_IP:4533/ping

# Check if behind reverse proxy
# Make sure ND_BASEURL is set correctly in docker-compose

# Verify firewall
sudo ufw status | grep 4533
```

**Slow Library Scan:**
```bash
# Check I/O performance
iostat -x 1

# Check if CIFS mount is slow
time ls -R /mnt/media/music | wc -l

# Consider adjusting scan schedule
# Edit docker-compose: ND_SCANSCHEDULE=24h
```

**Authentication Issues:**
```bash
# Reset admin password (requires database access)
docker exec -it navidrome sh
# Inside container:
# Navigate to /data directory
# Stop Navidrome, edit navidrome.db (requires sqlite3)

# Or recreate container with fresh data
docker compose down
sudo rm -rf /nfs/vm_shares/cyrene/apps/navidrome/*
docker compose up -d
# Create new admin account
```

---

## Additional Resources

### Plex
- Official Documentation: https://support.plex.tv
- Docker Hub: https://hub.docker.com/r/linuxserver/plex
- Community Forums: https://forums.plex.tv

### Jellyfin
- Official Documentation: https://jellyfin.org/docs
- Docker Hub: https://hub.docker.com/r/linuxserver/jellyfin
- Community Forums: https://forum.jellyfin.org

### Navidrome
- Official Documentation: https://www.navidrome.org/docs
- Docker Hub: https://hub.docker.com/r/deluan/navidrome
- GitHub: https://github.com/navidrome/navidrome
- Compatible Apps: https://www.navidrome.org/docs/overview/#apps

### Media Organization
- Plex Naming Conventions: https://support.plex.tv/articles/naming-and-organizing-your-movie-media-files/
- Jellyfin Naming: https://jellyfin.org/docs/general/server/media/movies.html
- Music Tagging: https://picard.musicbrainz.org (MusicBrainz Picard)
- FileBot: https://www.filebot.net (for organizing media)

---

## Security Considerations

1. **Read-Only Media Access**: Media is mounted as read-only (`:ro`) for security
2. **Secure Credentials**: CIFS credentials stored in `/root/.smb_credentials` with 600 permissions
3. **Firewall Rules**: Only necessary ports opened
4. **Reverse Proxy**: Use HTTPS with valid certificates
5. **User Access**: Configure authentication in Plex, Jellyfin, and Navidrome
6. **Network Isolation**: Consider using VLANs for media servers
7. **Navidrome Sharing**: Be cautious with public share links, set expiration times

---

For more information, see the main [README.md](../../README.md).

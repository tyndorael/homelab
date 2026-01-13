# Downloaders Stack Setup Guide

This guide covers the deployment and configuration of download clients for your homelab media automation.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Directory Setup](#directory-setup)
- [Deployment](#deployment)
- [Initial Configuration](#initial-configuration)
- [Integration with Media Automation](#integration-with-media-automation)
- [Troubleshooting](#troubleshooting)

---

## Overview

The downloaders stack provides BitTorrent download capabilities integrated with your media automation setup.

**Services Included:**
- **qBittorrent** (Port 8080) - BitTorrent client with web UI

**Port Assignments:**
- **8080** - qBittorrent Web UI
- **6881** - BitTorrent protocol (TCP/UDP)

**Storage Architecture:**
- **Config**: NFS shared storage (`/nfs/vm_shares/herta/apps/qbittorrent`)
- **Downloads**: CIFS media share (`/mnt/media/downloads`)

---

## Prerequisites

### 1. NFS Share
Ensure NFS is configured and mounted:
```bash
# Verify NFS mount
df -h | grep herta
```

### 2. CIFS/SMB Media Share
Ensure CIFS media share is mounted:
```bash
# Verify CIFS mount
df -h | grep media

# If not mounted, run the setup script
sudo bash setup-cifs-media.sh
```

### 3. Directory Structure
The CIFS share should have a downloads directory:
```bash
# Verify or create downloads directory
sudo mkdir -p /mnt/media/downloads
sudo mkdir -p /mnt/media/downloads/{incomplete,complete,torrents}

# Set permissions
sudo chown -R 1000:1000 /mnt/media/downloads
sudo chmod -R 755 /mnt/media/downloads
```

---

## Directory Setup

Create necessary directories on NFS share:

```bash
# Create qBittorrent config directory
sudo mkdir -p /nfs/vm_shares/herta/apps/qbittorrent/config
sudo mkdir -p /nfs/vm_shares/herta/stacks/downloaders

# Set ownership
sudo chown -R 1000:1000 /nfs/vm_shares/herta/apps/qbittorrent
sudo chmod -R 755 /nfs/vm_shares/herta/apps/qbittorrent

# Copy stack file
sudo cp downloaders-stack.yml /nfs/vm_shares/herta/stacks/downloaders/
```

---

## Firewall Configuration

Open required ports:

```bash
# qBittorrent Web UI
sudo ufw allow 8080/tcp comment 'qBittorrent Web UI'

# BitTorrent protocol
sudo ufw allow 6881/tcp comment 'qBittorrent BT TCP'
sudo ufw allow 6881/udp comment 'qBittorrent BT UDP'

# Verify
sudo ufw status
```

---

## Deployment

### Deploy the Stack

```bash
# Navigate to stack directory
cd /nfs/vm_shares/herta/stacks/downloaders

# Deploy the stack
docker compose up -d

# Verify containers are running
docker compose ps

# Check logs
docker compose logs -f qbittorrent
```

### Verify Deployment

```bash
# Check qBittorrent is running
docker ps | grep qbittorrent

# Check qBittorrent logs
docker logs qbittorrent

# Test web UI access
curl -I http://localhost:8080
```

---

## Initial Configuration

### 1. First Login

1. **Access qBittorrent Web UI:**
   - URL: `http://your-server-ip:8080`
   - Default credentials:
     - Username: `admin`
     - Password: `adminadmin`

2. **Change Default Password (IMPORTANT!):**
   - Go to: Tools → Options → Web UI
   - Authentication section
   - Change password to something secure
   - Click "Save"

### 2. Configure Basic Settings

**Go to: Tools → Options**

#### Connection Settings
- **Port used for incoming connections**: `6881` (matches docker port)
- **Use UPnP / NAT-PMP**: Disable (not needed in Docker)

#### Downloads Settings
- **Default Save Path**: `/downloads/complete`
- **Keep incomplete torrents in**: `/downloads/incomplete`
- **Copy .torrent files to**: `/downloads/torrents`
- **Copy .torrent files for finished downloads to**: `/downloads/torrents`

#### BitTorrent Settings
- **Privacy**
  - Enable Anonymous Mode: ✓ (optional, for privacy)
  - Enable DHT: ✓
  - Enable PEX: ✓
  - Enable Local Peer Discovery: ✓

#### Speed Settings
Configure according to your internet connection:
- **Global Download Speed Limit**: Set based on your ISP plan
- **Global Upload Speed Limit**: Set to 80% of your upload speed
- **Alternative Rate Limits**: Configure for daytime vs nighttime

#### Advanced Settings
- **Network Interface**: Leave empty (Docker handles this)
- **Listen on IPv6**: Disable (unless needed)

### 3. Configure Categories

Categories help organize downloads for different media types:

1. **Go to**: Right-click in sidebar → Add category
2. **Create categories:**

   | Category | Save Path | Use for |
   |----------|-----------|---------|
   | `tv` | `/downloads/complete/tv` | Sonarr |
   | `movies` | `/downloads/complete/movies` | Radarr |
   | `music` | `/downloads/complete/music` | Lidarr |
   | `books` | `/downloads/complete/books` | Readarr |

```bash
# Create category directories on CIFS share
sudo mkdir -p /mnt/media/downloads/complete/{tv,movies,music,books}
sudo mkdir -p /mnt/media/downloads/incomplete/{tv,movies,music,books}
sudo chown -R 1000:1000 /mnt/media/downloads
```

### 4. Web UI Security

**Go to: Tools → Options → Web UI**

- **IP address**: Leave as `*` (Docker handles network)
- **Port**: `8080`
- **Use UPnP / NAT-PMP**: Disable
- **Authentication**: Keep enabled
- **Bypass authentication for clients on localhost**: Enable
- **Bypass authentication for clients in whitelisted IP subnets**: Add your local network if needed
  - Example: `192.168.1.0/24` or `10.0.0.0/8`

---

## Integration with Media Automation

### Connect qBittorrent to *arr Apps

You'll need to add qBittorrent as a download client in each of your *arr applications.

#### For Sonarr, Radarr, Lidarr, Readarr

1. **Go to**: Settings → Download Clients → Add (+) → qBittorrent

2. **Configure settings:**
   ```
   Name: qBittorrent
   Enable: ✓
   Host: qbittorrent (if on same Docker network)
        OR
        192.168.X.X (your server IP if different network)
   Port: 8080
   Username: admin
   Password: (your changed password)
   Category: tv (or movies, music, books depending on app)
   ```

3. **Test and Save**

#### Important Path Mappings

If your *arr apps and qBittorrent are on the same Docker host, paths should match:
- qBittorrent sees: `/downloads/complete/tv`
- Sonarr sees: `/downloads/complete/tv`

No remote path mapping needed if using shared volumes correctly!

### Example *arr Configuration

**Sonarr Download Client Settings:**
```yaml
Name: qBittorrent
Host: qbittorrent
Port: 8080
URL Base: (leave empty)
Username: admin
Password: your-password
Category: tv
Priority: 1
Initial State: Start
Sequential Order: No
First and Last First: No
```

**Download Handling:**
- In Sonarr/Radarr: Settings → Download Clients
- Make sure "Completed Download Handling" is enabled
- This allows *arr apps to import and rename files automatically

---

## Reverse Proxy Configuration

### Nginx Proxy Manager Setup

1. **Add Proxy Host:**
   - Domain Names: `qbittorrent.tyndorael.duckdns.org`
   - Scheme: `http`
   - Forward Hostname/IP: `192.168.X.X` (your VM IP)
   - Forward Port: `8080`
   - Cache Assets: ✓
   - Block Common Exploits: ✓
   - Websockets Support: ✓

2. **SSL Certificate:**
   - SSL Certificate: Request new Let's Encrypt certificate
   - Force SSL: ✓
   - HTTP/2 Support: ✓
   - HSTS Enabled: ✓

### Update qBittorrent for Reverse Proxy

After setting up reverse proxy, update Web UI settings:

1. **Go to**: Tools → Options → Web UI
2. **Use Alternative Web UI**: (optional, for custom themes)
3. **Server domains**: Add your domain
   - `qbittorrent.tyndorael.duckdns.org`

---

## Performance Tuning

### Optimize for Your Use Case

#### For Fast Downloads (High-Speed Internet)
```yaml
# In qBittorrent Options → Advanced
- Disk Cache: 256 MB or higher
- Disk Cache Expiry: 600 seconds
- Enable OS Cache: ✓
- Asynchronous I/O threads: 10
```

#### For Multiple Simultaneous Torrents
```yaml
# In qBittorrent Options → BitTorrent
- Maximum active downloads: 5
- Maximum active uploads: 5
- Maximum active torrents: 10
```

#### For Seedbox (24/7 Seeding)
```yaml
# In qBittorrent Options → BitTorrent
- Seeding Limits:
  - When ratio reaches: 2.0
  - When seeding time reaches: 10080 minutes (1 week)
  - Then: Pause torrent
```

---

## Monitoring

### Check Download Status

```bash
# View qBittorrent logs
docker logs -f qbittorrent

# Check resource usage
docker stats qbittorrent

# Monitor downloads directory
du -sh /mnt/media/downloads/*
```

### Access Logs Location

On NFS share:
```bash
# View qBittorrent logs
tail -f /nfs/vm_shares/herta/apps/qbittorrent/config/qBittorrent/logs/qbittorrent.log
```

---

## Troubleshooting

### Web UI Not Accessible

**Check container status:**
```bash
docker ps | grep qbittorrent
docker logs qbittorrent
```

**Check firewall:**
```bash
sudo ufw status | grep 8080
```

**Test connectivity:**
```bash
curl http://localhost:8080
```

### Downloads Not Starting

**Check permissions:**
```bash
ls -la /mnt/media/downloads
# Should be owned by 1000:1000
```

**Check CIFS mount:**
```bash
df -h | grep media
mount | grep media
```

**Check disk space:**
```bash
df -h /mnt/media
```

### Connection Issues in *arr Apps

**Verify network:**
```bash
# If *arr apps are on same Docker host
docker network inspect downloaders

# Test connectivity from another container
docker exec sonarr ping qbittorrent
```

**Check qBittorrent credentials:**
- Make sure username/password in *arr apps match qBittorrent
- Verify qBittorrent Web UI is accessible from *arr apps

### Slow Download Speeds

**Check bandwidth limits:**
- Tools → Options → Speed
- Temporarily remove limits to test

**Check connection count:**
- Tools → Options → BitTorrent → "Maximum number of connections"
- Increase if needed (default: 500)

**Check disk I/O:**
```bash
# Monitor disk performance
iostat -x 1

# Check if CIFS is bottleneck
iotop
```

**For CIFS performance:**
- Consider using NFS for downloads if CIFS is slow
- Adjust CIFS mount options in `/etc/fstab` (add `cache=loose`)

### Port Not Open / NAT Issues

**Verify port forwarding:**
- In qBittorrent: Tools → Options → Connection
- Check "Port used for incoming connections" shows a checkmark (green)
- If not, port forwarding may not be working

**Docker port mapping:**
```bash
# Verify port 6881 is mapped
docker port qbittorrent
```

### Permission Denied Errors

**Fix ownership:**
```bash
sudo chown -R 1000:1000 /nfs/vm_shares/herta/apps/qbittorrent
sudo chown -R 1000:1000 /mnt/media/downloads
```

**Fix permissions:**
```bash
sudo chmod -R 755 /nfs/vm_shares/herta/apps/qbittorrent
sudo chmod -R 755 /mnt/media/downloads
```

---

## Security Best Practices

1. **Change Default Password**
   - First and most important step!

2. **Use Strong Authentication**
   - Don't bypass authentication unless necessary
   - Use IP whitelist for trusted networks only

3. **Consider VPN Integration**
   - For enhanced privacy
   - Use gluetun container for VPN (can be added later)

4. **Limit Web UI Access**
   - Use reverse proxy with authentication
   - Don't expose port 8080 to internet directly

5. **Regular Updates**
   - Watchtower will auto-update the container
   - Check release notes for breaking changes

6. **Monitor Activity**
   - Regularly check logs for suspicious activity
   - Review active torrents periodically

---

## Advanced Configuration

### Adding VPN Support (Optional)

For privacy, you can route qBittorrent through a VPN using gluetun:

```yaml
# Add gluetun service to downloaders-stack.yml
gluetun:
  image: qmcgaw/gluetun
  container_name: gluetun
  cap_add:
    - NET_ADMIN
  environment:
    - VPN_SERVICE_PROVIDER=your-vpn-provider
    - VPN_TYPE=openvpn
    - OPENVPN_USER=your-username
    - OPENVPN_PASSWORD=your-password
  # Then modify qbittorrent service:
  network_mode: "service:gluetun"
  depends_on:
    - gluetun
```

### Custom Themes

qBittorrent supports custom Web UI themes:

1. Download theme (e.g., VueTorrent)
2. Place in `/nfs/vm_shares/herta/apps/qbittorrent/themes/`
3. Enable in: Tools → Options → Web UI → Use Alternative Web UI

---

## Useful Commands

```bash
# Restart qBittorrent
docker restart qbittorrent

# Update qBittorrent
cd /nfs/vm_shares/herta/stacks/downloaders
docker compose pull
docker compose up -d

# View active downloads
# (Access via Web UI at http://your-server:8080)

# Backup configuration
sudo tar -czf qbittorrent-config-backup-$(date +%Y%m%d).tar.gz \
  /nfs/vm_shares/herta/apps/qbittorrent/config

# Check download speed from command line
docker stats --no-stream qbittorrent
```

---

## Next Steps

1. **Configure Reverse Proxy** (if needed)
   - Add domain in Nginx Proxy Manager
   - Get SSL certificate

2. **Integrate with *arr Apps**
   - Add qBittorrent to Sonarr, Radarr, etc.
   - Test downloads

3. **Set Download Rules**
   - Configure ratio limits
   - Set up categories
   - Define bandwidth schedules

4. **Optional Enhancements**
   - Add VPN support (gluetun)
   - Install custom Web UI theme
   - Set up RSS feeds for auto-downloads

---

## Additional Resources

- **qBittorrent Wiki**: https://github.com/qbittorrent/qBittorrent/wiki
- **LinuxServer qBittorrent Docs**: https://docs.linuxserver.io/images/docker-qbittorrent
- **TRaSH Guides (Download Clients)**: https://trash-guides.info/Downloaders/
- **Integration with *arr Apps**: https://wiki.servarr.com/

---

## Support

For issues specific to:
- **qBittorrent Configuration**: Check official wiki
- **Docker Deployment**: Check LinuxServer.io documentation
- **CIFS Mount Issues**: See `setup-cifs-media.sh` troubleshooting
- ***arr Integration**: See individual *arr application setup guides

---

**Setup complete!** qBittorrent is ready to integrate with your media automation workflow.

# Media Automation Stack Setup (*arr Apps)

This stack contains the *arr suite of applications for automated media management.

## Services Included

### Core Services

#### Sonarr
- **Purpose**: TV show collection management and automation
- **Port**: 8989
- **Features**:
  - Automatic TV show downloads
  - Episode tracking and calendar
  - Quality profile management
  - Series monitoring
  - Integration with download clients

#### Radarr
- **Purpose**: Movie collection management and automation
- **Port**: 7878
- **Features**:
  - Automatic movie downloads
  - Release monitoring
  - Quality profile management
  - Movie library organization
  - Integration with download clients

#### Prowlarr
- **Purpose**: Indexer manager for *arr apps
- **Port**: 9696
- **Features**:
  - Centralized indexer management
  - Automatic sync with Sonarr, Radarr, etc.
  - Built-in indexer search
  - Statistics and health checks
  - Flaresolverr integration support

### Optional Services

#### Bazarr
- **Purpose**: Subtitle management for TV shows and movies
- **Port**: 6767
- **Features**:
  - Automatic subtitle downloads
  - Multiple language support
  - Integration with Sonarr and Radarr
  - Subtitle providers management

#### Lidarr
- **Purpose**: Music collection management and automation
- **Port**: 8686
- **Features**:
  - Automatic music downloads
  - Artist and album tracking
  - Quality profile management
  - Integration with download clients

#### Readarr
- **Purpose**: Book/eBook collection management
- **Port**: 8787
- **Features**:
  - Automatic book downloads
  - Author tracking
  - eBook and audiobook support
  - Integration with download clients

## Prerequisites

- Docker and Docker Compose installed
- NFS mount at `/nfs/vm_shares/herta` (or update volume paths)
- Infrastructure stack deployed (nginx-proxy-manager network must exist)
- Download client (qBittorrent, Transmission, SABnzbd, etc.)
- Indexers or Usenet providers

## Directory Setup

Before deploying, create the necessary directory structure:

```bash
# Create app config directories
sudo mkdir -p /nfs/vm_shares/herta/apps/{sonarr,radarr,prowlarr,bazarr,lidarr,readarr}/config

# Create media directories
sudo mkdir -p /nfs/vm_shares/herta/media/{tv,movies,music,books}

# Create downloads directory
sudo mkdir -p /nfs/vm_shares/herta/downloads/{complete,incomplete}

# Set proper permissions
sudo chown -R 1000:1000 /nfs/vm_shares/herta/apps
sudo chown -R 1000:1000 /nfs/vm_shares/herta/media
sudo chown -R 1000:1000 /nfs/vm_shares/herta/downloads
sudo chmod -R 755 /nfs/vm_shares/herta/apps
sudo chmod -R 755 /nfs/vm_shares/herta/media
sudo chmod -R 775 /nfs/vm_shares/herta/downloads
```

**Note**: If you ran the setup script with directory creation, some directories may already exist.

## Deployment

### Via Portainer (Recommended)

1. Access Portainer web UI
2. Go to **Stacks** → **Add stack**
3. Name it: `media-automation`
4. Upload or paste the contents of `media-automation-stack.yml`
5. Configure environment variables
6. Click **Deploy the stack**

### Via Docker Compose

```bash
cd stacks/media-automation
docker compose -f media-automation-stack.yml up -d
```

## Environment Variables

Create a `.env` file in the same directory:

```env
TZ=America/New_York
```

## Initial Configuration

### 1. Prowlarr Setup (Do This First!)

1. Access Prowlarr at `http://your-server-ip:9696`
2. Go to **Settings** → **General** and set authentication
3. Go to **Indexers** → **Add Indexer** and add your indexers
4. Go to **Settings** → **Apps** and add Sonarr, Radarr, etc.
5. Prowlarr will sync indexers to all connected apps

### 2. Sonarr Setup

1. Access Sonarr at `http://your-server-ip:8989`
2. Go to **Settings** → **General** and set authentication
3. Go to **Settings** → **Media Management**:
   - Set root folder: `/tv`
   - Configure file naming
4. Go to **Settings** → **Download Clients**:
   - Add your download client (qBittorrent, etc.)
5. Go to **Settings** → **Connect**:
   - Add Prowlarr connection (if not auto-configured)

### 3. Radarr Setup

1. Access Radarr at `http://your-server-ip:7878`
2. Go to **Settings** → **General** and set authentication
3. Go to **Settings** → **Media Management**:
   - Set root folder: `/movies`
   - Configure file naming
4. Go to **Settings** → **Download Clients**:
   - Add your download client
5. Go to **Settings** → **Connect**:
   - Add Prowlarr connection (if not auto-configured)

### 4. Bazarr Setup (Optional)

1. Access Bazarr at `http://your-server-ip:6767`
2. Go to **Settings** → **Sonarr** and configure connection
3. Go to **Settings** → **Radarr** and configure connection
4. Go to **Settings** → **Subtitles** and add subtitle providers
5. Go to **Settings** → **Languages** and set preferred languages

### 5. Lidarr Setup (Optional)

1. Access Lidarr at `http://your-server-ip:8686`
2. Go to **Settings** → **General** and set authentication
3. Go to **Settings** → **Media Management**:
   - Set root folder: `/music`
4. Go to **Settings** → **Download Clients**:
   - Add your download client

### 6. Readarr Setup (Optional)

1. Access Readarr at `http://your-server-ip:8787`
2. Go to **Settings** → **General** and set authentication
3. Go to **Settings** → **Media Management**:
   - Set root folder: `/books`
4. Go to **Settings** → **Download Clients**:
   - Add your download client

## Post-Deployment

Access the services:
- Sonarr: `http://your-server-ip:8989`
- Radarr: `http://your-server-ip:7878`
- Prowlarr: `http://your-server-ip:9696`
- Bazarr: `http://your-server-ip:6767`
- Lidarr: `http://your-server-ip:8686`
- Readarr: `http://your-server-ip:8787`

## Setting Up Reverse Proxy

Use Nginx Proxy Manager to create proxy hosts for each service:

1. Access Nginx Proxy Manager at `http://your-server-ip:81`
2. Go to **Hosts** → **Proxy Hosts** → **Add Proxy Host**
3. Configure each service:
   - **Sonarr**: Forward to `sonarr:8989`
   - **Radarr**: Forward to `radarr:7878`
   - **Prowlarr**: Forward to `prowlarr:9696`
   - **Bazarr**: Forward to `bazarr:6767`
   - **Lidarr**: Forward to `lidarr:8686`
   - **Readarr**: Forward to `readarr:8787`
4. Enable **Websockets Support** for each
5. Enable SSL certificates

## Network Architecture

All services in this stack:
- Share a common `media-automation` network for inter-service communication
- Connect to `nginx-proxy-manager` network for reverse proxy access
- Share the same media and download directories
- Use consistent PUID/PGID (1000:1000) for file permissions

## Common Configuration Tips

### Quality Profiles

Create quality profiles based on your preferences:
- **1080p**: Good balance of quality and size
- **720p**: Smaller file sizes
- **4K/2160p**: Maximum quality (large files)
- **Any**: Accept any quality

### Download Client Configuration

Ensure your download client settings match:
- **Category/Label**: Use different categories for movies/TV
- **Remote Path Mappings**: May be needed if download client is on different host
- **Completed Download Handling**: Enable in *arr apps

### File Naming

Configure consistent file naming in each app:
- **TV Shows**: `{Series Title} - S{season:00}E{episode:00} - {Episode Title}`
- **Movies**: `{Movie Title} ({Release Year}) - {Quality Full}`
- **Music**: `{Artist Name}/{Album Title}/{track:00} - {Track Title}`

### Import Lists

Use import lists to automatically add content:
- Trakt lists
- IMDb lists
- MyAnimeList
- Goodreads (for Readarr)

## Updating Services

```bash
docker compose -f media-automation-stack.yml pull
docker compose -f media-automation-stack.yml up -d
docker image prune -f
```

## Troubleshooting

### Services can't communicate

- Verify all services are on the `media-automation` network
- Check Prowlarr app connections
- Ensure API keys are correct

### Permission denied errors

```bash
# Fix permissions
sudo chown -R 1000:1000 /nfs/vm_shares/herta/media
sudo chown -R 1000:1000 /nfs/vm_shares/herta/downloads
sudo chmod -R 775 /nfs/vm_shares/herta/downloads
```

### Download client connection issues

- Verify download client is accessible from the *arr apps
- Check if using correct host (container name or IP)
- Verify download client port is correct
- Check authentication credentials

### Indexers not working

- Ensure Prowlarr is properly configured
- Check indexer health in Prowlarr
- Verify indexers are synced to apps
- Check for rate limiting or banned IP

### Import not working

- Verify folder structure matches expectations
- Check file permissions
- Ensure media folders are mapped correctly
- Review activity logs in the app

### API errors

- Regenerate API keys if needed
- Verify API key is correctly entered in connected apps
- Check for URL base mismatches

## Security Best Practices

1. **Enable Authentication** - Set up user authentication in all apps
2. **Use HTTPS** - Access via reverse proxy with SSL
3. **Regular Backups** - Backup config directories regularly
4. **Update Regularly** - Keep all services up to date
5. **VPN/Proxy** - Consider using VPN for download client
6. **Private Indexers** - Use private trackers when possible
7. **Firewall Rules** - Don't expose service ports to internet

## Recommended Additional Services

Consider adding these services to complement the *arr stack:

- **qBittorrent** or **Transmission** - Download client
- **Jellyfin** or **Plex** - Media server
- **Overseerr** or **Jellyseerr** - Media request management
- **Tautulli** - Plex monitoring and statistics
- **Organizr** - Unified interface for all services

## Next Steps

After deploying the media automation stack:

1. ✅ Configure authentication for all services
2. ✅ Set up Prowlarr with your indexers
3. ✅ Connect Prowlarr to Sonarr, Radarr, etc.
4. ✅ Configure download client in all apps
5. ✅ Set up quality profiles
6. ✅ Configure file naming conventions
7. ✅ Add media to start automated downloads
8. 🔒 Set up reverse proxy with SSL
9. 💾 Configure backup solution
10. 📺 Install media server (Jellyfin/Plex)

## Resources

- [Servarr Wiki](https://wiki.servarr.com/)
- [TRaSH Guides](https://trash-guides.info/)
- [Sonarr Documentation](https://sonarr.tv/)
- [Radarr Documentation](https://radarr.video/)
- [Prowlarr Documentation](https://prowlarr.com/)
- [LinuxServer.io Documentation](https://docs.linuxserver.io/)

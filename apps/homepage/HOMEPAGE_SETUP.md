# Homepage Setup Guide

Homepage is a modern, fully static, fast, and secure application dashboard with integrations for over 100 services. Fully configured via YAML files or Docker label discovery.

## Features

✅ **Fast & Static** - Statically generated at build time for instant loads
✅ **Docker Integration** - Automatic service discovery via Docker labels
✅ **100+ Service Widgets** - Integrations for Radarr, Sonarr, Plex, Jellyfin, and more
✅ **Information Widgets** - Weather, system stats, search, and more
✅ **Secure** - All API requests are proxied, keeping API keys hidden
✅ **Customizable** - Custom themes, CSS, layouts, and localization
✅ **40+ Languages** - Full internationalization support
✅ **Bookmarks** - Add custom links and web bookmarks
✅ **Container Stats** - Real-time Docker container status and statistics

## Installation Steps

### 1. Prepare Directory

Create the required directory for Homepage configuration:

```bash
mkdir -p /nfs/vm_shares/herta/apps/homepage/config
```

### 2. Configure Environment Variables

Add to your `.env` file:

```env
TZ=America/New_York
HOMEPAGE_ALLOWED_HOSTS=your-server-ip:3000
# Or for domain access:
# HOMEPAGE_ALLOWED_HOSTS=home.yourdomain.com
```

**Important**: `HOMEPAGE_ALLOWED_HOSTS` is required and should match how you'll access Homepage (IP:port or domain name).

### 3. Deploy in Portainer

### 3. Deploy in Portainer

1. Go to **Stacks** → **Add stack**
2. Name it "homepage"
3. Upload `homepage-stack.yml` or paste its contents
4. Add environment variables:
   - `TZ`: Your timezone (e.g., `America/New_York`)
   - `HOMEPAGE_ALLOWED_HOSTS`: Your server IP and port (e.g., `192.168.1.100:3000`) or domain (e.g., `home.yourdomain.com`)
5. Click **Deploy the stack**

### 4. Initial Access

### 4. Initial Access

1. Access Homepage at `http://your-vm-ip:3000`
2. You'll see a skeleton configuration
3. Start customizing your configuration files

### 5. Basic Configuration

### 5. Basic Configuration

Homepage uses YAML configuration files in `/nfs/vm_shares/herta/apps/homepage/config/`:

#### Configuration Files

- `settings.yaml` - General settings, theme, layout
- `services.yaml` - Your services and integrations
- `widgets.yaml` - Information widgets (weather, search, etc.)
- `bookmarks.yaml` - Quick bookmarks and links
- `docker.yaml` - Docker integration settings

### 5. Example Configuration

#### settings.yaml

```yaml
title: My Homelab
favicon: https://yourdomain.com/favicon.ico
theme: dark
color: slate
layout:
  Network Services:
    style: row
    columns: 3
  Media:
    style: row
    columns: 4

providers:
  openweathermap: your_api_key_here
  weatherapi: your_api_key_here
```

#### services.yaml

```yaml
- Network Services:
    - Portainer:
        icon: portainer.png
        href: https://portainer.yourdomain.com
        description: Container Management
        widget:
          type: portainer
          url: http://portainer:9000
          env: 2
          key: ptr_your_api_key_here

    - Nginx Proxy Manager:
        icon: nginx-proxy-manager.png
        href: https://npm.yourdomain.com
        description: Reverse Proxy & SSL
        
    - Dockpeek:
        icon: docker.png
        href: https://dockpeek.yourdomain.com
        description: Docker Dashboard

- Monitoring:
    - Homepage:
        icon: homepage.png
        href: https://home.yourdomain.com
        description: Application Dashboard
```

#### widgets.yaml

```yaml
- logo:
    icon: https://yourdomain.com/logo.png

- search:
    provider: google
    target: _blank

- datetime:
    text_size: xl
    format:
      timeStyle: short
      dateStyle: short
      hourCycle: h23

- openmeteo:
    label: Home
    latitude: 40.7128
    longitude: -74.0060
    units: metric
    cache: 5

- resources:
    cpu: true
    memory: true
    disk: /
```

#### bookmarks.yaml

```yaml
- Developer:
    - GitHub:
        - icon: github.png
          href: https://github.com
    - GitLab:
        - icon: gitlab.png
          href: https://gitlab.com

- Documentation:
    - Homepage Docs:
        - icon: homepage.png
          href: https://gethomepage.dev
    - Docker Docs:
        - icon: docker.png
          href: https://docs.docker.com
```

#### docker.yaml

```yaml
my-docker:
  socket: /var/run/docker.sock
```

### 6. Docker Service Discovery

Homepage can automatically discover services using Docker labels. Add labels to your containers:

```yaml
labels:
  - homepage.group=Network Services
  - homepage.name=Portainer
  - homepage.icon=portainer.png
  - homepage.href=https://portainer.yourdomain.com
  - homepage.description=Container Management
  - homepage.widget.type=portainer
  - homepage.widget.url=http://portainer:9000
  - homepage.widget.env=2
  - homepage.widget.key=ptr_your_api_key_here
```

### 7. (Optional) Configure Nginx Proxy Manager

To access via a custom domain:

1. In NPM, create a new Proxy Host:
   - **Domain**: `home.yourdomain.com` or `homepage.yourdomain.com`
   - **Forward Hostname**: `homepage`
   - **Forward Port**: `3000`
   - Enable **Websockets Support**
   
2. Go to **SSL** tab:
   - Select your SSL certificate
   - Enable **Force SSL**, **HTTP/2**, and **HSTS**
   - Save

Access at: `https://home.yourdomain.com`

**Note**: If accessing via domain, update your `HOMEPAGE_ALLOWED_HOSTS` environment variable to match the domain name, then redeploy the stack.

## Configuration Options

### Settings Options

```yaml
title: Dashboard Title
favicon: /path/to/favicon
theme: dark # or light
color: slate # slate, gray, zinc, neutral, stone, amber, yellow, etc.
target: _blank # or _self for link behavior
cardBlur: md # none, sm, md, lg, xl
backgroundOpacity: 50 # 0-100
background:
  image: /images/background.jpg
  blur: sm
  saturate: 50
  brightness: 50
  opacity: 50
layout:
  Group Name:
    style: row # or column
    columns: 3 # 1-6
    header: true
hideVersion: false
```

### Service Widget Types

Homepage supports 100+ service integrations. Some popular ones:

**Media Servers:**
- `plex` - Plex Media Server
- `jellyfin` - Jellyfin
- `emby` - Emby
- `tautulli` - Tautulli

**Download Clients:**
- `transmission` - Transmission
- `qbittorrent` - qBittorrent
- `deluge` - Deluge
- `sabnzbd` - SABnzbd

**Media Management:**
- `sonarr` - Sonarr
- `radarr` - Radarr
- `lidarr` - Lidarr
- `prowlarr` - Prowlarr

**System & Network:**
- `portainer` - Portainer
- `unifi` - UniFi Controller
- `pihole` - Pi-hole
- `adguardhome` - AdGuard Home

[Full Widget List](https://gethomepage.dev/widgets/)

### Information Widgets

Available information widgets:

```yaml
- search: # Search bar
    provider: google # google, duckduckgo, bing, baidu, brave, custom
    target: _blank

- datetime: # Date and time
    text_size: xl
    format:
      timeStyle: short
      hourCycle: h23

- openmeteo: # Weather widget
    label: Location
    latitude: 40.71
    longitude: -74.01
    units: metric
    cache: 5

- resources: # System resources
    cpu: true
    memory: true
    disk: /
    cputemp: true
    uptime: true

- glances: # Glances integration
    url: http://glances:61208
    metric: cpu
```

## Advanced Features

### Custom Icons

Place custom icons in `/nfs/vm_shares/herta/apps/homepage/config/icons/`:

```yaml
- Service Name:
    icon: /icons/my-icon.png
    href: https://service.local
```

### Custom CSS

Create `custom.css` in config directory:

```yaml
# settings.yaml
customCSS: |
  .service-group {
    border-radius: 10px;
  }
```

### API Keys & Secrets

Store sensitive data in `secrets.yaml`:

```yaml
# secrets.yaml
portainer_api_key: ptr_your_key_here
radarr_api_key: your_radarr_key
```

Reference in services:

```yaml
widget:
  type: portainer
  key: {{HOMEPAGE_VAR_PORTAINER_API_KEY}}
```

### Custom Bookmarks Groups

Organize bookmarks by category:

```yaml
- Development:
    - GitHub:
        - icon: github.png
          href: https://github.com/username
          description: My GitHub Profile
    - VSCode Web:
        - icon: vscode.png
          href: https://vscode.dev

- Media:
    - YouTube:
        - icon: youtube.png
          href: https://youtube.com
    - Spotify:
        - icon: spotify.png
          href: https://spotify.com
```

## Docker Label Examples

### Basic Service

```yaml
labels:
  - homepage.group=Services
  - homepage.name=My App
  - homepage.icon=app.png
  - homepage.href=https://app.local
  - homepage.description=My Application
```

### Service with Widget

```yaml
labels:
  - homepage.group=Media
  - homepage.name=Radarr
  - homepage.icon=radarr.png
  - homepage.href=https://radarr.local
  - homepage.description=Movie Management
  - homepage.widget.type=radarr
  - homepage.widget.url=http://radarr:7878
  - homepage.widget.key={{HOMEPAGE_VAR_RADARR_KEY}}
```

### Ping Widget

```yaml
labels:
  - homepage.group=Network
  - homepage.name=Router
  - homepage.icon=router.png
  - homepage.href=http://192.168.1.1
  - homepage.widget.type=ping
  - homepage.widget.url=http://192.168.1.1
```

## Themes

Available color themes:
- `slate` (default)
- `gray`
- `zinc`
- `neutral`
- `stone`
- `red`
- `orange`
- `amber`
- `yellow`
- `lime`
- `green`
- `emerald`
- `teal`
- `cyan`
- `sky`
- `blue`
- `indigo`
- `violet`
- `purple`
- `fuchsia`
- `pink`
- `rose`

## Security Best Practices

- Deploy behind reverse proxy with authentication
- Use HTTPS via NPM
- Keep Homepage updated
- Don't expose port 3000 directly to internet
- Use Docker socket proxy for enhanced security
- Store API keys in `secrets.yaml`
- Regular config backups
- Use read-only Docker socket when possible

## Troubleshooting

**Can't access dashboard:**
- Check container is running: `docker ps | grep homepage`
- Verify port 3000 is accessible
- Check logs: `docker logs homepage`

**Services not appearing:**
- Verify config files exist in `/nfs/vm_shares/herta/apps/homepage/config/`
- Check YAML syntax (use YAML validator)
- Review logs for parsing errors
- Ensure file permissions are correct

**Docker discovery not working:**
- Verify Docker socket is mounted: `-v /var/run/docker.sock:/var/run/docker.sock:ro`
- Check `docker.yaml` configuration
- Ensure containers have proper labels
- Review container logs

**Widgets not loading:**
- Verify service URLs are accessible from Homepage container
- Check API keys are correct
- Ensure services are on same Docker network or accessible
- Review widget documentation for specific requirements

**Icons not displaying:**
- Check icon file exists in correct path
- Verify icon filename in configuration
- Use absolute paths for custom icons
- Clear browser cache

## Useful Commands

View logs:
```bash
docker logs homepage -f
```

Restart Homepage:
```bash
docker restart homepage
```

Access container shell:
```bash
docker exec -it homepage sh
```

Validate YAML config:
```bash
# Install yamllint
pip install yamllint

# Validate config
yamllint /nfs/vm_shares/herta/apps/homepage/config/*.yaml
```

Backup config:
```bash
tar -czf homepage-config-backup.tar.gz /nfs/vm_shares/herta/apps/homepage/config/
```

Restore config:
```bash
tar -xzf homepage-config-backup.tar.gz -C /nfs/vm_shares/herta/apps/homepage/
docker restart homepage
```

## Resources

- [Official Documentation](https://gethomepage.dev/)
- [GitHub Repository](https://github.com/gethomepage/homepage)
- [Service Widgets](https://gethomepage.dev/widgets/)
- [Configuration Examples](https://gethomepage.dev/configs/)
- [Docker Integration](https://gethomepage.dev/configs/docker/)
- [Troubleshooting Guide](https://gethomepage.dev/troubleshooting/)
- [Discord Community](https://discord.gg/k4ruYNrudu)

## Next Steps

1. Create your configuration files in the config directory
2. Add your services to `services.yaml`
3. Configure widgets in `widgets.yaml`
4. Set up bookmarks in `bookmarks.yaml`
5. Customize appearance in `settings.yaml`
6. Enable Docker service discovery with labels
7. Set up NPM proxy for external access
8. Explore service integrations and widgets
9. Join the community and share your setup!

# Dashy Setup Guide

Dashy is a highly customizable, self-hosted dashboard for organizing and accessing your services. Beautiful UI with themes, widgets, status monitoring, and tons of features.

## Features

✅ **Multi-page support** - Organize services across multiple pages
✅ **Real-time status monitoring** - Check if services are up and responding
✅ **Widgets** - Display dynamic content from self-hosted services
✅ **Instant search** - Find services by name, domain, or tags
✅ **Multiple themes** - Built-in color themes with custom CSS support
✅ **Icon options** - Font-Awesome, homelab icons, favicons, emojis, and more
✅ **Authentication** - Optional multi-user access with SSO support
✅ **Multi-language** - 10+ translated languages
✅ **Cloud backup** - Optional encrypted off-site backup and restore
✅ **Workspace view** - Switch between multiple apps simultaneously
✅ **PWA support** - Install as a progressive web app

## Installation Steps

### 1. Prepare Directory

Create the required directory for Dashy configuration:

```bash
mkdir -p /nfs/vm_shares/herta/apps/dashy/config
```

### 2. Deploy in Portainer

### 2. Deploy in Portainer

1. Go to **Stacks** → **Add stack**
2. Name it "dashy"
3. Upload `dashy-stack.yml` or paste its contents
4. (Optional) Add environment variable:
   - `TZ`: Your timezone (e.g., `America/New_York`)
5. Click **Deploy the stack**

### 3. Initial Access

### 3. Initial Access

1. Access Dashy at `http://your-vm-ip:4000`
2. You'll see the default demo dashboard
3. Click the **Config** icon (top-right) to customize

### 4. Configure Your Dashboard

#### Option A: Using the UI Editor

1. Enter **Edit Mode** (Pen icon in top-right)
2. Click any section or item to edit
3. Add new sections and services
4. Click **Save to Disk** to persist changes

#### Option B: Edit Config File Directly

Edit the config file directly on your shared storage:

```bash
# On your Docker host or via SSH
vi /nfs/vm_shares/herta/apps/dashy/config/conf.yml
```

Or access from the container:

```bash
docker exec -it dashy sh
vi /app/user-data/conf.yml
```

The config is stored at `/nfs/vm_shares/herta/apps/dashy/config/` on your host system.

### 5. Basic Configuration Example

Create your `conf.yml` at `/nfs/vm_shares/herta/apps/dashy/config/conf.yml`:

```yaml
pageInfo:
  title: My Homelab Dashboard
  description: Welcome to my self-hosted services
  navLinks:
    - title: GitHub
      path: https://github.com
    - title: Documentation
      path: https://dashy.to/docs

appConfig:
  theme: nord
  layout: auto
  iconSize: medium
  language: en
  statusCheck: true
  statusCheckInterval: 300

sections:
  - name: Network Services
    icon: fas fa-network-wired
    items:
      - title: Portainer
        description: Container Management
        icon: favicon
        url: https://portainer.yourdomain.com
        statusCheck: true
        
      - title: Nginx Proxy Manager
        description: Reverse Proxy
        icon: favicon
        url: https://npm.yourdomain.com
        statusCheck: true
        
  - name: Monitoring
    icon: fas fa-chart-line
    items:
      - title: Dockpeek
        description: Docker Dashboard
        icon: favicon
        url: https://dockpeek.yourdomain.com
        statusCheck: true
```

### 6. (Optional) Configure Nginx Proxy Manager

To access via a custom domain:

1. In NPM, create a new Proxy Host:
   - **Domain**: `dashy.yourdomain.com` or `home.yourdomain.com`
   - **Forward Hostname**: `dashy`
   - **Forward Port**: `8080`
   - Enable **Websockets Support**
   
2. Go to **SSL** tab:
   - Select your SSL certificate
   - Enable **Force SSL**, **HTTP/2**, and **HSTS**
   - Save

Access at: `https://dashy.yourdomain.com`

## Configuration Options

### App Config

Common `appConfig` options:

```yaml
appConfig:
  theme: colorful                    # Theme name
  layout: auto                       # auto, horizontal, vertical, grid
  iconSize: medium                   # small, medium, large
  language: en                       # Language code
  startingView: default              # default, minimal, workspace
  defaultOpeningMethod: newtab       # newtab, sametab, modal, workspace
  statusCheck: true                  # Enable status checking
  statusCheckInterval: 300           # Check interval in seconds
  disableUpdateChecks: false         # Disable checking for Dashy updates
  hideComponents:                    # Hide UI components
    hideHeading: false
    hideNav: false
    hideSearch: false
    hideSettings: false
    hideFooter: false
```

### Item Properties

Configure individual items:

```yaml
items:
  - title: Service Name
    description: Brief description
    icon: favicon                    # Icon type
    url: https://service.local
    target: newtab                   # newtab, sametab, modal, workspace
    statusCheck: true                # Enable for this item
    statusCheckUrl: https://alt.url  # Alternative URL for status check
    tags: [tag1, tag2]               # Search tags
    hotkey: 0                        # Keyboard shortcut (0-9)
```

### Icon Types

Dashy supports multiple icon sources:

```yaml
# Favicon (auto-fetch from URL)
icon: favicon

# Font Awesome
icon: fas fa-rocket

# Simple Icons
icon: si-docker

# Material Design Icons
icon: mdi-home

# Homelab Icons (dashboard-icons)
icon: hl-portainer

# Emoji
icon: 🚀

# URL
icon: https://example.com/logo.png

# Local image
icon: my-icon.png
```

### Authentication

Enable basic authentication:

```yaml
appConfig:
  auth:
    users:
      - user: admin
        hash: 4D1E58C90B3B94BCAD9848ECCACD6D2A8C9FBC5CA913304BBA5CDEAB36FEEFA3
        type: admin
      - user: guest
        hash: 5E884898DA28047151D0E56F8DC6292773603D0D6AABBDD62A11EF721D1542D8
        type: normal
```

Generate password hash:
```bash
echo -n 'your-password' | sha256sum
```

### Multi-Page Setup

Create multiple pages:

```yaml
pages:
  - name: Home
    path: home.yml
  - name: Work Services
    path: work.yml
  - name: Media
    path: https://snippet.host/xyz/raw
```

### Widgets

Add dynamic widgets:

```yaml
sections:
  - name: System Stats
    widgets:
      - type: clock
        options:
          timeZone: America/New_York
          format: en-US
          
      - type: weather
        options:
          apiKey: your-api-key
          city: New York
          units: metric
```

## Themes

### Built-in Themes

Apply a theme in `appConfig`:

```yaml
appConfig:
  theme: colorful  # colorful, nord, nord-frost, material-dark, etc.
```

Available themes: `colorful`, `nord`, `nord-frost`, `material`, `material-dark`, `material-light`, `dracula`, `nord-frost`, `high-contrast-dark`, `high-contrast-light`, `colorful-dark`, and more.

### Custom CSS

Add custom styling:

```yaml
appConfig:
  customCss: '.item { border-radius: 10px; }'
```

Or link external stylesheet:

```yaml
appConfig:
  externalStyleSheet: 'https://example.com/my-theme.css'
```

## Advanced Features

### Status Checking

Monitor service availability:

```yaml
appConfig:
  statusCheck: true
  statusCheckInterval: 300

sections:
  - name: Services
    items:
      - title: My App
        url: https://app.local
        statusCheck: true
        statusCheckHeaders:
          Authorization: Bearer token123
```

### Search Configuration

Customize search behavior:

```yaml
appConfig:
  webSearch:
    searchEngine: duckduckgo
    openingMethod: newtab
    searchBangs:
      /r: reddit
      /w: wikipedia
      /g: google
```

### Keyboard Shortcuts

Assign hotkeys to items:

```yaml
items:
  - title: Portainer
    url: https://portainer.local
    hotkey: 1  # Press '1' to open
```

Global shortcuts:
- `Esc` - Clear search / close modals
- `Enter` - Open first search result
- `Tab` / Arrow Keys - Navigate results
- `0-9` - Open item with assigned hotkey

### Workspace View

Launch multiple apps in split view:

```yaml
appConfig:
  startingView: workspace
  
items:
  - title: Service
    url: https://service.local
    target: workspace  # Open in workspace
```

## Security Best Practices

- Enable authentication for public-facing instances
- Use HTTPS via reverse proxy (NPM)
- Keep Dashy updated
- Use strong passwords (if using basic auth)
- Don't expose port 4000 directly to internet
- Regular config backups
- Use read-only config volume when possible

## Troubleshooting

**Can't access dashboard:**
- Check container is running: `docker ps | grep dashy`
- Verify port 4000 is accessible
- Check logs: `docker logs dashy`

**Changes not saving:**
- Ensure volume path exists: `/nfs/vm_shares/herta/apps/dashy/config`
- Check directory permissions
- Verify `NODE_ENV=production` is set
- Try saving locally, then to disk
- Check logs for write errors

**Status checks failing:**
- Verify services are accessible from Dashy container
- Check `statusCheckUrl` if service has different health endpoint
- Ensure CORS/authentication allows health checks
- Increase `statusCheckInterval` for slower services

**Icons not loading:**
- Check internet connectivity for favicon fetching
- Verify icon syntax (Font Awesome, Simple Icons, etc.)
- Use local icons or emojis as fallback
- Clear browser cache

**Theme not applying:**
- Check theme name spelling
- Clear browser cache
- Try incognito/private mode
- Check for custom CSS conflicts

## Useful Commands

View logs:
```bash
docker logs dashy -f
```

Restart Dashy:
```bash
docker restart dashy
```

Access container shell:
```bash
docker exec -it dashy sh
```

Backup config:
```bash
cp /nfs/vm_shares/herta/apps/dashy/config/conf.yml /nfs/vm_shares/herta/apps/dashy/config/conf.yml.backup
```

Restore config:
```bash
cp /nfs/vm_shares/herta/apps/dashy/config/conf.yml.backup /nfs/vm_shares/herta/apps/dashy/config/conf.yml
docker restart dashy
```

Rebuild container (after config changes):
```bash
docker exec dashy yarn build
docker restart dashy
```

## Cloud Backup & Sync

Dashy includes optional cloud backup:

1. Go to **Config** → **Cloud Backup**
2. Create a backup with encryption password
3. Save the backup ID
4. Restore on any Dashy instance using ID and password

All data is E2E encrypted before upload.

## Resources

- [Official Documentation](https://dashy.to/docs)
- [GitHub Repository](https://github.com/Lissy93/dashy)
- [Configuration Docs](https://github.com/Lissy93/dashy/blob/master/docs/configuring.md)
- [Widget Docs](https://github.com/Lissy93/dashy/blob/master/docs/widgets.md)
- [Theming Docs](https://github.com/Lissy93/dashy/blob/master/docs/theming.md)
- [Icon Docs](https://github.com/Lissy93/dashy/blob/master/docs/icons.md)
- [Live Demo](https://demo.dashy.to/)
- [Community Showcase](https://github.com/Lissy93/dashy/blob/master/docs/showcase.md)

## Next Steps

1. Customize your dashboard with your services
2. Set up authentication if needed
3. Configure status monitoring
4. Add widgets for dynamic content
5. Set up NPM proxy for external access
6. Explore themes and customize appearance
7. Create additional pages for organization
8. Share your dashboard in the [Showcase](https://github.com/Lissy93/dashy/blob/master/docs/showcase.md)!

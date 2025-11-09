# Homelab Docker Stack

This repository contains Docker compose stacks for managing homelab services with reverse proxy and SSL support. Services are organized by theme for easier management.

## Repository Structure

```
homelab/
├── stacks/               # Thematic grouped stacks (recommended)
│   ├── portainer/        # Container management (deploy first!)
│   ├── infrastructure/   # Networking & reverse proxy
│   ├── dashboards/       # Web dashboards & homepages
│   ├── monitoring/       # Container monitoring tools
│   ├── media-automation/ # *arr apps (Sonarr, Radarr, etc.)
│   ├── media-players/    # Media servers (Plex, Jellyfin)
│   └── development/      # IDE & terminal tools
└── apps/                 # Individual app configs (legacy)
```

## Prerequisites

**Deploy Portainer first!** It's required for managing all other stacks.

## Available Stacks

### 🐳 Portainer Stack (DEPLOY FIRST!)
Container management platform - required for deploying other stacks.

**Location**: `stacks/portainer/`
**Setup Guide**: `stacks/portainer/PORTAINER_SETUP.md`
**Stack File**: `portainer-stack.yml`

**Service Included**:
- **Portainer** - Docker container management platform
  - Web-based stack deployment
  - Container and image management
  - Network and volume management
  - Ports: 9443 (HTTPS), 9000 (HTTP), 8000 (Edge Agent)

### 🏗️ Infrastructure Stack
Essential networking and reverse proxy services.

**Location**: `stacks/infrastructure/`
**Setup Guide**: `stacks/infrastructure/INFRASTRUCTURE_SETUP.md`
**Stack File**: `infrastructure-stack.yml`

**Service Included**:
- **Nginx Proxy Manager** - Reverse proxy with SSL management
  - Web UI for managing proxy hosts and SSL certificates
  - Access control lists and stream proxies
  - Ports: 80 (HTTP), 443 (HTTPS), 81 (Web UI)

### 📊 Dashboards Stack
Web dashboards and homepage interfaces for your homelab.

**Location**: `stacks/dashboards/`
**Setup Guide**: `stacks/dashboards/DASHBOARDS_SETUP.md`
**Stack File**: `dashboards-stack.yml`

**Services Included**:
- **Homepage** - Modern application dashboard with service integrations
  - Docker auto-discovery via labels
  - 100+ service widgets
  - Port: 3000
  
- **Dashy** - Highly customizable homepage
  - Multi-page support with custom layouts
  - Real-time status monitoring
  - Port: 4000

### 📈 Monitoring Stack
Container monitoring and management tools.

**Location**: `stacks/monitoring/`
**Setup Guide**: `stacks/monitoring/MONITORING_SETUP.md`
**Stack File**: `monitoring-stack.yml`

**Services Included**:
- **Dockpeek** - Lightweight Docker dashboard
  - One-click container web access
  - Live log streaming and update detection
  - Multi-host Docker management
  - Port: 3420

- **Uptime Kuma** - Self-hosted uptime monitoring
  - Beautiful modern UI
  - Monitor HTTP(S), TCP, Ping, DNS
  - Push notifications and status pages
  - Port: 3001

### 🎬 Media Automation Stack
*arr suite for automated media management.

**Location**: `stacks/media-automation/`
**Setup Guide**: `stacks/media-automation/MEDIA_AUTOMATION_SETUP.md`
**Stack File**: `media-automation-stack.yml`

**Services Included**:
- **Sonarr** - TV show management (Port: 8989)
- **Radarr** - Movie management (Port: 7878)
- **Prowlarr** - Indexer management (Port: 9696)
- **Bazarr** - Subtitle management (Port: 6767)
- **Lidarr** - Music management (Port: 8686)
- **Readarr** - Book management (Port: 8787)

### 🎥 Media Players Stack
Media streaming servers with NFS config and CIFS media storage.

**Location**: `stacks/media-players/`
**Setup Guide**: `stacks/media-players/MEDIA_PLAYERS_SETUP.md`
**Stack File**: `media-players-stack.yml`

**Services Included**:
- **Plex** - Popular media streaming platform (Port: 32400)
- **Jellyfin** - Open-source media server (Port: 8096)

**Storage Architecture**:
- Config: NFS shared storage (`/nfs/vm_shares/cyrene/apps/`)
- Media: CIFS/SMB mount (`/mnt/media/`) - configure with `setup-cifs-media.sh`

### 💻 Development Stack
IDE and terminal management tools for development work.

**Location**: `stacks/development/`
**Setup Guide**: `stacks/development/DEVELOPMENT_SETUP.md`
**Stack File**: `development-stack.yml`

**Services Included**:
- **Code-Server** - VS Code in your browser
  - Full VS Code experience with extensions
  - Built-in terminal and Git integration
  - Port: 8443
  
- **Termix** - SSH server management platform
  - Multi-panel SSH terminal
  - SSH tunnel management
  - Remote file manager
  - Port: 8282

## Quick Start

1. Install Portainer
2. Deploy Nginx Proxy Manager stack
3. Upload SSL certificates
4. Deploy Homepage for service dashboard with integrations
5. (Optional) Deploy Dashy for alternative customizable homepage
6. Deploy Dockpeek for container monitoring

## Deployment Order

1. **Portainer Stack** (Required first - deploy manually)
   - Must be deployed via Docker Compose before using Portainer UI
   - See `stacks/portainer/PORTAINER_SETUP.md`

2. **Infrastructure Stack** (Required second)
   - Creates the nginx-proxy-manager network used by other stacks
   - See `stacks/infrastructure/INFRASTRUCTURE_SETUP.md`

3. **Dashboards Stack** (Optional)
   - Choose your preferred dashboard solution
   - See `stacks/dashboards/DASHBOARDS_SETUP.md`

4. **Monitoring Stack** (Optional)
   - Deploy for Docker container monitoring
   - See `stacks/monitoring/MONITORING_SETUP.md`

5. **Media Automation Stack** (Optional)
   - Deploy *arr apps for media management
   - See `stacks/media-automation/MEDIA_AUTOMATION_SETUP.md`

6. **Media Players Stack** (Optional)
   - Deploy Plex or Jellyfin for media streaming
   - Requires CIFS media share configured first
   - See `stacks/media-players/MEDIA_PLAYERS_SETUP.md`

7. **Development Stack** (Optional)
   - Deploy if you need code editing or SSH management
   - See `stacks/development/DEVELOPMENT_SETUP.md`

## Deployment Methods

### Initial Setup: Deploy Portainer First

**Portainer must be deployed manually via Docker Compose:**

```bash
cd stacks/portainer
docker compose -f portainer-stack.yml up -d
```

Then access Portainer at `https://your-server-ip:9443` and create your admin account.

### Option 1: Via Portainer (Recommended for other stacks)

1. Access Portainer at `https://your-server-ip:9443`
2. Go to **Stacks** → **Add stack**
3. Name your stack (e.g., "infrastructure", "dashboards", "development")
4. Upload the respective `*-stack.yml` file
5. Configure environment variables
6. Click **Deploy the stack**

### Option 2: Via Docker Compose

```bash
# Portainer (deploy first)
cd stacks/portainer
docker compose -f portainer-stack.yml up -d

# Infrastructure (deploy second)
cd stacks/infrastructure
docker compose -f infrastructure-stack.yml up -d

# Dashboards (optional)
cd stacks/dashboards
docker compose -f dashboards-stack.yml up -d

# Monitoring (optional)
cd stacks/monitoring
docker compose -f monitoring-stack.yml up -d

# Media Automation (optional)
cd stacks/media-automation
docker compose -f media-automation-stack.yml up -d

# Media Players (optional - requires CIFS setup first)
cd stacks/media-players
docker compose -f media-players-stack.yml up -d

# Development (optional)
cd stacks/development
docker compose -f development-stack.yml up -d
```

## Network Architecture

All stacks connect to the `nginx-proxy-manager` bridge network created by the Infrastructure stack. This allows:
- Central reverse proxy management
- SSL termination at the proxy level
- Easy subdomain routing
- Isolated service networks within each stack

All services communicate via container names on their respective networks. External access is controlled through Nginx Proxy Manager proxy hosts on ports 80/443.

## Environment Variables

Each stack requires a `.env` file or environment variables configured in Portainer. Common variables:

```env
TZ=America/New_York
```

See individual setup guides for stack-specific variables.

## Updating Stacks

### Via Portainer
1. Go to **Stacks** → Select your stack
2. Click **Editor** → **Pull and redeploy**

### Via Docker Compose
```bash
cd stacks/<stack-name>
docker compose -f <stack-name>-stack.yml pull
docker compose -f <stack-name>-stack.yml up -d
docker image prune -f
```

## Migrating from Individual Apps

If you have existing individual app deployments in the `apps/` directory:

1. **Backup your data** - Export configurations and note volume locations
2. **Stop old containers** - `docker stop <container-name>`
3. **Deploy new stacks** - Follow the deployment order above
4. **Verify data paths** - Ensure volume mounts match your existing data
5. **Update proxy configs** - Reconfigure Nginx Proxy Manager with new container names
6. **Remove old containers** - `docker rm <container-name>` after verification

The `apps/` directory remains for reference and individual deployments if preferred.

## Support

Each stack has its own setup guide with detailed configuration and troubleshooting:
- `stacks/portainer/PORTAINER_SETUP.md` - **Start here!**
- `stacks/infrastructure/INFRASTRUCTURE_SETUP.md`
- `stacks/dashboards/DASHBOARDS_SETUP.md`
- `stacks/monitoring/MONITORING_SETUP.md`
- `stacks/media-automation/MEDIA_AUTOMATION_SETUP.md`
- `stacks/media-players/MEDIA_PLAYERS_SETUP.md`
- `stacks/development/DEVELOPMENT_SETUP.md`

## Setup Scripts

- `setup-homelab.sh` - Main Ubuntu VM setup (NFS, Docker, firewall)
- `setup-cifs-media.sh` - CIFS/SMB media share configuration (required for media players)

## License

MIT License - Feel free to use and modify for your homelab!

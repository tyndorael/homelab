# Dashboards Stack Setup

This stack contains all dashboard and monitoring web interfaces for your homelab.

## Services Included

### Homepage
- **Purpose**: Modern, fast application dashboard with service integrations
- **Port**: 3000
- **Features**:
  - Docker service auto-discovery via labels
  - 100+ service widget integrations
  - Information widgets (weather, system stats)
  - Fully customizable themes and layouts
  - Secure API proxying

### Dashy
- **Purpose**: Highly customizable homepage and dashboard
- **Port**: 4000
- **Features**:
  - Multi-page support with custom layouts
  - Real-time status monitoring
  - Dynamic widgets and content
  - Multiple themes and customization
  - Authentication and multi-user support
  - Instant search and keyboard shortcuts

### Dockpeek
- **Purpose**: Lightweight Docker dashboard for container management
- **Port**: 3420
- **Features**:
  - One-click container web access
  - Live log streaming
  - Image update detection
  - Port mapping and management
  - Container tagging and organization

## Prerequisites

- Docker and Docker Compose installed
- NFS mount at `/nfs/vm_shares/herta` (or update volume paths)
- Infrastructure stack deployed (nginx-proxy-manager network must exist)

## Deployment

### Via Portainer (Recommended)

1. Access Portainer web UI
2. Go to **Stacks** → **Add stack**
3. Name it: `dashboards`
4. Upload or paste the contents of `dashboards-stack.yml`
5. Configure environment variables
6. Click **Deploy the stack**

### Via Docker Compose

```bash
cd stacks/dashboards
docker compose -f dashboards-stack.yml up -d
```

## Environment Variables

Create a `.env` file in the same directory:

```env
TZ=America/New_York

# Homepage
HOMEPAGE_ALLOWED_HOSTS=your-domain.com

# Dockpeek
DOCKPEEK_SECRET_KEY=your-secret-key-here
DOCKPEEK_USERNAME=admin
DOCKPEEK_PASSWORD=your-secure-password
DOCKER_HOST_1_NAME=Local
```

## Configuration

### Homepage

Configuration files are stored in `/nfs/vm_shares/herta/apps/homepage/config/`:
- `services.yaml` - Define your services and links
- `widgets.yaml` - Configure dashboard widgets
- `settings.yaml` - General settings and theme
- `bookmarks.yaml` - Quick access bookmarks

See the [Homepage documentation](https://gethomepage.dev/) for detailed configuration.

### Dashy

Configuration is stored in `/nfs/vm_shares/herta/apps/dashy/config/conf.yml`. Access the built-in config editor via the web UI.

See the [Dashy documentation](https://dashy.to/docs/) for configuration options.

### Dockpeek

Configuration is done via environment variables. To add additional Docker hosts, uncomment and configure the `DOCKER_HOST_2_*` and `DOCKER_HOST_3_*` variables in the compose file.

## Post-Deployment

Access the dashboards:
- Homepage: `http://your-server-ip:3000`
- Dashy: `http://your-server-ip:4000`
- Dockpeek: `http://your-server-ip:3420`

### Dockpeek Initial Login
- Username: Set via `DOCKPEEK_USERNAME` (default: admin)
- Password: Set via `DOCKPEEK_PASSWORD` (default: admin)

## Setting Up Reverse Proxy

Use Nginx Proxy Manager to create proxy hosts:

1. Access Nginx Proxy Manager at `http://your-server-ip:81`
2. Go to **Hosts** → **Proxy Hosts** → **Add Proxy Host**
3. Configure each dashboard:
   - **Homepage**: Forward to `homepage:3000`
   - **Dashy**: Forward to `dashy:8080`
   - **Dockpeek**: Forward to `dockpeek:8000`
4. Enable SSL certificates as needed

## Updating Services

```bash
docker compose -f dashboards-stack.yml pull
docker compose -f dashboards-stack.yml up -d
docker image prune -f
```

## Troubleshooting

### Homepage not showing Docker services
- Verify Docker socket is mounted and readable
- Check service labels in other stacks
- Review Homepage logs: `docker logs homepage`

### Dashy configuration not persisting
- Verify volume mount permissions (user 1000:1000)
- Check config file path exists
- Use the built-in config editor

### Dockpeek connection issues
- Verify SECRET_KEY is set
- Check Docker socket permissions
- Ensure nginx-proxy-manager network exists

## Choosing Your Dashboard

Each dashboard has different strengths:

- **Homepage**: Best for modern look, Docker integration, and service widgets
- **Dashy**: Best for maximum customization and multi-page layouts
- **Dockpeek**: Best for Docker-specific monitoring and quick container access

You can run all three and choose your favorite, or proxy one as your main homepage.

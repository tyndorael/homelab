# Infrastructure Stack Setup

This stack contains the networking infrastructure for your homelab.

**⚠️ Prerequisites**: Deploy Portainer first! See `stacks/portainer/PORTAINER_SETUP.md`

## Services Included

### Nginx Proxy Manager
- **Purpose**: Reverse proxy with web UI for SSL management
- **Port**: 81 (Web UI), 80 (HTTP), 443 (HTTPS)
- **Features**:
  - Beautiful web interface
  - Automatic and manual SSL certificate management
  - Access control lists
  - Stream proxies for TCP/UDP
  - Custom locations and advanced configurations

## Prerequisites

- Docker and Docker Compose installed
- **Portainer deployed and running** - See `stacks/portainer/PORTAINER_SETUP.md`

## Deployment

### Option 1: Deploy via Portainer (Recommended)

1. Access Portainer web UI at `https://your-server-ip:9443`
2. Go to **Stacks** → **Add stack**
3. Name it: `infrastructure`
4. Upload or paste the contents of `infrastructure-stack.yml`
5. Configure environment variables:
   ```env
   TZ=America/New_York
   ```
6. Click **Deploy the stack**

### Option 2: Deploy via Docker Compose

```bash
# Navigate to the infrastructure stack directory
cd stacks/infrastructure

# Deploy the stack
docker compose -f infrastructure-stack.yml up -d

# View logs
docker compose -f infrastructure-stack.yml logs -f

# Stop the stack
docker compose -f infrastructure-stack.yml down
```

## Environment Variables

Create a `.env` file in the same directory:

```env
TZ=America/New_York
```

## Initial Setup

### Nginx Proxy Manager

1. Access the web UI at `http://your-server-ip:81`
2. Default credentials:
   - Email: `admin@example.com`
   - Password: `changeme`
3. Change the default credentials immediately
4. Configure proxy hosts and SSL certificates

## Post-Deployment

1. Verify Nginx Proxy Manager is running:
   ```bash
   docker ps | grep nginx-proxy-manager
   ```

2. Access the web interface:
   - Nginx Proxy Manager: `http://your-server-ip:81`

## Updating Services

```bash
# Pull latest images
docker compose -f infrastructure-stack.yml pull

# Recreate containers with new images
docker compose -f infrastructure-stack.yml up -d

# Remove old images
docker image prune -f
```

## Troubleshooting

### Nginx Proxy Manager connection issues
- Ensure ports 80, 443, and 81 are not in use by other services
- Check firewall rules
- Verify network connectivity

## Network Architecture

This stack creates the `nginx-proxy-manager` bridge network that other services can join to be proxied. All services in other stacks should connect to this network if they need to be accessible through the reverse proxy.

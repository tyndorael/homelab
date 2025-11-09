# Monitoring Stack Setup

This stack contains monitoring and container management tools for your homelab.

## Services Included

### Dockpeek
- **Purpose**: Lightweight Docker dashboard for container management
- **Port**: 3420
- **Features**:
  - One-click container web access
  - Live log streaming
  - Image update detection
  - Port mapping and management
  - Container tagging and organization
  - Multi-host Docker management
  - Real-time container stats

## Prerequisites

- Docker and Docker Compose installed
- Infrastructure stack deployed (nginx-proxy-manager network must exist)
- Docker socket accessible

## Deployment

### Via Portainer (Recommended)

1. Access Portainer web UI
2. Go to **Stacks** → **Add stack**
3. Name it: `monitoring`
4. Upload or paste the contents of `monitoring-stack.yml`
5. Configure environment variables
6. Click **Deploy the stack**

### Via Docker Compose

```bash
cd stacks/monitoring
docker compose -f monitoring-stack.yml up -d
```

## Environment Variables

Create a `.env` file in the same directory:

```env
TZ=America/New_York

# Dockpeek
DOCKPEEK_SECRET_KEY=your-secret-key-here-change-this
DOCKPEEK_USERNAME=admin
DOCKPEEK_PASSWORD=your-secure-password
DOCKER_HOST_1_NAME=Local

# Optional: Additional Docker hosts
# DOCKER_HOST_2_URL=tcp://remote-server:2375
# DOCKER_HOST_2_NAME=Remote Server
# DOCKER_HOST_2_PUBLIC_HOSTNAME=remote.example.com
```

## Configuration

### Dockpeek

Configuration is done via environment variables in the compose file.

#### Adding Multiple Docker Hosts

To monitor multiple Docker servers:

1. Uncomment the `DOCKER_HOST_2_*` variables in the compose file
2. Set the Docker host URL (e.g., `tcp://192.168.1.100:2375` or `unix:///var/run/docker.sock`)
3. Set a friendly name for the host
4. Optionally set the public hostname for web access links
5. Add more hosts by following the same pattern with `DOCKER_HOST_3_*`, etc.

**Example for remote host:**
```yaml
- DOCKER_HOST_2_URL=tcp://192.168.1.100:2375
- DOCKER_HOST_2_NAME=Production Server
- DOCKER_HOST_2_PUBLIC_HOSTNAME=prod.example.com
```

#### Security Notes

When connecting to remote Docker hosts:
- Use TLS-secured connections when possible
- Consider using SSH tunnels: `ssh://user@host`
- Restrict Docker API access with firewall rules
- Use Docker context for secure connections

## Post-Deployment

Access Dockpeek:
- Dockpeek: `http://your-server-ip:3420`

### Initial Login
- Username: Set via `DOCKPEEK_USERNAME` (default: admin)
- Password: Set via `DOCKPEEK_PASSWORD` (default: admin)

**⚠️ Change the default password immediately!**

## Setting Up Reverse Proxy

Use Nginx Proxy Manager to create a proxy host:

1. Access Nginx Proxy Manager at `http://your-server-ip:81`
2. Go to **Hosts** → **Proxy Hosts** → **Add Proxy Host**
3. Configure:
   - **Domain Names**: `dockpeek.your-domain.com`
   - **Forward Hostname/IP**: `dockpeek`
   - **Forward Port**: `8000`
   - **Scheme**: `http`
   - Enable **Websockets Support** (required for live logs)
   - Enable SSL certificate
4. Click **Save**

## Features and Usage

### Container Management
- Start, stop, restart, and remove containers
- View real-time logs with live streaming
- Access container web interfaces with one click
- Inspect container details and environment variables

### Image Management
- View all Docker images
- Check for image updates
- Pull new image versions
- Remove unused images

### Network and Volume Management
- View Docker networks and their connections
- Manage Docker volumes
- Inspect volume usage and data

### Tagging and Organization
- Tag containers for better organization
- Filter containers by tags
- Group related containers together

### Port Mapping
- View all exposed ports
- Quick access to service web interfaces
- Port range grouping for cleaner display

## Updating Services

```bash
docker compose -f monitoring-stack.yml pull
docker compose -f monitoring-stack.yml up -d
docker image prune -f
```

## Troubleshooting

### Cannot connect to Docker
- Verify Docker socket is mounted: `ls -la /var/run/docker.sock`
- Check Docker socket permissions: `sudo chmod 666 /var/run/docker.sock`
- Ensure Docker service is running: `sudo systemctl status docker`

### Remote host connection issues
- Verify Docker API is exposed on remote host
- Check firewall rules allow connection
- Test connection: `curl http://remote-host:2375/version`
- Consider using SSH tunnel for security

### Dockpeek login issues
- Verify `SECRET_KEY` is set and consistent
- Check username and password environment variables
- Clear browser cache and cookies
- Check logs: `docker logs dockpeek`

### Live logs not updating
- Ensure WebSockets support is enabled in reverse proxy
- Check browser console for WebSocket errors
- Verify network connectivity

### Permission errors
- Dockpeek needs read-only access to Docker socket
- Check socket mount: `/var/run/docker.sock:/var/run/docker.sock:ro`
- Verify container has socket access

## Security Best Practices

1. **Change Default Credentials** - Set strong username and password
2. **Use SECRET_KEY** - Generate a strong random secret key
3. **Read-Only Socket** - Keep Docker socket mounted as `:ro` (read-only)
4. **Reverse Proxy** - Access via HTTPS through Nginx Proxy Manager
5. **Firewall Rules** - Don't expose port 3420 to the internet
6. **Remote Connections** - Use TLS or SSH tunnels for remote Docker hosts
7. **Regular Updates** - Keep Dockpeek image updated

## Adding More Monitoring Tools

This monitoring stack can be expanded with additional tools:

- **Grafana** - Metrics visualization and dashboards
- **Prometheus** - Metrics collection and alerting
- **Uptime Kuma** - Service uptime monitoring
- **Netdata** - Real-time system monitoring
- **cAdvisor** - Container metrics collector

Example additions can be made to this stack file as your monitoring needs grow.

## Next Steps

After deploying the monitoring stack:

1. ✅ Access Dockpeek and change default password
2. 🔒 Set up reverse proxy with SSL
3. 🏷️ Tag your containers for better organization
4. 📊 Monitor container health and resource usage
5. 🔄 Set up alerts for container failures (future enhancement)

## Resources

- [Dockpeek Documentation](https://dockpeek.com/docs) (if available)
- [Docker API Documentation](https://docs.docker.com/engine/api/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)

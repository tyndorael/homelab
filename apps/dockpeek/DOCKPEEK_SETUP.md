# Dockpeek Setup Guide

Dockpeek is a lightweight Docker dashboard for quick access to your containers. View web interfaces, logs, ports, and update images from one clean interface.

## Features

✅ **One-click web access** - Instantly open container dashboards
✅ **Automatic port mapping** - Detect and display all published ports
✅ **Live container logs** - Stream logs in real time
✅ **Traefik integration** - Automatically extract service URLs from labels
✅ **Image update checks** - Detect and upgrade outdated containers
✅ **Port range grouping** - Clean display of consecutive ports
✅ **Container tagging** - Organize with custom tags

## Installation Steps

### 1. Configure Environment Variables

Create or update your `.env` file with:

```env
TZ=America/New_York
DOCKPEEK_SECRET_KEY=your_secure_random_secret_key_here
DOCKPEEK_USERNAME=admin
DOCKPEEK_PASSWORD=your_secure_password

# Local Docker Host (required)
DOCKER_HOST_1_NAME=Local Server

# Remote Docker Host 2 (optional) - Uncomment to enable
# DOCKER_HOST_2_URL=tcp://192.168.1.100:2375
# DOCKER_HOST_2_NAME=Remote Server
# DOCKER_HOST_2_PUBLIC_HOSTNAME=server.local

# Remote Docker Host 3 (optional) - Add more as needed
# DOCKER_HOST_3_URL=tcp://192.168.1.101:2375
# DOCKER_HOST_3_NAME=Another Server
# DOCKER_HOST_3_PUBLIC_HOSTNAME=server2.local
```

**Important**: Generate a secure random secret key for `DOCKPEEK_SECRET_KEY`

### 2. Deploy in Portainer

1. Go to **Stacks** → **Add stack**
2. Name it "dockpeek"
3. Upload `dockpeek-stack.yml` or paste its contents
4. Add environment variables from your `.env` file
5. Click **Deploy the stack**

### 3. Initial Access

1. Access Dockpeek at `http://your-vm-ip:3420`
2. Login with your configured username and password
3. You should see all your Docker containers

### 4. (Optional) Configure Nginx Proxy Manager

To access via a custom domain:

1. In NPM, create a new Proxy Host:
   - **Domain**: `dockpeek.yourdomain.com`
   - **Forward Hostname**: `dockpeek`
   - **Forward Port**: `8000`
   - Enable **Websockets Support**
   
2. Go to **SSL** tab:
   - Select your SSL certificate
   - Enable **Force SSL**, **HTTP/2**, and **HSTS**
   - Save

Access at: `https://dockpeek.yourdomain.com`

## Container Labels

Add labels to your containers to customize their appearance in Dockpeek:

```yaml
labels:
  - "dockpeek.ports=8080,9090"              # Show additional ports
  - "dockpeek.https=3001,8080"              # Force HTTPS for ports
  - "dockpeek.link=https://myapp.local"     # Make container name clickable
  - "dockpeek.tags=frontend,production"     # Add organization tags
  - "dockpeek.port-range-grouping=false"    # Disable port grouping
```

## Configuration Options

Available environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `SECRET_KEY` | Required | Essential for security and sessions |
| `USERNAME` | Required | Dashboard login username |
| `PASSWORD` | Required | Dashboard login password |
| `PORT` | 8000 | Application port |
| `TRAEFIK_LABELS` | true | Show Traefik column |
| `TAGS` | true | Show tags column |
| `PORT_RANGE_GROUPING` | true | Group consecutive ports |
| `PORT_RANGE_THRESHOLD` | 5 | Min ports to group as range |
| `TRUST_PROXY_HEADERS` | false | Enable X-Forwarded-* headers |
| `TRUSTED_PROXY_COUNT` | 1 | Number of trusted proxies |
| `DOCKER_CONNECTION_TIMEOUT` | 2 | Connection timeout in seconds |

### Multi-Host Configuration

To manage multiple Docker hosts from a single Dockpeek instance:

1. **Configure in `.env` file:**
```env
# Remote Docker Host 2
DOCKER_HOST_2_URL=tcp://192.168.1.100:2375
DOCKER_HOST_2_NAME=Production Server
DOCKER_HOST_2_PUBLIC_HOSTNAME=prod.local

# Remote Docker Host 3
DOCKER_HOST_3_URL=tcp://192.168.1.101:2375
DOCKER_HOST_3_NAME=Development Server
DOCKER_HOST_3_PUBLIC_HOSTNAME=dev.local
```

2. **Uncomment the corresponding lines** in `dockpeek-stack.yml`

3. **Redeploy the stack** in Portainer

**Remote Host Requirements:**
- Each remote host needs Docker API exposed via TCP
- Use Docker Socket Proxy for security (recommended)
- Ensure network connectivity between Dockpeek and remote hosts
- Format: `tcp://hostname-or-ip:port`

**Example Remote Setup with Socket Proxy:**
On each remote host, deploy a socket proxy:
```yaml
services:
  socket-proxy:
    image: lscr.io/linuxserver/socket-proxy:latest
    container_name: socket-proxy
    environment:
      - CONTAINERS=1
      - IMAGES=1
      - NETWORKS=1
      - SERVICES=1
      - TASKS=1
      - POST=1
    ports:
      - "2375:2375"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    restart: unless-stopped
```

## Features in Action

### Check for Updates
- View which containers have newer images available
- Update containers with one click
- Supports floating tags (latest, major, minor versions)

### View Logs
- Stream container logs in real-time
- Search and filter log output
- Download logs for troubleshooting

### Port Management
- See all exposed ports
- Click to open in browser
- Automatic HTTPS detection
- Custom port configuration via labels

### Organization
- Tag containers for easy filtering
- Search by name, tag, or port
- Clean grouped display

## Security Best Practices

- Use a strong, random `SECRET_KEY`
- Change default username/password
- Don't expose port 3420 to the internet (use NPM instead)
- Use read-only Docker socket mount
- Keep Dockpeek updated
- Enable proxy headers only when behind a reverse proxy

## Troubleshooting

**Can't access dashboard:**
- Check container is running: `docker ps | grep dockpeek`
- Verify port 3420 is not blocked by firewall
- Check logs: `docker logs dockpeek`

**Containers not showing:**
- Ensure Docker socket is mounted correctly
- Check socket permissions
- Verify container has access to `/var/run/docker.sock`

**Login fails:**
- Verify `SECRET_KEY` is set
- Check `USERNAME` and `PASSWORD` environment variables
- Review logs for authentication errors

**Updates not working:**
- Ensure Dockpeek has Docker API access
- Check socket proxy permissions if using one
- Verify container has necessary permissions

## Useful Commands

View logs:
```bash
docker logs dockpeek -f
```

Restart Dockpeek:
```bash
docker restart dockpeek
```

Check container status:
```bash
docker ps | grep dockpeek
```

## Advanced: Socket Proxy

For enhanced security, use a socket proxy to limit Docker API access:

```yaml
services:
  dockpeek:
    image: dockpeek/dockpeek:latest
    environment:
      - SECRET_KEY=your_secure_secret_key
      - USERNAME=admin
      - PASSWORD=admin
      - DOCKER_HOST=tcp://socket-proxy:2375
    ports:
      - "3420:8000"
    depends_on:
      - socket-proxy
    restart: unless-stopped

  socket-proxy:
    image: lscr.io/linuxserver/socket-proxy:latest
    container_name: dockpeek-socket-proxy
    environment:
      - CONTAINERS=1
      - IMAGES=1
      - PING=1
      - VERSION=1
      - INFO=1
      - POST=1
      - ALLOW_START=1
      - ALLOW_STOP=1
      - ALLOW_RESTARTS=1
      - NETWORKS=1
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    read_only: true
    tmpfs:
      - /run
    restart: unless-stopped
```

## Resources

- [GitHub Repository](https://github.com/dockpeek/dockpeek)
- [Docker Hub](https://hub.docker.com/r/dockpeek/dockpeek)
- [Latest Release](https://github.com/dockpeek/dockpeek/releases)

## Next Steps

1. Customize container labels for better organization
2. Set up NPM proxy for secure external access
3. Explore update checking features
4. Configure multi-host management (optional)

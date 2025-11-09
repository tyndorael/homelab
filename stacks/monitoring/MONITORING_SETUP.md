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

### Uptime Kuma
- **Purpose**: Self-hosted uptime monitoring tool
- **Port**: 3001
- **Features**:
  - Beautiful and modern UI
  - Monitor HTTP(S), TCP, Ping, DNS, and more
  - Push notifications (Discord, Telegram, Slack, Email, etc.)
  - Status pages (public or private)
  - Multiple notification channels
  - Certificate expiry monitoring
  - Multi-language support
  - 2FA authentication

## Prerequisites

- Docker and Docker Compose installed
- NFS mount at `/nfs/vm_shares/herta` (or update volume paths)
- Infrastructure stack deployed (nginx-proxy-manager network must exist)
- Docker socket accessible

## Directory Setup

Before deploying, create the necessary directories:

```bash
# Create Uptime Kuma data directory
sudo mkdir -p /nfs/vm_shares/herta/apps/uptime-kuma/data

**Note**: If you ran the setup script with the optional directory creation, these directories are already created.

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

To monitor multiple Docker servers, you need to expose the Docker API on remote VMs.

**Step 1: On Each Remote Docker Host VM**

1. **Edit Docker daemon configuration:**
   ```bash
   sudo nano /etc/docker/daemon.json
   ```

2. **Add TCP socket configuration:**
   ```json
   {
     "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2375"]
   }
   ```

3. **Create systemd override:**
   ```bash
   sudo mkdir -p /etc/systemd/system/docker.service.d
   sudo nano /etc/systemd/system/docker.service.d/override.conf
   ```
   
   Add this content:
   ```ini
   [Service]
   ExecStart=
   ExecStart=/usr/bin/dockerd
   ```

4. **Reload and restart Docker:**
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl restart docker
   ```

5. **Open firewall port (restrict to monitoring VM IP):**
   ```bash
   # Replace MONITORING_VM_IP with your Dockpeek host's IP
   sudo ufw allow from MONITORING_VM_IP to any port 2375 proto tcp comment 'Docker API for Dockpeek'
   
   # Example:
   sudo ufw allow from 192.168.50.100 to any port 2375 proto tcp comment 'Docker API for Dockpeek'
   
   # Verify
   sudo ufw status
   ```

6. **Test Docker API (from monitoring VM):**
   ```bash
   curl http://REMOTE_VM_IP:2375/version
   ```

**Step 2: Configure Dockpeek**

1. Edit `monitoring-stack.yml` and uncomment remote host entries:
   ```yaml
   # Docker Host 2 (Herta VM)
   - DOCKER_HOST_2_URL=tcp://192.168.50.105:2375
   - DOCKER_HOST_2_NAME=Herta VM
   - DOCKER_HOST_2_PUBLIC_HOSTNAME=herta.local
   
   # Docker Host 3 (Cyrene VM)
   - DOCKER_HOST_3_URL=tcp://192.168.50.107:2375
   - DOCKER_HOST_3_NAME=Cyrene VM
   - DOCKER_HOST_3_PUBLIC_HOSTNAME=cyrene.local
   ```

2. **Redeploy the stack:**
   ```bash
   cd stacks/monitoring
   docker compose -f monitoring-stack.yml down
   docker compose -f monitoring-stack.yml up -d
   ```

3. **Verify in Dockpeek:**
   - Access Dockpeek at `http://YOUR_IP:3420`
   - You should see all configured hosts in the host selector dropdown

**Security Note**: TCP port 2375 is unencrypted. For production environments, consider:
- Using Docker over SSH instead
- Implementing TLS on port 2376
- Restricting firewall rules to specific IPs only
- Using a VPN or private network

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

Access the monitoring tools:
- Dockpeek: `http://your-server-ip:3420`
- Uptime Kuma: `http://your-server-ip:3001`

### Dockpeek Initial Login
- Username: Set via `DOCKPEEK_USERNAME` (default: admin)
- Password: Set via `DOCKPEEK_PASSWORD` (default: admin)

**⚠️ Change the default password immediately!**

### Uptime Kuma Initial Setup
1. Access Uptime Kuma at `http://your-server-ip:3001`
2. Create your admin account on first visit
3. Start adding monitors for your services
4. Configure notification channels (optional)

## Setting Up Reverse Proxy

Use Nginx Proxy Manager to create proxy hosts:

1. Access Nginx Proxy Manager at `http://your-server-ip:81`
2. Go to **Hosts** → **Proxy Hosts** → **Add Proxy Host**

### Dockpeek Proxy
3. Configure:
   - **Domain Names**: `dockpeek.your-domain.com`
   - **Forward Hostname/IP**: `dockpeek`
   - **Forward Port**: `8000`
   - **Scheme**: `http`
   - Enable **Websockets Support** (required for live logs)
   - Enable SSL certificate
4. Click **Save**

### Uptime Kuma Proxy
5. Add another proxy host:
   - **Domain Names**: `uptime.your-domain.com`
   - **Forward Hostname/IP**: `uptime-kuma`
   - **Forward Port**: `3001`
   - **Scheme**: `http`
   - Enable **Websockets Support** (required for real-time updates)
   - Enable SSL certificate
6. Click **Save**

## Features and Usage

### Dockpeek - Container Management
- Start, stop, restart, and remove containers
- View real-time logs with live streaming
- Access container web interfaces with one click
- Inspect container details and environment variables
- View all Docker images and check for updates
- Manage Docker networks and volumes
- Tag containers for better organization

### Uptime Kuma - Service Monitoring
- **Adding Monitors**: Click "+ New Monitor" to add services
- **Monitor Types**:
  - HTTP(S) - Monitor websites and APIs
  - TCP Port - Check if ports are open
  - Ping - Basic connectivity check
  - DNS - Monitor DNS resolution
  - Docker Container - Monitor container health
  - Push - Receive push notifications
- **Notifications**: Configure alerts via Discord, Telegram, Slack, Email, etc.
- **Status Pages**: Create public or private status pages for your services
- **Tags**: Organize monitors with tags
- **Maintenance Windows**: Schedule maintenance to pause alerts

## Updating Services

```bash
docker compose -f monitoring-stack.yml pull
docker compose -f monitoring-stack.yml up -d
docker image prune -f
```

## Troubleshooting

### Dockpeek Issues

#### Cannot connect to Docker
- Verify Docker socket is mounted: `ls -la /var/run/docker.sock`
- Check Docker socket permissions: `sudo chmod 666 /var/run/docker.sock`
- Ensure Docker service is running: `sudo systemctl status docker`

#### Remote host connection issues
- Verify Docker API is exposed on remote host
- Check firewall rules allow connection
- Test connection: `curl http://remote-host:2375/version`
- Consider using SSH tunnel for security

#### Dockpeek login issues
- Verify `SECRET_KEY` is set and consistent
- Check username and password environment variables
- Clear browser cache and cookies
- Check logs: `docker logs dockpeek`

#### Live logs not updating
- Ensure WebSockets support is enabled in reverse proxy
- Check browser console for WebSocket errors
- Verify network connectivity

### Uptime Kuma Issues

#### Cannot access web UI
- Verify container is running: `docker ps | grep uptime-kuma`
- Check logs: `docker logs uptime-kuma`
- Ensure port 3001 is not in use: `netstat -tulpn | grep 3001`

#### Notifications not working
- Verify notification channel configuration
- Test the notification channel from Uptime Kuma settings
- Check firewall/network allows outbound connections
- Review Uptime Kuma logs for errors

#### Database errors
- Data is stored in `/nfs/vm_shares/herta/apps/uptime-kuma/data`
- Backup this directory before upgrades
- Check directory permissions (should be writable by container)

#### Monitors showing as down
- Verify the monitored service is actually running
- Check network connectivity from container
- Try increasing timeout values
- Review monitor logs in Uptime Kuma

## Security Best Practices

1. **Change Default Credentials** - Set strong username and password for Dockpeek
2. **Use SECRET_KEY** - Generate a strong random secret key for Dockpeek
3. **Read-Only Socket** - Keep Docker socket mounted as `:ro` (read-only) in Dockpeek
4. **Reverse Proxy** - Access via HTTPS through Nginx Proxy Manager
5. **Firewall Rules** - Don't expose ports 3420 or 3001 to the internet
6. **Remote Connections** - Use TLS or SSH tunnels for remote Docker hosts
7. **Regular Updates** - Keep all images updated
8. **Enable 2FA** - Enable two-factor authentication in Uptime Kuma
9. **Backup Data** - Regular backup of `/nfs/vm_shares/herta/apps/uptime-kuma/data`
10. **Status Page Privacy** - Use authentication for sensitive status pages

## Expanding Your Monitoring

This monitoring stack can be further expanded with additional tools:

- **Grafana** - Metrics visualization and dashboards
- **Prometheus** - Metrics collection and alerting
- **Netdata** - Real-time system monitoring
- **cAdvisor** - Container metrics collector
- **Loki** - Log aggregation system

These can be added to the monitoring stack as needed.

## Example Monitors to Add in Uptime Kuma

Once Uptime Kuma is running, consider adding monitors for:

1. **Portainer** - `https://your-domain.com:9443` (HTTPS)
2. **Nginx Proxy Manager** - `http://nginx-proxy-manager:81` (HTTP)
3. **Homepage** - `http://homepage:3000` (HTTP)
4. **Dashy** - `http://dashy:8080` (HTTP)
5. **Your public website** - External URL monitoring
6. **SSL Certificates** - Certificate expiry monitoring
7. **DNS Records** - DNS resolution checks
8. **Database** - TCP port monitoring
9. **NFS Server** - Ping monitoring

## Next Steps

After deploying the monitoring stack:

1. ✅ Access Uptime Kuma and create admin account
2. ✅ Access Dockpeek and change default password
3. 🔒 Set up reverse proxy with SSL for both services
4. 📊 Add monitors for all your critical services
5. � Configure notification channels (Discord, Telegram, Email, etc.)
6. � Create a status page for your services
7. 🏷️ Tag your containers in Dockpeek for organization
8. 💾 Set up regular backups of Uptime Kuma data

## Resources

- [Dockpeek Documentation](https://dockpeek.com/docs) (if available)
- [Uptime Kuma GitHub](https://github.com/louislam/uptime-kuma)
- [Uptime Kuma Wiki](https://github.com/louislam/uptime-kuma/wiki)
- [Docker API Documentation](https://docs.docker.com/engine/api/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)

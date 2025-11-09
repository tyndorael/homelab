# Portainer Stack Setup

**⚠️ DEPLOY THIS STACK FIRST!**

Portainer is the container management platform that you'll use to deploy all other stacks. It must be deployed manually before anything else.

## What is Portainer?

Portainer provides a web-based UI for managing Docker containers, images, networks, and volumes. It's essential for deploying and managing your other homelab stacks through an easy-to-use interface.

## Prerequisites

- Docker and Docker Compose installed
- NFS mount at `/nfs/vm_shares/herta` (or update the volume path)

## Initial Deployment

**You MUST deploy Portainer manually via Docker Compose first:**

```bash
# Navigate to the portainer stack directory
cd stacks/portainer

# Deploy Portainer
docker compose -f portainer-stack.yml up -d

# Check if it's running
docker ps | grep portainer
```

## First-Time Setup

1. **Access Portainer** at `https://your-server-ip:9443` (or `http://your-server-ip:9000`)

2. **Create Admin Account** within 5 minutes of first start:
   - Choose a username
   - Set a strong password (minimum 12 characters)
   - Confirm the password

3. **Select Environment**: Choose "Get Started" to use the local Docker environment

4. **You're Ready!** Now you can deploy other stacks through the Portainer UI

## Ports

- **9443**: HTTPS Web UI (recommended)
- **9000**: HTTP Web UI
- **8000**: Edge Agent (optional, for managing remote Docker environments)

## Deploying Other Stacks via Portainer

Once Portainer is running:

1. Go to **Stacks** in the left menu
2. Click **+ Add stack**
3. Enter a name (e.g., "infrastructure", "dashboards", "development")
4. Choose upload method:
   - **Web editor**: Paste the stack YAML content
   - **Upload**: Upload the `*-stack.yml` file
   - **Repository**: Connect to a Git repository
5. Configure environment variables if needed
6. Click **Deploy the stack**

## Recommended Deployment Order

1. ✅ **Portainer** (you're here - deploy first!)
2. **Infrastructure** - `stacks/infrastructure/` (creates nginx-proxy-manager network)
3. **Dashboards** - `stacks/dashboards/` (optional)
4. **Development** - `stacks/development/` (optional)

## Environment Variables

Create a `.env` file if needed:

```env
TZ=America/New_York
```

## Updating Portainer

### Via Docker Compose

```bash
cd stacks/portainer
docker compose -f portainer-stack.yml pull
docker compose -f portainer-stack.yml up -d
docker image prune -f
```

### Via Portainer UI (Self-Update)

1. Go to **Containers**
2. Select the `portainer` container
3. Click **Recreate**
4. Enable "Pull latest image"
5. Click **Recreate**

## Data Persistence

Portainer data is stored at:
- `/nfs/vm_shares/herta/apps/portainer/data`

This includes:
- User accounts and settings
- Stack definitions
- Custom templates
- Access control configurations

**Backup this directory regularly!**

## Troubleshooting

### Can't access the web UI
- Check if Portainer is running: `docker ps | grep portainer`
- Verify ports 9443/9000 aren't in use: `netstat -tulpn | grep -E '9443|9000'`
- Check firewall rules
- View logs: `docker logs portainer`

### Admin account creation timeout
If you didn't create an account within 5 minutes:
```bash
# Restart Portainer to reset the timer
docker restart portainer
```

### Permission errors with Docker socket
```bash
# Verify Docker socket permissions
ls -la /var/run/docker.sock

# The socket should be accessible by your user or the docker group
```

### Volume mount issues
```bash
# Create the data directory if it doesn't exist
mkdir -p /nfs/vm_shares/herta/apps/portainer/data

# Set ownership
sudo chown -R 1000:1000 /nfs/vm_shares/herta/apps/portainer/data
```

## Security Recommendations

1. **Use HTTPS** - Access via port 9443 instead of 9000
2. **Strong Password** - Use a password manager to generate a secure password
3. **Enable 2FA** - Configure in User Settings after first login
4. **Regular Updates** - Keep Portainer updated to the latest version
5. **Backup Data** - Regularly backup the data volume
6. **Firewall Rules** - Don't expose Portainer directly to the internet
7. **Use Reverse Proxy** - Access via Nginx Proxy Manager with SSL

## Setting Up Reverse Proxy (After Infrastructure Stack)

Once you've deployed the Infrastructure stack with Nginx Proxy Manager:

1. Access Nginx Proxy Manager at `http://your-server-ip:81`
2. Go to **Hosts** → **Proxy Hosts** → **Add Proxy Host**
3. Configure:
   - **Domain Names**: `portainer.your-domain.com`
   - **Forward Hostname/IP**: `portainer`
   - **Forward Port**: `9000`
   - **Scheme**: `http`
   - Enable **Websockets Support**
   - Enable SSL certificate
4. Click **Save**

Now you can access Portainer at `https://portainer.your-domain.com`

## Next Steps

After Portainer is running:

1. ✅ Portainer deployed and configured
2. 📦 Deploy Infrastructure stack → `stacks/infrastructure/INFRASTRUCTURE_SETUP.md`
3. 📊 Deploy Dashboards stack → `stacks/dashboards/DASHBOARDS_SETUP.md`
4. 💻 Deploy Development stack → `stacks/development/DEVELOPMENT_SETUP.md`

## Resources

- [Portainer Documentation](https://docs.portainer.io/)
- [Portainer Community](https://www.portainer.io/community)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

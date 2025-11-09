# Homelab Setup Guide for Ubuntu VM (Proxmox)

This guide walks you through setting up your Ubuntu VM in Proxmox for running the homelab Docker stacks.

## Prerequisites

- Ubuntu Server 22.04 LTS or newer installed on Proxmox VM
- Root or sudo access to the VM
- NFS server configured (optional, for shared storage)
- Network connectivity to NFS server

## Quick Start

### 1. Download the Setup Script

SSH into your Ubuntu VM and download the setup script:

```bash
# Using git (recommended)
git clone https://github.com/yourusername/homelab.git
cd homelab
chmod +x setup-homelab.sh

# Or download directly
wget https://raw.githubusercontent.com/yourusername/homelab/main/setup-homelab.sh
chmod +x setup-homelab.sh
```

### 2. Configure the Script (Optional)

Edit the script to customize your NFS settings:

```bash
nano setup-homelab.sh
```

Update these variables at the top of the script:

```bash
NFS_SERVER_IP="192.168.1.100"           # Your NFS server IP
NFS_EXPORT_PATH="/mnt/storage/vm_shares/herta"  # NFS export path
LOCAL_MOUNT_POINT="/nfs/vm_shares/herta"  # Local mount point
```

### 3. Run the Setup Script

```bash
sudo ./setup-homelab.sh
```

The script will:
- ✓ Update system packages
- ✓ Install Docker and Docker Compose
- ✓ Install useful utilities (htop, vim, git, etc.)
- ✓ Configure NFS client and mount shared volumes
- ✓ Create application directories
- ✓ Set proper permissions (UID:GID 1000:1000)
- ✓ Configure firewall rules (UFW)
- ✓ Enable Fail2Ban for SSH protection
- ✓ Create environment variable template

### 4. Post-Setup

After the script completes:

1. **Log out and back in** for Docker group changes to take effect:
   ```bash
   exit
   # SSH back in
   ```

2. **Verify Docker installation**:
   ```bash
   docker run hello-world
   docker compose version
   ```

3. **Check NFS mount**:
   ```bash
   df -h | grep nfs
   ls -la /nfs/vm_shares/herta/apps
   ```

## Manual Installation Steps

If you prefer to install manually or the script fails, follow these steps:

### Install Docker

```bash
# Remove old versions
sudo apt-get remove docker docker-engine docker.io containerd runc

# Update and install prerequisites
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Set up the repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add your user to docker group
sudo usermod -aG docker $USER

# Log out and back in, then test
docker run hello-world
```

### Configure NFS Client

```bash
# Install NFS client
sudo apt-get install -y nfs-common

# Create mount point
sudo mkdir -p /nfs/vm_shares/herta

# Test mount
sudo mount -t nfs 192.168.1.100:/mnt/storage/vm_shares/herta /nfs/vm_shares/herta

# Add to /etc/fstab for automatic mounting
echo "192.168.1.100:/mnt/storage/vm_shares/herta /nfs/vm_shares/herta nfs defaults,_netdev 0 0" | sudo tee -a /etc/fstab

# Verify mount
df -h | grep nfs
```

### Create Application Directories

```bash
# Create directory structure
sudo mkdir -p /nfs/vm_shares/herta/apps/{portainer,nginx-proxy-manager,homepage,dashy,dockpeek,code-server,termix}
sudo mkdir -p /nfs/vm_shares/herta/apps/portainer/data
sudo mkdir -p /nfs/vm_shares/herta/apps/homepage/config
sudo mkdir -p /nfs/vm_shares/herta/apps/dashy/config
sudo mkdir -p /nfs/vm_shares/herta/apps/code-server/{config,projects}

# Set ownership (UID:GID 1000:1000)
sudo chown -R 1000:1000 /nfs/vm_shares/herta/apps
sudo chmod -R 755 /nfs/vm_shares/herta/apps
```

### Configure Firewall

```bash
# Install UFW
sudo apt-get install -y ufw

# Allow SSH (important!)
sudo ufw allow 22/tcp comment 'SSH'

# Allow application ports
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
sudo ufw allow 81/tcp comment 'Nginx Proxy Manager'
sudo ufw allow 9443/tcp comment 'Portainer HTTPS'
sudo ufw allow 9000/tcp comment 'Portainer HTTP'
sudo ufw allow 3000/tcp comment 'Homepage'
sudo ufw allow 4000/tcp comment 'Dashy'
sudo ufw allow 3420/tcp comment 'Dockpeek'
sudo ufw allow 8443/tcp comment 'Code-Server'
sudo ufw allow 8282/tcp comment 'Termix'

# Enable firewall
sudo ufw --force enable

# Check status
sudo ufw status numbered
```

## Deploying the Stacks

### 1. Deploy Portainer (First!)

```bash
cd homelab/stacks/portainer
docker compose -f portainer-stack.yml up -d
```

Access Portainer at `https://VM-IP:9443` and create your admin account.

### 2. Deploy Infrastructure Stack

Via Portainer UI:
1. Go to **Stacks** → **Add stack**
2. Name: `infrastructure`
3. Upload `stacks/infrastructure/infrastructure-stack.yml`
4. Deploy

Or via command line:
```bash
cd homelab/stacks/infrastructure
docker compose -f infrastructure-stack.yml up -d
```

### 3. Deploy Other Stacks

Deploy dashboards and development stacks as needed through Portainer UI.

## Environment Variables

Create a `.env` file in each stack directory or configure in Portainer:

```env
# Common
TZ=America/New_York

# Dockpeek
DOCKPEEK_SECRET_KEY=your-secret-key-here
DOCKPEEK_USERNAME=admin
DOCKPEEK_PASSWORD=your-secure-password

# Code-Server
CODE_SERVER_PASSWORD=your-password
CODE_SERVER_SUDO_PASSWORD=your-sudo-password
CODE_SERVER_PROXY_DOMAIN=code.yourdomain.com

# Homepage
HOMEPAGE_ALLOWED_HOSTS=yourdomain.com,localhost
```

## Troubleshooting

### Docker Permission Denied

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, or run
newgrp docker
```

### NFS Mount Issues

```bash
# Check if NFS server is reachable
ping YOUR_NFS_SERVER_IP

# Test mount manually
sudo mount -t nfs YOUR_NFS_SERVER_IP:/export/path /nfs/vm_shares/herta

# Check mount status
df -h | grep nfs
mount | grep nfs

# View NFS exports on server
showmount -e YOUR_NFS_SERVER_IP
```

### Firewall Blocking Connections

```bash
# Check firewall status
sudo ufw status verbose

# Allow a specific port
sudo ufw allow PORT/tcp

# Disable firewall temporarily (for testing)
sudo ufw disable

# Re-enable
sudo ufw enable
```

### Container Permission Issues

```bash
# Check directory ownership
ls -la /nfs/vm_shares/herta/apps

# Fix ownership
sudo chown -R 1000:1000 /nfs/vm_shares/herta/apps

# Fix permissions
sudo chmod -R 755 /nfs/vm_shares/herta/apps
```

## VM Recommended Specifications

### Minimal Setup
- **CPU**: 2 cores
- **RAM**: 4 GB
- **Disk**: 32 GB
- **Network**: Bridged adapter

### Recommended Setup
- **CPU**: 4 cores
- **RAM**: 8 GB
- **Disk**: 64 GB
- **Network**: Bridged adapter

### For Development Stack
- **CPU**: 4-6 cores
- **RAM**: 12-16 GB
- **Disk**: 128 GB
- **Network**: Bridged adapter

## Useful Commands

```bash
# Check Docker status
sudo systemctl status docker

# View running containers
docker ps

# View all containers
docker ps -a

# Check Docker logs
docker logs CONTAINER_NAME

# Restart Docker service
sudo systemctl restart docker

# View NFS mounts
df -h | grep nfs

# Check firewall rules
sudo ufw status numbered

# View system resources
htop

# Check disk usage
df -h
ncdu /nfs/vm_shares/herta

# View network connections
netstat -tulpn
```

## Security Best Practices

1. **Change default passwords** - Update all default credentials immediately
2. **Use strong passwords** - Generate with password manager
3. **Enable Fail2Ban** - Protects against brute-force attacks (enabled by script)
4. **Configure firewall** - Only allow necessary ports
5. **Keep system updated** - Regular apt updates
6. **Use HTTPS** - Configure SSL certificates in Nginx Proxy Manager
7. **Backup regularly** - Backup NFS data and Docker volumes
8. **Limit exposure** - Don't expose all ports to the internet
9. **Use reverse proxy** - Route external access through Nginx Proxy Manager
10. **Enable 2FA** - Where supported (Portainer, etc.)

## Updates and Maintenance

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Docker images
cd homelab/stacks/STACK_NAME
docker compose pull
docker compose up -d

# Or via Portainer UI: Stacks → Select Stack → Pull and Redeploy

# Clean up unused images
docker image prune -a

# Clean up unused volumes
docker volume prune

# Clean up everything
docker system prune -a --volumes
```

## Next Steps

1. ✅ VM configured with setup script
2. ✅ Docker installed and running
3. ✅ NFS mount configured
4. 📦 Deploy Portainer → See `stacks/portainer/PORTAINER_SETUP.md`
5. 🏗️ Deploy Infrastructure → See `stacks/infrastructure/INFRASTRUCTURE_SETUP.md`
6. 📊 Deploy Dashboards → See `stacks/dashboards/DASHBOARDS_SETUP.md`
7. 💻 Deploy Development → See `stacks/development/DEVELOPMENT_SETUP.md`

## Resources

- [Docker Documentation](https://docs.docker.com/)
- [Ubuntu Server Guide](https://ubuntu.com/server/docs)
- [Proxmox Documentation](https://pve.proxmox.com/wiki/Main_Page)
- [NFS Setup Guide](https://ubuntu.com/server/docs/service-nfs)

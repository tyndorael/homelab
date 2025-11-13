#!/bin/bash

################################################################################
# Homelab Setup Script for Ubuntu (Proxmox VM)
# 
# This script will:
# - Update system packages
# - Install Docker and Docker Compose
# - Configure NFS client for shared volumes
# - Create necessary directories
# - Set proper permissions
# - Configure firewall rules
# - Install useful utilities
################################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables - MODIFY THESE FOR YOUR SETUP
HOSTNAME="${HOSTNAME:-herta}"  # VM hostname (used for NFS path)
NFS_SERVER_IP="${NFS_SERVER_IP:-192.168.1.100}"  # Your NFS server IP
NFS_EXPORT_PATH="${NFS_EXPORT_PATH:-/mnt/storage/vm_shares/${HOSTNAME}}"  # NFS export path
LOCAL_MOUNT_POINT="/nfs/vm_shares"  # Local mount point
CURRENT_USER="${SUDO_USER:-$USER}"  # Current user
USER_UID="1000"  # UID for Docker user
USER_GID="1000"  # GID for Docker user

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root or with sudo"
        exit 1
    fi
}

confirm_action() {
    read -p "$1 (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 1
    fi
    return 0
}

################################################################################
# Main Setup Functions
################################################################################

update_system() {
    print_header "Updating System Packages"
    
    apt-get update
    apt-get upgrade -y
    
    print_success "System updated successfully"
}

install_utilities() {
    print_header "Installing Useful Utilities"
    
    apt-get install -y \
        curl \
        wget \
        git \
        vim \
        nano \
        htop \
        net-tools \
        dnsutils \
        ca-certificates \
        gnupg \
        lsb-release \
        software-properties-common \
        apt-transport-https \
        nfs-common \
        cifs-utils \
        ufw \
        fail2ban \
        unzip \
        zip \
        tree \
        ncdu \
        iotop \
        iftop \
        qemu-guest-agent
    
    # Enable and start qemu-guest-agent for Proxmox integration
    systemctl enable qemu-guest-agent
    systemctl start qemu-guest-agent
    
    print_success "Utilities installed successfully"
    print_success "QEMU Guest Agent enabled for Proxmox integration"
}

install_docker() {
    print_header "Installing Docker"
    
    # Check if Docker is already installed
    if command -v docker &> /dev/null; then
        print_warning "Docker is already installed"
        docker --version
        return 0
    fi
    
    # Remove old versions
    apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Set up the repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    print_success "Docker installed successfully"
    docker --version
}

configure_docker_user() {
    print_header "Configuring Docker for Non-Root User"
    
    # Add user to docker group
    if ! groups "$CURRENT_USER" | grep -q docker; then
        usermod -aG docker "$CURRENT_USER"
        print_success "User '$CURRENT_USER' added to docker group"
        print_warning "User needs to log out and back in for group changes to take effect"
    else
        print_warning "User '$CURRENT_USER' is already in docker group"
    fi
    
    # Fix Docker socket permissions
    if [ -S /var/run/docker.sock ]; then
        chmod 666 /var/run/docker.sock
        print_success "Fixed Docker socket permissions"
    else
        print_warning "Docker socket not found, will be created on Docker start"
    fi
}

configure_docker_tcp_api() {
    print_header "Configuring Docker TCP API for Dockpeek"
    
    echo -e "${YELLOW}This will expose Docker API on TCP port 2375 for Dockpeek monitoring.${NC}"
    echo -e "${YELLOW}This is UNENCRYPTED and should only be used on trusted networks.${NC}"
    echo ""
    
    if ! confirm_action "Do you want to enable Docker TCP API?"; then
        print_warning "Skipping Docker TCP API configuration"
        return 0
    fi
    
    # Create daemon.json if it doesn't exist
    if [ ! -f /etc/docker/daemon.json ]; then
        echo '{}' > /etc/docker/daemon.json
        print_success "Created /etc/docker/daemon.json"
    fi
    
    # Backup existing daemon.json
    cp /etc/docker/daemon.json /etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)
    print_success "Backed up daemon.json"
    
    # Add hosts configuration
    cat > /etc/docker/daemon.json << 'EOF'
{
  "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2375"]
}
EOF
    
    print_success "Updated /etc/docker/daemon.json"
    
    # Create systemd override directory
    mkdir -p /etc/systemd/system/docker.service.d
    
    # Create override file to remove -H fd:// from ExecStart
    cat > /etc/systemd/system/docker.service.d/override.conf << 'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd
EOF
    
    print_success "Created systemd override configuration"
    
    # Reload systemd and restart Docker
    systemctl daemon-reload
    systemctl restart docker
    
    # Wait for Docker to start
    sleep 3
    
    # Verify Docker is running
    if systemctl is-active --quiet docker; then
        print_success "Docker restarted successfully with TCP API enabled"
        
        # Test TCP API
        if curl -s http://localhost:2375/version > /dev/null; then
            print_success "Docker TCP API is responding on port 2375"
        else
            print_error "Docker TCP API is not responding"
            return 1
        fi
    else
        print_error "Docker failed to start. Rolling back configuration..."
        
        # Restore backup
        mv /etc/docker/daemon.json.backup.* /etc/docker/daemon.json 2>/dev/null || true
        rm /etc/systemd/system/docker.service.d/override.conf 2>/dev/null || true
        systemctl daemon-reload
        systemctl restart docker
        
        print_warning "Configuration rolled back"
        return 1
    fi
    
    # Prompt for firewall configuration
    echo ""
    echo -e "${YELLOW}Firewall Configuration:${NC}"
    echo "For security, you should restrict TCP port 2375 to specific IPs."
    echo ""
    
    if confirm_action "Do you want to configure firewall rules now?"; then
        echo ""
        echo -e "${YELLOW}Enter the IP address of your Dockpeek/monitoring VM:${NC}"
        echo "(e.g., 192.168.1.100)"
        read -p "IP address: " MONITOR_IP
        
        if [ -n "$MONITOR_IP" ]; then
            # Allow from monitoring VM
            ufw allow from "$MONITOR_IP" to any port 2375 proto tcp comment 'Docker TCP API for Dockpeek'
            print_success "Firewall rule added for $MONITOR_IP"
        else
            print_warning "No IP provided, skipping firewall rule"
            print_warning "Remember to manually configure firewall!"
        fi
    else
        print_warning "Skipping firewall configuration"
        print_warning "SECURITY: Port 2375 is open to all IPs. Configure firewall manually!"
    fi
    
    # Show configuration summary
    echo ""
    echo -e "${BLUE}Docker TCP API Configuration Summary:${NC}"
    echo "- API Endpoint: tcp://$(hostname -I | awk '{print $1}'):2375"
    echo "- Local Test: curl http://localhost:2375/version"
    echo "- Remote Test: curl http://$(hostname -I | awk '{print $1}'):2375/version"
    echo ""
    echo -e "${YELLOW}Security Notes:${NC}"
    echo "- This connection is UNENCRYPTED"
    echo "- Use firewall rules to restrict access"
    echo "- Consider using VPN for remote access"
    echo "- Monitor access logs regularly"
}

configure_nfs_client() {
    print_header "Configuring NFS Client"
    
    # Install NFS client if not already installed
    if ! command -v mount.nfs &> /dev/null; then
        apt-get install -y nfs-common
    fi
    
    # Create mount point
    mkdir -p "$LOCAL_MOUNT_POINT"
    print_success "Created mount point: $LOCAL_MOUNT_POINT"
    
    # Check if already mounted
    if mount | grep -q "$LOCAL_MOUNT_POINT"; then
        print_warning "NFS share already mounted at $LOCAL_MOUNT_POINT"
        return 0
    fi
    
    # Test NFS server connectivity
    print_warning "Testing connection to NFS server: $NFS_SERVER_IP"
    if ! ping -c 1 -W 2 "$NFS_SERVER_IP" &> /dev/null; then
        print_error "Cannot reach NFS server at $NFS_SERVER_IP"
        print_warning "Skipping NFS mount. You can configure it later manually."
        return 1
    fi
    
    # Try to mount NFS share
    if mount -t nfs "$NFS_SERVER_IP:$NFS_EXPORT_PATH" "$LOCAL_MOUNT_POINT"; then
        print_success "NFS share mounted successfully"
    else
        print_error "Failed to mount NFS share"
        print_warning "Check your NFS server settings and try mounting manually:"
        print_warning "  sudo mount -t nfs $NFS_SERVER_IP:$NFS_EXPORT_PATH $LOCAL_MOUNT_POINT"
        return 1
    fi
    
    # Add to /etc/fstab for automatic mounting
    FSTAB_ENTRY="$NFS_SERVER_IP:$NFS_EXPORT_PATH $LOCAL_MOUNT_POINT nfs defaults,_netdev 0 0"
    
    if ! grep -qF "$LOCAL_MOUNT_POINT" /etc/fstab; then
        echo "$FSTAB_ENTRY" >> /etc/fstab
        print_success "Added NFS mount to /etc/fstab for automatic mounting"
    else
        print_warning "NFS mount entry already exists in /etc/fstab"
    fi
}

create_app_directories() {
    print_header "Creating Application Directories"
    
    echo -e "${YELLOW}This will create directory structure for all homelab apps.${NC}"
    echo -e "${YELLOW}Location: $LOCAL_MOUNT_POINT/${HOSTNAME}/apps${NC}"
    echo ""
    
    if ! confirm_action "Do you want to create application directories now?"; then
        print_warning "Skipping application directories creation"
        print_warning "You can create them manually later as needed"
        return 0
    fi
    
    # Base directories
    APPS_BASE="$LOCAL_MOUNT_POINT/${HOSTNAME}/apps"
    
    # Create directory structure
    mkdir -p "$APPS_BASE"/{portainer,nginx-proxy-manager,homepage,dashy,dockpeek,code-server,termix,uptime-kuma}
    mkdir -p "$APPS_BASE"/{plex,jellyfin,navidrome}
    mkdir -p "$APPS_BASE"/{speedtest-tracker,stirling-pdf,filebrowser}
    mkdir -p "$APPS_BASE"/qbittorrent/config
    mkdir -p "$APPS_BASE"/portainer/data
    mkdir -p "$APPS_BASE"/homepage/config
    mkdir -p "$APPS_BASE"/dashy/config
    mkdir -p "$APPS_BASE"/code-server/{config,projects}
    mkdir -p "$APPS_BASE"/uptime-kuma/data
    mkdir -p "$APPS_BASE"/plex/{config,transcode}
    mkdir -p "$APPS_BASE"/jellyfin/{config,cache}
    mkdir -p "$APPS_BASE"/speedtest-tracker/config
    mkdir -p "$APPS_BASE"/stirling-pdf/{configs,logs}
    
    # Create FileBrowser initial files
    touch "$APPS_BASE"/filebrowser/database.db
    touch "$APPS_BASE"/filebrowser/settings.json
    
    print_success "Created application directories"
    
    # Set ownership and permissions
    chown -R "$USER_UID:$USER_GID" "$APPS_BASE"
    chmod -R 755 "$APPS_BASE"
    
    print_success "Set proper ownership (UID:GID $USER_UID:$USER_GID)"
}

configure_firewall() {
    print_header "Configuring Firewall (UFW)"
    
    # Enable UFW if not already enabled
    if ! ufw status | grep -q "Status: active"; then
        print_warning "Configuring firewall rules..."
        
        # Allow SSH (important!)
        ufw allow 22/tcp comment 'SSH'
        
        # Allow HTTP/HTTPS for Nginx Proxy Manager
        ufw allow 80/tcp comment 'HTTP'
        ufw allow 443/tcp comment 'HTTPS'
        ufw allow 81/tcp comment 'Nginx Proxy Manager UI'
        
        # Allow Portainer
        ufw allow 9443/tcp comment 'Portainer HTTPS'
        ufw allow 9000/tcp comment 'Portainer HTTP'
        
        # Allow dashboard ports
        ufw allow 3000/tcp comment 'Homepage'
        ufw allow 4000/tcp comment 'Dashy'
        
        # Allow monitoring tools
        ufw allow 3420/tcp comment 'Dockpeek'
        ufw allow 3001/tcp comment 'Uptime Kuma'
        
        # Allow media automation (*arr apps)
        ufw allow 8989/tcp comment 'Sonarr'
        ufw allow 7878/tcp comment 'Radarr'
        ufw allow 9696/tcp comment 'Prowlarr'
        ufw allow 6767/tcp comment 'Bazarr'
        ufw allow 8686/tcp comment 'Lidarr'
        ufw allow 8787/tcp comment 'Readarr'
        
        # Allow media players
        ufw allow 32400/tcp comment 'Plex'
        ufw allow 8096/tcp comment 'Jellyfin HTTP'
        ufw allow 8920/tcp comment 'Jellyfin HTTPS'
        ufw allow 4533/tcp comment 'Navidrome'
        
        # Allow utilities
        ufw allow 8765/tcp comment 'Speedtest Tracker'
        ufw allow 8766/tcp comment 'IT-Tools'
        ufw allow 8767/tcp comment 'CyberChef'
        ufw allow 8768/tcp comment 'Excalidraw'
        ufw allow 8769/tcp comment 'Stirling-PDF'
        ufw allow 8770/tcp comment 'Dozzle'
        ufw allow 8771/tcp comment 'FileBrowser'
        
        # Allow downloaders
        ufw allow 8080/tcp comment 'qBittorrent Web UI'
        ufw allow 6881/tcp comment 'qBittorrent BT TCP'
        ufw allow 6881/udp comment 'qBittorrent BT UDP'
        
        # Allow monitoring
        ufw allow 3001/tcp comment 'Uptime Kuma'
        ufw allow 3420/tcp comment 'Dockpeek'
        ufw allow 8001/tcp comment 'DockMon'
        
        # Allow development tools
        ufw allow 8443/tcp comment 'Code-Server'
        ufw allow 8282/tcp comment 'Termix'
        
        # Enable firewall
        ufw --force enable
        
        print_success "Firewall configured and enabled"
    else
        print_warning "Firewall is already active"
    fi
    
    # Show firewall status
    echo ""
    ufw status numbered
}

configure_fail2ban() {
    print_header "Configuring Fail2Ban"
    
    # Enable and start fail2ban
    systemctl enable fail2ban
    systemctl start fail2ban
    
    print_success "Fail2Ban enabled for SSH protection"
}

create_env_file() {
    print_header "Creating Environment Variables Template"
    
    ENV_FILE="$HOME/homelab.env"
    
    cat > "$ENV_FILE" << 'EOF'
# Homelab Environment Variables
# Copy this to each stack directory as .env and customize

# Timezone
TZ=America/New_York

# Portainer (not needed if using volume)
# No additional vars required

# Nginx Proxy Manager (uses Docker volumes)
# No additional vars required

# Homepage
HOMEPAGE_ALLOWED_HOSTS=your-domain.com,localhost

# Dockpeek
DOCKPEEK_SECRET_KEY=your-secret-key-here-change-this
DOCKPEEK_USERNAME=admin
DOCKPEEK_PASSWORD=change-this-password
DOCKER_HOST_1_NAME=Local

# Code-Server
CODE_SERVER_PASSWORD=your-secure-password
CODE_SERVER_SUDO_PASSWORD=your-sudo-password
CODE_SERVER_PROXY_DOMAIN=code.your-domain.com

# NFS Server Info (for reference)
# NFS_SERVER=192.168.1.100
# NFS_PATH=/mnt/storage/vm_shares/herta
EOF
    
    chown "$CURRENT_USER:$CURRENT_USER" "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    
    print_success "Created environment template: $ENV_FILE"
    print_warning "Remember to customize the values in this file!"
}

print_summary() {
    print_header "Setup Complete!"
    
    echo -e "${GREEN}✓ System updated${NC}"
    echo -e "${GREEN}✓ Docker installed${NC}"
    echo -e "${GREEN}✓ Utilities installed${NC}"
    echo -e "${GREEN}✓ NFS client configured${NC}"
    echo -e "${GREEN}✓ Application directories created${NC}"
    echo -e "${GREEN}✓ Firewall configured${NC}"
    echo -e "${GREEN}✓ Fail2Ban enabled${NC}"
    
    echo -e "\n${YELLOW}Next Steps:${NC}"
    echo "1. Log out and back in for Docker group changes to take effect"
    echo "2. Verify Docker: docker run hello-world"
    echo "3. Clone your homelab repository:"
    echo "   git clone https://github.com/yourusername/homelab.git"
    echo "4. Navigate to the repository and deploy Portainer:"
    echo "   cd homelab/stacks/portainer"
    echo "   docker compose -f portainer-stack.yml up -d"
    echo "5. Access Portainer at https://$(hostname -I | awk '{print $1}'):9443"
    echo "6. Deploy other stacks through Portainer UI"
    
    echo -e "\n${YELLOW}Important Files:${NC}"
    echo "- Environment template: $HOME/homelab.env"
    echo "- NFS mount point: $LOCAL_MOUNT_POINT"
    echo "- Apps directory: $LOCAL_MOUNT_POINT/${HOSTNAME}/apps"
    
    echo -e "\n${YELLOW}Useful Commands:${NC}"
    echo "- Check Docker status: sudo systemctl status docker"
    echo "- Check NFS mount: df -h | grep nfs"
    echo "- View firewall rules: sudo ufw status"
    echo "- View running containers: docker ps"
    
    echo -e "\n${GREEN}Setup completed successfully!${NC}\n"
    
    # Prompt for reboot
    echo -e "${YELLOW}A reboot is recommended for all changes to take effect (especially Docker group membership).${NC}"
    if confirm_action "Do you want to reboot now?"; then
        print_warning "Rebooting in 5 seconds... Press Ctrl+C to cancel."
        sleep 5
        reboot
    else
        print_warning "Please remember to reboot later for changes to fully apply."
        echo -e "${YELLOW}You can reboot manually with: sudo reboot now${NC}\n"
    fi
}

################################################################################
# Main Execution
################################################################################

main() {
    clear
    
    echo -e "${BLUE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║        Homelab Setup Script for Ubuntu (Proxmox)          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # Check if running as root
    check_root
    
    echo -e "${YELLOW}This script will install and configure:${NC}"
    echo "  • Docker and Docker Compose"
    echo "  • NFS client and mount shared volumes"
    echo "  • System utilities (htop, vim, git, etc.)"
    echo "  • Firewall rules (UFW)"
    echo "  • Fail2Ban for SSH protection"
    echo "  • Application directory structure"
    echo ""
    echo -e "${YELLOW}Configuration:${NC}"
    echo "  • Hostname: $HOSTNAME"
    echo "  • NFS Server: $NFS_SERVER_IP"
    echo "  • NFS Export: $NFS_EXPORT_PATH"
    echo "  • Mount Point: $LOCAL_MOUNT_POINT"
    echo "  • User: $CURRENT_USER (UID:GID $USER_UID:$USER_GID)"
    echo ""
    
    if ! confirm_action "Do you want to proceed with the installation?"; then
        print_warning "Installation cancelled"
        exit 0
    fi
    
    # Run setup functions
    update_system
    install_utilities
    install_docker
    configure_docker_user
    configure_docker_tcp_api
    configure_nfs_client
    create_app_directories
    configure_firewall
    configure_fail2ban
    create_env_file
    print_summary
}

# Run main function
main "$@"

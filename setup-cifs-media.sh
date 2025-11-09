#!/bin/bash

################################################################################
# CIFS/SMB Media Share Setup Script
# 
# This script will:
# - Install CIFS utilities
# - Create mount point for media share
# - Configure /etc/fstab for automatic mounting
# - Mount the CIFS share
# - Set proper permissions
################################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables - MODIFY THESE FOR YOUR SETUP
CIFS_SERVER_IP="${CIFS_SERVER_IP:-192.168.50.107}"  # SMB/CIFS server IP
CIFS_SHARE_NAME="${CIFS_SHARE_NAME:-Media}"  # Share name on server
LOCAL_MOUNT_POINT="${LOCAL_MOUNT_POINT:-/mnt/media}"  # Local mount point
CIFS_USERNAME="${CIFS_USERNAME:-tyndorael}"  # CIFS username
CIFS_PASSWORD="${CIFS_PASSWORD}"  # CIFS password (set via environment or prompt)
CIFS_UID="${CIFS_UID:-1000}"  # User ID for file ownership
CIFS_GID="${CIFS_GID:-1000}"  # Group ID for file ownership
CIFS_FILE_MODE="${CIFS_FILE_MODE:-0755}"  # File permissions
CIFS_DIR_MODE="${CIFS_DIR_MODE:-0755}"  # Directory permissions

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

prompt_password() {
    if [ -z "$CIFS_PASSWORD" ]; then
        echo -e "${YELLOW}Enter CIFS password for user '$CIFS_USERNAME':${NC}"
        read -s CIFS_PASSWORD
        echo ""
        
        if [ -z "$CIFS_PASSWORD" ]; then
            print_error "Password cannot be empty"
            exit 1
        fi
    fi
}

################################################################################
# Main Setup Functions
################################################################################

install_cifs_utils() {
    print_header "Installing CIFS Utilities"
    
    # Check if cifs-utils is already installed
    if dpkg -l | grep -q cifs-utils; then
        print_warning "cifs-utils is already installed"
        return 0
    fi
    
    apt-get update
    apt-get install -y cifs-utils
    
    print_success "CIFS utilities installed successfully"
}

create_mount_point() {
    print_header "Creating Mount Point"
    
    if [ -d "$LOCAL_MOUNT_POINT" ]; then
        print_warning "Mount point already exists: $LOCAL_MOUNT_POINT"
    else
        mkdir -p "$LOCAL_MOUNT_POINT"
        print_success "Created mount point: $LOCAL_MOUNT_POINT"
    fi
    
    # Set ownership
    chown "$CIFS_UID:$CIFS_GID" "$LOCAL_MOUNT_POINT"
    chmod 755 "$LOCAL_MOUNT_POINT"
}

test_cifs_connection() {
    print_header "Testing CIFS Server Connection"
    
    # Test server connectivity
    print_warning "Testing connection to CIFS server: $CIFS_SERVER_IP"
    if ! ping -c 1 -W 2 "$CIFS_SERVER_IP" &> /dev/null; then
        print_error "Cannot reach CIFS server at $CIFS_SERVER_IP"
        print_warning "Please verify the server IP address and network connectivity"
        return 1
    fi
    
    print_success "CIFS server is reachable"
    return 0
}

mount_cifs_share() {
    print_header "Mounting CIFS Share"
    
    # Check if already mounted
    if mount | grep -q "$LOCAL_MOUNT_POINT"; then
        print_warning "Share already mounted at $LOCAL_MOUNT_POINT"
        if confirm_action "Do you want to unmount and remount?"; then
            umount "$LOCAL_MOUNT_POINT"
            print_success "Unmounted existing share"
        else
            return 0
        fi
    fi
    
    # Build mount options
    MOUNT_OPTIONS="uid=$CIFS_UID,gid=$CIFS_GID,file_mode=$CIFS_FILE_MODE,dir_mode=$CIFS_DIR_MODE,username=$CIFS_USERNAME,password=$CIFS_PASSWORD"
    
    # Try to mount
    print_warning "Attempting to mount CIFS share..."
    if mount -t cifs "//$CIFS_SERVER_IP/$CIFS_SHARE_NAME" "$LOCAL_MOUNT_POINT" -o "$MOUNT_OPTIONS"; then
        print_success "CIFS share mounted successfully"
        
        # Show mount info
        echo ""
        df -h "$LOCAL_MOUNT_POINT" | tail -1
    else
        print_error "Failed to mount CIFS share"
        print_warning "Please check:"
        print_warning "  - Server IP: $CIFS_SERVER_IP"
        print_warning "  - Share name: $CIFS_SHARE_NAME"
        print_warning "  - Username: $CIFS_USERNAME"
        print_warning "  - Password is correct"
        print_warning "  - Share permissions allow this user"
        return 1
    fi
}

create_credentials_file() {
    print_header "Creating Credentials File"
    
    CREDENTIALS_FILE="/root/.smb_credentials"
    
    # Create credentials file
    cat > "$CREDENTIALS_FILE" << EOF
username=$CIFS_USERNAME
password=$CIFS_PASSWORD
EOF
    
    # Secure the credentials file
    chmod 600 "$CREDENTIALS_FILE"
    chown root:root "$CREDENTIALS_FILE"
    
    print_success "Credentials file created: $CREDENTIALS_FILE"
    print_warning "Credentials are stored securely with 600 permissions"
}

update_fstab() {
    print_header "Updating /etc/fstab"
    
    SHARE_PATH="//$CIFS_SERVER_IP/$CIFS_SHARE_NAME"
    
    # Check if entry already exists
    if grep -q "$LOCAL_MOUNT_POINT" /etc/fstab; then
        print_warning "Mount entry already exists in /etc/fstab"
        
        if confirm_action "Do you want to update the existing entry?"; then
            # Backup fstab
            cp /etc/fstab /etc/fstab.backup.$(date +%Y%m%d_%H%M%S)
            print_success "Created backup of /etc/fstab"
            
            # Remove old entry
            sed -i "\|$LOCAL_MOUNT_POINT|d" /etc/fstab
            print_success "Removed old entry"
        else
            return 0
        fi
    fi
    
    # Add new entry to fstab
    FSTAB_ENTRY="$SHARE_PATH $LOCAL_MOUNT_POINT cifs credentials=/root/.smb_credentials,uid=$CIFS_UID,gid=$CIFS_GID,file_mode=$CIFS_FILE_MODE,dir_mode=$CIFS_DIR_MODE,_netdev 0 0"
    
    echo "$FSTAB_ENTRY" >> /etc/fstab
    print_success "Added CIFS mount to /etc/fstab"
    
    echo -e "${BLUE}Entry added:${NC}"
    echo "$FSTAB_ENTRY"
}

test_fstab_mount() {
    print_header "Testing fstab Configuration"
    
    # Unmount if currently mounted
    if mount | grep -q "$LOCAL_MOUNT_POINT"; then
        umount "$LOCAL_MOUNT_POINT"
    fi
    
    # Test mount from fstab
    print_warning "Testing mount from /etc/fstab..."
    if mount "$LOCAL_MOUNT_POINT"; then
        print_success "Successfully mounted from /etc/fstab"
        
        # Verify mount
        echo ""
        df -h "$LOCAL_MOUNT_POINT" | tail -1
        return 0
    else
        print_error "Failed to mount from /etc/fstab"
        print_warning "Check /etc/fstab for errors"
        return 1
    fi
}

create_media_directories() {
    print_header "Creating Media Directory Structure"
    
    echo -e "${YELLOW}This will create standard media directories.${NC}"
    echo -e "${YELLOW}Location: $LOCAL_MOUNT_POINT${NC}"
    echo ""
    
    if ! confirm_action "Do you want to create media subdirectories (tv, movies, music, books)?"; then
        print_warning "Skipping media directory creation"
        return 0
    fi
    
    # Create media directories
    mkdir -p "$LOCAL_MOUNT_POINT"/{tv,movies,music,books,downloads}
    
    # Set permissions
    chown -R "$CIFS_UID:$CIFS_GID" "$LOCAL_MOUNT_POINT"
    chmod -R 755 "$LOCAL_MOUNT_POINT"
    
    print_success "Created media directories"
    
    echo ""
    echo "Directory structure:"
    tree -L 1 "$LOCAL_MOUNT_POINT" 2>/dev/null || ls -la "$LOCAL_MOUNT_POINT"
}

print_summary() {
    print_header "Setup Complete!"
    
    echo -e "${GREEN}✓ CIFS utilities installed${NC}"
    echo -e "${GREEN}✓ Mount point created${NC}"
    echo -e "${GREEN}✓ CIFS share mounted${NC}"
    echo -e "${GREEN}✓ Credentials file created${NC}"
    echo -e "${GREEN}✓ /etc/fstab updated${NC}"
    
    echo -e "\n${YELLOW}Mount Information:${NC}"
    echo "Server: //$CIFS_SERVER_IP/$CIFS_SHARE_NAME"
    echo "Mount point: $LOCAL_MOUNT_POINT"
    echo "Username: $CIFS_USERNAME"
    echo "UID:GID: $CIFS_UID:$CIFS_GID"
    echo "Credentials: /root/.smb_credentials"
    
    echo -e "\n${YELLOW}Verify Mount:${NC}"
    df -h "$LOCAL_MOUNT_POINT" 2>/dev/null || echo "Not currently mounted"
    
    echo -e "\n${YELLOW}Useful Commands:${NC}"
    echo "- Check mount: df -h | grep media"
    echo "- Mount manually: sudo mount $LOCAL_MOUNT_POINT"
    echo "- Unmount: sudo umount $LOCAL_MOUNT_POINT"
    echo "- Test all mounts: sudo mount -a"
    echo "- View fstab: cat /etc/fstab"
    
    echo -e "\n${GREEN}CIFS media share configured successfully!${NC}\n"
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
║          CIFS/SMB Media Share Setup Script                ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # Check if running as root
    check_root
    
    echo -e "${YELLOW}This script will configure CIFS/SMB media share:${NC}"
    echo "  • Install CIFS utilities"
    echo "  • Create mount point"
    echo "  • Mount CIFS share"
    echo "  • Create secure credentials file"
    echo "  • Update /etc/fstab for automatic mounting"
    echo ""
    echo -e "${YELLOW}Configuration:${NC}"
    echo "  • Server: //$CIFS_SERVER_IP/$CIFS_SHARE_NAME"
    echo "  • Mount point: $LOCAL_MOUNT_POINT"
    echo "  • Username: $CIFS_USERNAME"
    echo "  • UID:GID: $CIFS_UID:$CIFS_GID"
    echo "  • Permissions: Files=$CIFS_FILE_MODE, Dirs=$CIFS_DIR_MODE"
    echo ""
    
    if ! confirm_action "Do you want to proceed with the configuration?"; then
        print_warning "Configuration cancelled"
        exit 0
    fi
    
    # Prompt for password if not set
    prompt_password
    
    # Run setup functions
    install_cifs_utils
    create_mount_point
    test_cifs_connection || exit 1
    mount_cifs_share || exit 1
    create_credentials_file
    update_fstab
    test_fstab_mount || print_warning "Manual verification recommended"
    create_media_directories
    print_summary
}

# Run main function
main "$@"

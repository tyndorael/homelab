# Utilities Stack Setup Guide

This guide covers the deployment and configuration of various utility applications for your homelab.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Services Included](#services-included)
- [Directory Setup](#directory-setup)
- [Deployment](#deployment)
- [Configuration](#configuration)
- [Usage Guide](#usage-guide)
- [Troubleshooting](#troubleshooting)

---

## Overview

This stack provides a collection of useful utilities for homelab management, development, and productivity.

**Port Assignments:**
- **8765** - Speedtest Tracker
- **8766** - IT-Tools
- **8767** - CyberChef
- **8768** - Excalidraw
- **8769** - Stirling-PDF
- **8770** - Dozzle
- **8771** - FileBrowser

---

## Prerequisites

### 1. NFS Share
Ensure NFS is configured and mounted:
```bash
# Verify NFS mount
df -h | grep herta
```

### 2. Directory Preparation
Create necessary directories on NFS share:
```bash
# Create directories for utilities that need NFS storage
sudo mkdir -p /nfs/vm_shares/herta/apps/stirling-pdf
sudo mkdir -p /nfs/vm_shares/herta/apps/stirling-pdf/{configs,logs}

# Set ownership
sudo chown -R 1000:1000 /nfs/vm_shares/herta/apps/stirling-pdf
sudo chmod -R 755 /nfs/vm_shares/herta/apps/stirling-pdf
```

**Note:** Speedtest Tracker and FileBrowser now use Docker volumes instead of NFS for better performance.

### 3. Firewall Configuration
Open required ports:
```bash
# Speedtest Tracker
sudo ufw allow 8765/tcp comment 'Speedtest Tracker'

# IT-Tools
sudo ufw allow 8766/tcp comment 'IT-Tools'

# CyberChef
sudo ufw allow 8767/tcp comment 'CyberChef'

# Excalidraw
sudo ufw allow 8768/tcp comment 'Excalidraw'

# Stirling-PDF
sudo ufw allow 8769/tcp comment 'Stirling-PDF'

# Dozzle
sudo ufw allow 8770/tcp comment 'Dozzle'

# FileBrowser
sudo ufw allow 8771/tcp comment 'FileBrowser'

# Verify
sudo ufw status
```

---

## Services Included

### 1. Speedtest Tracker (Port 8765)
**Purpose**: Monitor your internet connection speed over time

**Features:**
- Automated speed tests (default: every 6 hours)
- Historical data with beautiful charts
- Notifications for speed drops
- Results export
- ISP performance tracking

**Use Cases:**
- Verify ISP delivers promised speeds
- Track network performance issues
- Document speed problems for ISP support
- Monitor network upgrades effectiveness

---

### 2. IT-Tools (Port 8766)
**Purpose**: Collection of 80+ handy tools for developers

**Features:**
- Token generators (JWT, UUID, passwords)
- Encoders/Decoders (Base64, URL, HTML)
- Hash calculators (MD5, SHA, bcrypt)
- Text tools (diff, case converter, regex tester)
- Network tools (IP info, CIDR calculator)
- Image converters and QR generators
- All processing happens in browser (privacy-friendly)

**Use Cases:**
- Quick encoding/decoding operations
- Generate secure passwords
- Calculate hashes
- Test regular expressions
- Convert images

---

### 3. CyberChef (Port 8767)
**Purpose**: The Cyber Swiss Army Knife for data operations

**Features:**
- 300+ operations for data analysis
- Encryption/Decryption
- Encoding/Decoding
- Compression
- Data extraction
- Hash operations
- Recipe chains (combine multiple operations)

**Use Cases:**
- Analyze encoded data
- Decrypt/decrypt messages
- Convert between formats
- Extract data from files
- Security research
- Forensics

---

### 4. Excalidraw (Port 8768)
**Purpose**: Virtual whiteboard for sketching diagrams

**Features:**
- Hand-drawn style diagrams
- Network architecture diagrams
- Flowcharts and mind maps
- Export to PNG, SVG, or clipboard
- Collaboration (if enabled)
- Library of shapes

**Use Cases:**
- Design network topology
- Document infrastructure
- Create flowcharts
- Brainstorm ideas
- Technical documentation

---

### 5. Stirling-PDF (Port 8769)
**Purpose**: Powerful PDF manipulation tool

**Features:**
- Merge multiple PDFs
- Split PDFs by pages
- Rotate pages
- Convert to/from images
- Compress PDFs
- Add/remove pages
- Add watermarks
- Extract pages
- OCR (Optical Character Recognition)
- Sign PDFs

**Use Cases:**
- Organize documentation
- Compress large PDFs
- Extract specific pages
- Convert scanned documents
- Add watermarks to documents

---

### 6. Dozzle (Port 8770)
**Purpose**: Real-time Docker log viewer

**Features:**
- Live log streaming
- Multi-host support (with TCP Docker API)
- Search and filter logs
- No database required
- Lightweight and fast
- Dark/light theme

**Use Cases:**
- Troubleshoot container issues
- Monitor application logs
- Debug without SSH access
- View logs from multiple hosts

---

### 7. FileBrowser (Port 8771)
**Purpose**: Web-based file manager for NFS share

**Features:**
- Browse files via web interface
- Upload/download files
- Create, edit, delete files and folders
- User management
- File sharing with links
- Search functionality
- Archive extraction

**Use Cases:**
- Manage homelab files remotely
- Upload files to NFS share
- Quick file edits
- Share files with others
- Organize media files

**Default Credentials:**
- Username: `admin`
- Password: `admin`
- **Change immediately after first login!**

---

## Deployment

### 1. Environment Variables (Optional)
Create `.env` file in the stack directory:
```bash
cd stacks/utilities

cat > .env << 'EOF'
# Speedtest Tracker APP_KEY
# Generate properly formatted key with:
# docker run --rm -it php:8.2-alpine php -r "echo 'base64:' . base64_encode(random_bytes(32)) . PHP_EOL;"
SPEEDTEST_APP_KEY=base64:YOUR_GENERATED_KEY_HERE

# Or use this one-liner on Linux:
# echo "base64:$(openssl rand -base64 32)"
EOF
```

**Generate a proper APP_KEY:**
```bash
# Method 1: Using Docker (works everywhere)
docker run --rm -it php:8.2-alpine php -r "echo 'base64:' . base64_encode(random_bytes(32)) . PHP_EOL;"

# Method 2: Using OpenSSL (Linux/Mac)
echo "base64:$(openssl rand -base64 32)"

# Copy the output and use it as SPEEDTEST_APP_KEY
```

### 2. Deploy the Stack

**Option A: Using Portainer**
1. Navigate to Portainer UI
2. Go to **Stacks** → **Add Stack**
3. Name: `utilities`
4. Upload `utilities-stack.yml` or paste contents
5. Add environment variables if needed
6. Click **Deploy the stack**

**Option B: Using Docker Compose**
```bash
cd stacks/utilities
docker compose -f utilities-stack.yml up -d
```

### 3. Verify Deployment
```bash
# Check container status
docker ps | grep -E "speedtest|it-tools|cyberchef|excalidraw|stirling|dozzle|filebrowser"

# Check logs
docker logs speedtest-tracker
docker logs it-tools
docker logs stirling-pdf
docker logs filebrowser
```

---

## Configuration

### Speedtest Tracker

**Initial Setup:**
1. Access at `http://YOUR_SERVER_IP:8765`
2. Create admin account
3. Configure schedule (default: every 6 hours)
4. Set notification preferences

**Customization:**
```yaml
# In utilities-stack.yml
environment:
  - SPEEDTEST_SCHEDULE=0 */3 * * *  # Every 3 hours
  - PRUNE_RESULTS_OLDER_THAN=180     # Keep 6 months
```

---

### FileBrowser

**First Login:**
1. Access at `http://YOUR_SERVER_IP:8771`
2. Login with admin/admin
3. **Change password immediately**: Settings → User Management

**Add Users:**
1. Settings → User Management → New User
2. Set username and password
3. Set permissions (read/write)
4. Assign directory scope

**File Sharing:**
1. Right-click file → Share
2. Set expiration date
3. Copy share link

---

### Dozzle

**Multi-Host Docker Monitoring:**

Dozzle can monitor multiple Docker hosts simultaneously. To set this up:

1. **Expose Docker TCP API on each host** (see [Monitoring Setup Guide](../monitoring/MONITORING_SETUP.md))
2. **Configure Dozzle with remote hosts** using comma-separated values:

```yaml
# In utilities-stack.yml
environment:
  - DOZZLE_REMOTE_HOST=tcp://192.168.1.10:2375|Herta VM,tcp://192.168.1.20:2375|Cyrene VM
```

Format: `tcp://IP:PORT|Display Name,tcp://IP2:PORT|Display Name2`

3. **Restart Dozzle:**
```bash
cd /nfs/vm_shares/herta/stacks/utilities
docker compose restart dozzle
```

**Accessing Logs:**
- Use the host dropdown in top right to switch between Docker hosts
- All containers from all hosts will be visible
- Search and filter work across all hosts

---

## Usage Guide

### IT-Tools Common Tasks

**Generate Secure Password:**
1. Navigate to IT-Tools
2. Search "password"
3. Set length and complexity
4. Click generate

**Encode to Base64:**
1. Navigate to "Base64 encoder"
2. Paste text
3. Copy encoded result

**Calculate Hash:**
1. Navigate to "Hash text"
2. Paste text
3. Select hash type (MD5, SHA256, etc.)
4. Copy hash

---

### CyberChef Recipes

**Decode Base64:**
1. Drag "From Base64" to recipe
2. Paste encoded text in input
3. View decoded output

**Create Recipe Chain:**
1. Drag multiple operations
2. Order matters (top to bottom)
3. Save recipe for reuse

---

### Excalidraw Tips

**Network Diagram:**
1. Use library shapes (left sidebar)
2. Add text labels
3. Connect elements with arrows
4. Export as PNG for documentation

**Collaboration:**
- Share link with team
- Real-time editing
- Save to local file

---

### Stirling-PDF Common Tasks

**Merge PDFs:**
1. Upload multiple PDFs
2. Arrange in desired order
3. Click "Merge"
4. Download result

**Compress PDF:**
1. Upload PDF
2. Select compression level
3. Process
4. Compare sizes

**Extract Pages:**
1. Upload PDF
2. Select page range
3. Extract
4. Download new PDF

---

## Troubleshooting

### Speedtest Tracker Not Running Tests

**Check schedule:**
```bash
docker logs speedtest-tracker | grep -i schedule
```

**Manual test:**
1. Access web UI
2. Click "Run Test Now"

**Check cron:**
```bash
docker exec speedtest-tracker crontab -l
```

---

### FileBrowser Permission Issues

**Fix ownership:**
```bash
sudo chown -R 1000:1000 /nfs/vm_shares/herta/apps/filebrowser
sudo chmod -R 755 /nfs/vm_shares/herta/apps/filebrowser
```

**Reset database:**
```bash
sudo rm /nfs/vm_shares/herta/apps/filebrowser/database.db
docker restart filebrowser
# Login with admin/admin again
```

---

### Stirling-PDF Processing Slow

**Check resources:**
```bash
docker stats stirling-pdf
```

**Increase memory limit:**
```yaml
# In utilities-stack.yml
stirling-pdf:
  deploy:
    resources:
      limits:
        memory: 2G
```

---

### Dozzle Not Showing Logs

**Check Docker socket:**
```bash
docker exec dozzle ls -la /var/run/docker.sock
```

**For remote hosts:**
- Verify TCP API exposed (port 2375)
- Check firewall allows connection
- Test: `curl http://REMOTE_IP:2375/version`

---

## Useful Commands

```bash
# View all utility container logs
docker logs speedtest-tracker -f
docker logs it-tools -f
docker logs stirling-pdf -f
docker logs filebrowser -f

# Restart specific service
docker restart speedtest-tracker
docker restart filebrowser

# Check resource usage
docker stats --no-stream | grep -E "speedtest|it-tools|stirling|filebrowser"

# Rebuild stack
cd stacks/utilities
docker compose -f utilities-stack.yml down
docker compose -f utilities-stack.yml pull
docker compose -f utilities-stack.yml up -d

# Access container shell
docker exec -it filebrowser sh
docker exec -it stirling-pdf bash
```

---

## Security Considerations

1. **FileBrowser**: Change default admin password immediately
2. **Speedtest Tracker**: Use strong APP_KEY
3. **Dozzle**: Restrict access (shows all container logs)
4. **Reverse Proxy**: Use HTTPS with valid certificates
5. **Firewall**: Restrict to LAN or VPN if possible
6. **Updates**: Keep containers updated with Watchtower

---

## Additional Resources

- **Speedtest Tracker**: https://docs.speedtest-tracker.dev/
- **IT-Tools**: https://github.com/CorentinTh/it-tools
- **CyberChef**: https://gchq.github.io/CyberChef/
- **Excalidraw**: https://excalidraw.com/
- **Stirling-PDF**: https://github.com/Stirling-Tools/Stirling-PDF
- **Dozzle**: https://dozzle.dev/
- **FileBrowser**: https://filebrowser.org/

---

For more information, see the main [README.md](../../README.md).

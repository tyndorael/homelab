# Termix Setup Guide

Termix is an open-source, self-hosted all-in-one server management platform. Access SSH terminals, manage files remotely, create SSH tunnels, and monitor servers through a single, modern web interface. The perfect free alternative to Termius.

## Features

✅ **SSH Terminal Access** - Full-featured terminal with split-screen support (up to 4 panels)
✅ **SSH Tunnel Management** - Create and manage SSH tunnels with auto-reconnection
✅ **Remote File Manager** - View, edit, upload, download files with code/media preview
✅ **SSH Host Manager** - Save and organize SSH connections with tags and folders
✅ **Server Stats** - View CPU, memory, disk, network, uptime, and system info
✅ **Dashboard** - Server information at a glance
✅ **User Authentication** - Secure user management with admin controls, OIDC, and 2FA
✅ **Database Encryption** - Encrypted SQLite database storage
✅ **Data Export/Import** - Backup and restore SSH hosts and credentials
✅ **Modern UI** - Clean, mobile-friendly interface
✅ **Multi-language** - English, Chinese, German, Portuguese
✅ **SSH Tools** - Reusable command snippets for quick execution

## Installation Steps

### 1. Prepare Directory

Create the required directory for Termix data:

```bash
mkdir -p /nfs/vm_shares/herta/apps/termix/data
```

### 2. Deploy in Portainer

1. Go to **Stacks** → **Add stack**
2. Name it "termix"
3. Upload `termix-stack.yml` or paste its contents
4. (Optional) Add environment variable:
   - `TZ`: Your timezone (e.g., `America/New_York`)
5. Click **Deploy the stack**

### 3. Initial Access

1. Access Termix at `http://your-vm-ip:8282`
2. Create your admin account on first visit
3. Start adding your SSH connections

### 4. First-Time Setup

**Create Admin Account:**
1. On first access, you'll be prompted to create an account
2. Enter username and secure password
3. This becomes your admin account

**Enable 2FA (Recommended):**
1. Go to Settings → Security
2. Enable Two-Factor Authentication (TOTP)
3. Scan QR code with authenticator app
4. Save backup codes

### 5. (Optional) Configure Nginx Proxy Manager

To access via a custom domain with HTTPS:

1. In NPM, create a new Proxy Host:
   - **Domain**: `termix.yourdomain.com` or `ssh.yourdomain.com`
   - **Forward Hostname**: `termix`
   - **Forward Port**: `8080`
   - Enable **Websockets Support** (Critical!)
   
2. Go to **SSL** tab:
   - Select your SSL certificate
   - Enable **Force SSL**, **HTTP/2**, and **HSTS**
   - Save

Access at: `https://termix.yourdomain.com`

## Adding SSH Hosts

### Method 1: Manual Entry

1. Click **Hosts** in sidebar
2. Click **Add Host** button
3. Fill in details:
   - **Name**: Display name for the host
   - **Host**: IP address or hostname
   - **Port**: SSH port (default: 22)
   - **Username**: SSH username
   - **Authentication**: Password or SSH Key
   - **Tags**: Optional tags for organization
   - **Folder**: Optional folder for grouping
4. Click **Save**

### Method 2: Import from File

1. Go to **Settings** → **Data Management**
2. Click **Import**
3. Upload your JSON export file
4. Select items to import
5. Click **Import**

## Terminal Features

### Split Screen

- Click split icon to divide terminal (horizontal/vertical)
- Support for up to 4 terminal panels
- Resize panels by dragging divider
- Each panel maintains independent session

### Tab System

- Browser-like tab management
- Open multiple hosts in tabs
- Drag tabs to reorder
- Middle-click or 'x' to close

### Customization

**Settings** → **Terminal**:
- **Theme**: Choose from popular terminal themes
- **Font**: Select monospace font
- **Font Size**: Adjust text size
- **Cursor Style**: Block, underline, or bar
- **Bell**: Enable/disable terminal bell
- **Copy on Select**: Auto-copy selected text

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+C` | Copy (when text selected) |
| `Ctrl+V` | Paste |
| `Ctrl+Shift+F` | Find in terminal |
| `Ctrl+L` | Clear terminal |
| `Ctrl++` | Increase font size |
| `Ctrl+-` | Decrease font size |
| `Ctrl+0` | Reset font size |

## SSH Tunnels

### Creating a Tunnel

1. Go to **Tunnels** in sidebar
2. Click **Create Tunnel**
3. Select **Tunnel Type**:
   - **Local Forward**: Access remote service locally
   - **Remote Forward**: Expose local service remotely
   - **Dynamic (SOCKS)**: SOCKS proxy through SSH
4. Configure:
   - **SSH Host**: Select saved host
   - **Local Port**: Port on your machine
   - **Remote Host**: Target hostname
   - **Remote Port**: Target port
5. Click **Create**

### Managing Tunnels

- **Start/Stop**: Toggle tunnel connection
- **Auto-reconnect**: Automatically reconnect on failure
- **Health Monitoring**: View tunnel status
- **Edit**: Modify tunnel settings
- **Delete**: Remove tunnel

### Common Tunnel Examples

**Access Remote MySQL:**
```
Type: Local Forward
Local Port: 3306
Remote Host: localhost
Remote Port: 3306
```

**Access Remote Web Service:**
```
Type: Local Forward
Local Port: 8080
Remote Host: localhost
Remote Port: 80
```

**SOCKS Proxy:**
```
Type: Dynamic
Local Port: 1080
```

## File Manager

### Accessing Files

1. Go to **Files** in sidebar
2. Select SSH host from dropdown
3. Navigate file system
4. Click folders to browse

### File Operations

**Upload Files:**
- Click **Upload** button
- Select files
- Files upload to current directory

**Download Files:**
- Right-click file
- Select **Download**

**Edit Files:**
- Click file to open editor
- Syntax highlighting for code
- Save changes directly

**File Actions:**
- **Rename**: Right-click → Rename
- **Delete**: Right-click → Delete
- **Move**: Drag and drop
- **New Folder**: Click **New Folder** button
- **Permissions**: Right-click → Permissions

### Supported File Previews

- **Code**: Syntax highlighting for 100+ languages
- **Images**: PNG, JPG, GIF, SVG, WebP
- **Audio**: MP3, WAV, OGG
- **Video**: MP4, WebM, OGG
- **Text**: TXT, LOG, MD, JSON, YAML

## Server Stats

View real-time server information:

1. Go to **Dashboard**
2. Add server cards for monitored hosts
3. View metrics:
   - **CPU Usage**: Current and historical
   - **Memory**: Used/Free RAM
   - **Disk**: Storage usage by partition
   - **Network**: Upload/download rates
   - **Uptime**: Server uptime
   - **System Info**: OS, kernel, hostname

## SSH Tools & Snippets

### Creating Command Snippets

1. Go to **Tools** → **Snippets**
2. Click **Add Snippet**
3. Enter:
   - **Name**: Snippet identifier
   - **Command**: Shell command to execute
   - **Description**: Optional description
4. Save

### Using Snippets

- Open terminal
- Click **Snippets** dropdown
- Select snippet to execute
- Command runs immediately

### Broadcast Command

Execute command across multiple terminals:

1. Open multiple terminals
2. Click **Broadcast** icon
3. Type command
4. Command executes in all open terminals

## User Management

### Adding Users (Admin Only)

1. Go to **Settings** → **Users**
2. Click **Add User**
3. Enter:
   - **Username**
   - **Password**
   - **Role**: Admin or User
4. Save

### User Permissions

**Admin:**
- Full access to all features
- User management
- System settings
- View all hosts and tunnels

**User:**
- Access to own hosts and tunnels
- Cannot manage other users
- Limited settings access

### Session Management

**View Active Sessions:**
1. Settings → Security → Active Sessions
2. See all logged-in sessions
3. Revoke individual sessions

## Authentication Options

### Password Authentication

Default authentication method. Users login with username and password.

### Two-Factor Authentication (2FA)

1. Settings → Security → 2FA
2. Enable 2FA
3. Scan QR code with authenticator app (Google Authenticator, Authy, etc.)
4. Enter code to verify
5. Save backup codes

### OIDC (OpenID Connect)

Configure external authentication:

1. Settings → Security → OIDC
2. Enter:
   - **Issuer URL**
   - **Client ID**
   - **Client Secret**
   - **Redirect URI**
3. Enable OIDC
4. Users can login with SSO

## Data Management

### Export Data

1. Settings → Data Management → Export
2. Select data types:
   - SSH Hosts
   - Credentials
   - File Manager Favorites
3. Click **Export**
4. Download JSON file

### Import Data

1. Settings → Data Management → Import
2. Upload JSON export file
3. Review items
4. Select items to import
5. Click **Import**

### Backup Recommendations

- Regular exports of SSH hosts
- Store exports securely (encrypted)
- Document important configurations
- Test restore procedures

## Security Best Practices

- Use strong, unique passwords
- Enable 2FA for all users
- Deploy behind reverse proxy with HTTPS
- Don't expose port 8282 directly to internet
- Use NPM for external access
- Regular backups of data directory
- Keep Termix updated
- Use SSH keys instead of passwords where possible
- Audit user sessions regularly
- Enable automatic SSL with NPM

## Troubleshooting

**Can't access Termix:**
- Check container is running: `docker ps | grep termix`
- Verify port 8282 is accessible
- Check logs: `docker logs termix`

**SSH connection fails:**
- Verify host is reachable
- Check SSH port is correct
- Confirm credentials are valid
- Test SSH manually: `ssh user@host`
- Check firewall rules

**File upload fails:**
- Check disk space on remote server
- Verify write permissions
- Check file size limits
- Review error in browser console

**Tunnel not connecting:**
- Verify SSH host is accessible
- Check ports are not already in use
- Confirm remote service is running
- Review tunnel logs in Termix

**WebSocket errors:**
- Ensure Websockets Support enabled in NPM
- Check proxy configuration
- Verify firewall allows WebSocket connections
- Clear browser cache

**Database corruption:**
- Stop container
- Backup data directory
- Remove lock files if present
- Restart container
- If persists, restore from backup

## Useful Commands

View logs:
```bash
docker logs termix -f
```

Restart Termix:
```bash
docker restart termix
```

Access container shell:
```bash
docker exec -it termix sh
```

Backup data:
```bash
tar -czf termix-backup-$(date +%Y%m%d).tar.gz /nfs/vm_shares/herta/apps/termix/data/
```

Restore data:
```bash
tar -xzf termix-backup-YYYYMMDD.tar.gz -C /nfs/vm_shares/herta/apps/termix/
docker restart termix
```

Check database:
```bash
docker exec termix sqlite3 /app/data/termix.db ".tables"
```

## Advanced Configuration

### Custom Port

Change the port in stack file:
```yaml
environment:
  - PORT=8080
ports:
  - "8282:8080"  # Change left side to your preferred port
```

### Database Location

Data is stored in `/app/data/termix.db` inside container, mapped to `/nfs/vm_shares/herta/apps/termix/data/` on host.

### SSL Certificates

Termix can generate SSL certificates automatically, but it's recommended to use NPM for SSL termination.

## Resources

- [Official Documentation](https://docs.termix.site/)
- [GitHub Repository](https://github.com/Termix-SSH/Termix)
- [Installation Guide](https://docs.termix.site/install)
- [Discord Community](https://discord.gg/jVQGdvHDrf)
- [Report Issues](https://github.com/Termix-SSH/Support/issues)
- [Download Apps](https://github.com/Termix-SSH/Termix/blob/main/DOWNLOADS.md) (Desktop, Mobile)

## Mobile & Desktop Apps

Termix is available on multiple platforms:

**Desktop:**
- Windows (MSI, Portable, Chocolatey)
- macOS (DMG, App Store, Homebrew)
- Linux (AppImage, Deb, Flatpak)

**Mobile:**
- iOS/iPadOS (App Store, ISO)
- Android (Google Play, APK)

All apps connect to your self-hosted instance.

## Next Steps

1. Create your admin account
2. Enable 2FA for security
3. Add your SSH hosts
4. Organize hosts with tags and folders
5. Set up SSH key authentication
6. Create SSH tunnels for services
7. Explore file manager features
8. Create command snippets for common tasks
9. Set up NPM proxy for external HTTPS access
10. Install mobile/desktop apps for on-the-go access

# Development Stack Setup

This stack contains development tools including IDE and SSH management.

## Services Included

### Code-Server
- **Purpose**: VS Code in your browser - code from anywhere
- **Port**: 8443
- **Features**:
  - Full VS Code experience in browser
  - Code on tablets, Chromebooks, any device
  - Cloud-powered intensive tasks
  - Consistent development environment
  - VS Code extensions support
  - Built-in terminal and Git integration

### Termix
- **Purpose**: All-in-one SSH server management platform
- **Port**: 8282
- **Features**:
  - SSH terminal with split-screen (up to 4 panels)
  - SSH tunnel management with auto-reconnect
  - Remote file manager with code/media preview
  - Server stats and monitoring
  - User authentication with 2FA and OIDC
  - Command snippets and broadcast
  - Available on all platforms (web, desktop, mobile)

## Prerequisites

- Docker and Docker Compose installed
- NFS mount at `/nfs/vm_shares/herta` (or update volume paths)
- Infrastructure stack deployed (nginx-proxy-manager network must exist)

## Deployment

### Via Portainer (Recommended)

1. Access Portainer web UI
2. Go to **Stacks** → **Add stack**
3. Name it: `development`
4. Upload or paste the contents of `development-stack.yml`
5. Configure environment variables
6. Click **Deploy the stack**

### Via Docker Compose

```bash
cd stacks/development
docker compose -f development-stack.yml up -d
```

## Environment Variables

Create a `.env` file in the same directory:

```env
TZ=America/New_York

# Code-Server
CODE_SERVER_PASSWORD=your-secure-password
CODE_SERVER_SUDO_PASSWORD=your-sudo-password
CODE_SERVER_PROXY_DOMAIN=code.your-domain.com
```

## Configuration

### Code-Server

The configuration and project files are stored in:
- `/nfs/vm_shares/herta/apps/code-server/config` - VS Code settings, extensions
- `/nfs/vm_shares/herta/apps/code-server/projects` - Your code projects
- `/nfs/vm_shares` - Full NFS mount for accessing other data

**First-time setup**:
1. Access Code-Server at `http://your-server-ip:8443`
2. Login with the password set in `CODE_SERVER_PASSWORD`
3. Install your favorite VS Code extensions
4. Configure your development environment

### Termix

Termix stores its data in a Docker volume. Configuration is done via the web UI.

**First-time setup**:
1. Access Termix at `http://your-server-ip:8282`
2. Create your admin account
3. Add SSH servers to manage
4. Configure tunnels and access settings

## Post-Deployment

Access the development tools:
- Code-Server: `http://your-server-ip:8443`
- Termix: `http://your-server-ip:8282`

## Setting Up Reverse Proxy

Use Nginx Proxy Manager to create proxy hosts with SSL:

1. Access Nginx Proxy Manager at `http://your-server-ip:81`
2. Go to **Hosts** → **Proxy Hosts** → **Add Proxy Host**
3. Configure each service:
   - **Code-Server**: 
     - Forward to `code-server:8080`
     - Enable WebSockets Support
   - **Termix**: 
     - Forward to `termix:8080`
     - Enable WebSockets Support
4. Enable SSL certificates

## Usage Tips

### Code-Server

- **Installing Extensions**: Use the Extensions panel (Ctrl+Shift+X) just like desktop VS Code
- **Terminal Access**: Open integrated terminal with Ctrl+\` (backtick)
- **File Upload**: Drag and drop files into the editor
- **Git Integration**: Configure Git credentials in the terminal

### Termix

- **SSH Keys**: Upload your SSH keys through the web interface
- **Tunnels**: Create SSH tunnels for secure access to remote services
- **File Manager**: Browse and edit files on remote servers
- **Multi-Panel**: Split the terminal into up to 4 panels for multitasking

## Updating Services

```bash
docker compose -f development-stack.yml pull
docker compose -f development-stack.yml up -d
docker image prune -f
```

## Troubleshooting

### Code-Server won't start
- Check volume mount permissions (user 1000:1000)
- Verify password is set in environment variables
- Check logs: `docker logs code-server`

### Code-Server extensions not installing
- Ensure config volume has write permissions
- Try installing from VSIX file
- Check extension compatibility with code-server

### Termix connection issues
- Verify SSH server is reachable from the container
- Check firewall rules on target servers
- Ensure SSH keys are properly configured

### WebSocket connection errors
- Enable WebSockets support in Nginx Proxy Manager
- Check proxy timeout settings
- Verify browser isn't blocking WebSockets

## Security Considerations

- **Code-Server**: Use strong passwords and enable SSL
- **Termix**: Use SSH keys instead of passwords when possible
- **Firewall**: Don't expose these ports directly to the internet
- **Reverse Proxy**: Always use Nginx Proxy Manager with SSL for external access
- **Backups**: Regularly backup your projects and SSH configurations

## Integration with Other Services

Both services can be added to your Homepage or Dashy dashboards for quick access. Use the appropriate service URLs and configure widgets in your dashboard configuration files.

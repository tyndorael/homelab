# Code-Server Setup Guide

Code-server is VS Code running on a remote server, accessible through your browser. Code on any device with a consistent development environment.

## Features

✅ **VS Code in Browser** - Full VS Code experience anywhere
✅ **Any Device** - Code from tablets, Chromebooks, or any device with a browser
✅ **Cloud Power** - Use powerful cloud servers for heavy workloads
✅ **Battery Life** - Intensive tasks run on the server, not your device
✅ **Consistent Environment** - Same development environment across all devices
✅ **Extensions** - Install VS Code extensions
✅ **Terminal Access** - Built-in terminal for command-line tasks
✅ **Git Integration** - Full Git support
✅ **SSH** - SSH into other machines from code-server

## Installation Steps

### 1. Prepare Directories

Create the required directories for code-server:

```bash
mkdir -p /nfs/vm_shares/herta/apps/code-server/config
mkdir -p /nfs/vm_shares/herta/apps/code-server/projects
```

### 2. Configure Environment Variables

Add to your `.env` file:

```env
TZ=America/New_York
CODE_SERVER_PASSWORD=your_secure_password_here
CODE_SERVER_SUDO_PASSWORD=your_sudo_password_here
CODE_SERVER_PROXY_DOMAIN=code.yourdomain.com
```

**Important**:
- `PASSWORD`: Required for authentication
- `SUDO_PASSWORD`: Optional, for sudo access within the container
- `PROXY_DOMAIN`: Optional, your domain if accessing via reverse proxy

### 3. Deploy in Portainer

1. Go to **Stacks** → **Add stack**
2. Name it "code-server"
3. Upload `code-server-stack.yml` or paste its contents
4. Add environment variables from your `.env` file
5. Click **Deploy the stack**

### 4. Initial Access

1. Access code-server at `http://your-vm-ip:8443`
2. Enter your password when prompted
3. You'll see VS Code interface in your browser

### 5. (Optional) Configure Nginx Proxy Manager

To access via a custom domain with HTTPS:

1. In NPM, create a new Proxy Host:
   - **Domain**: `code.yourdomain.com` or `vscode.yourdomain.com`
   - **Forward Hostname**: `code-server`
   - **Forward Port**: `8080`
   - Enable **Websockets Support** (Important!)
   
2. Go to **SSL** tab:
   - Select your SSL certificate
   - Enable **Force SSL**, **HTTP/2**, and **HSTS**
   - Save

3. Update `CODE_SERVER_PROXY_DOMAIN` in your environment variables to match your domain

Access at: `https://code.yourdomain.com`

## Configuration

### Password Authentication

By default, code-server uses password authentication. You can set the password using:

**Environment variable (recommended):**
```yaml
environment:
  - PASSWORD=your_secure_password
```

**Config file:**
Edit `/nfs/vm_shares/herta/apps/code-server/config/code-server/config.yaml`:
```yaml
bind-addr: 0.0.0.0:8080
auth: password
password: your_secure_password
cert: false
```

### Disable Authentication

**Not recommended for production!**

```yaml
# config.yaml
auth: none
```

Or via environment:
```yaml
environment:
  - PASSWORD=
```

### Settings Sync

Code-server supports VS Code Settings Sync:

1. Open command palette (Ctrl+Shift+P or Cmd+Shift+P)
2. Type "Settings Sync: Turn On"
3. Sign in with your GitHub or Microsoft account
4. Your settings, extensions, and keybindings will sync

### Extensions

Install extensions just like in VS Code:

**Via UI:**
1. Click Extensions icon in sidebar (or Ctrl+Shift+X)
2. Search for extension
3. Click Install

**Via Command Line:**
```bash
docker exec code-server code-server --install-extension <extension-id>
```

**Popular Extensions:**
- `ms-python.python` - Python
- `golang.go` - Go
- `rust-lang.rust-analyzer` - Rust
- `ms-azuretools.vscode-docker` - Docker
- `eamodio.gitlens` - GitLens
- `esbenp.prettier-vscode` - Prettier
- `dbaeumer.vscode-eslint` - ESLint

### Terminal

Access terminal in code-server:
- Menu: Terminal → New Terminal
- Keyboard: Ctrl+` (backtick)

The terminal runs inside the container with your user permissions.

## Project Management

### Adding Projects

Your projects are stored in `/nfs/vm_shares/herta/apps/code-server/projects/`

**Open a project:**
1. File → Open Folder
2. Navigate to `/home/coder/projects/your-project`
3. Click OK

**Clone from Git:**
```bash
cd /home/coder/projects
git clone https://github.com/username/repo.git
```

### Multi-root Workspaces

Save workspace files to quickly switch between projects:

1. File → Add Folder to Workspace (add multiple folders)
2. File → Save Workspace As
3. Save in `/home/coder/projects/`

## Advanced Configuration

### Custom config.yaml

Full configuration options in `/nfs/vm_shares/herta/apps/code-server/config/code-server/config.yaml`:

```yaml
bind-addr: 0.0.0.0:8080
auth: password
password: your_secure_password
cert: false
disable-telemetry: true
disable-update-check: false
```

### Environment Variables

Available environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `PASSWORD` | Set password for authentication | - |
| `HASHED_PASSWORD` | Use argon2 hashed password | - |
| `SUDO_PASSWORD` | Password for sudo within container | - |
| `PROXY_DOMAIN` | Domain for proxy (affects cookies) | - |
| `TZ` | Timezone | UTC |

### Installing Software

You can install additional software in the container:

```bash
# Access container shell
docker exec -it code-server bash

# Install packages (Debian/Ubuntu)
sudo apt update
sudo apt install <package-name>
```

To persist installations, consider:
- Creating a custom Dockerfile based on `codercom/code-server`
- Mounting additional volumes
- Using a persistent volume for `/home/coder`

### Git Configuration

Configure Git in the terminal:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Set up SSH keys for GitHub/GitLab
ssh-keygen -t ed25519 -C "your.email@example.com"
cat ~/.ssh/id_ed25519.pub
```

### Custom Themes

Install themes from VS Code marketplace:

1. Extensions → Search for theme
2. Install theme extension
3. File → Preferences → Color Theme
4. Select your theme

Popular themes:
- Dracula Official
- One Dark Pro
- Material Theme
- Nord
- GitHub Theme

### Keyboard Shortcuts

Common VS Code shortcuts work in code-server:

| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+P` | Command Palette |
| `Ctrl+P` | Quick Open File |
| `Ctrl+Shift+F` | Find in Files |
| `Ctrl+`` | Toggle Terminal |
| `Ctrl+B` | Toggle Sidebar |
| `Ctrl+Shift+E` | Explorer |
| `Ctrl+Shift+G` | Source Control |
| `Ctrl+Shift+X` | Extensions |
| `Ctrl+Shift+D` | Debug |

## Docker Integration

Access Docker from within code-server:

**Option 1: Mount Docker socket (read-only recommended):**
```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro
```

**Option 2: Install Docker in container:**
```bash
docker exec -it code-server bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

## Security Best Practices

- Use a strong, unique password
- Deploy behind reverse proxy with HTTPS
- Don't expose port 8443 directly to internet
- Use NPM for external access
- Enable firewall rules
- Keep code-server updated
- Use SSH keys for Git operations
- Don't store sensitive credentials in code
- Use environment variables for secrets
- Regular backups of config and projects

## Troubleshooting

**Can't access code-server:**
- Check container is running: `docker ps | grep code-server`
- Verify port 8443 is accessible
- Check logs: `docker logs code-server`
- Ensure PASSWORD is set

**Password not working:**
- Verify PASSWORD environment variable is set
- Check for typos in `.env` file
- Restart container after password change
- Check `config.yaml` for conflicting settings

**Extensions not installing:**
- Check internet connectivity from container
- Verify disk space available
- Check logs for errors
- Try installing manually via command line

**Performance issues:**
- Increase container resources in Docker
- Check host system resources
- Disable unnecessary extensions
- Close unused files and terminals

**WebSocket errors:**
- Ensure Websockets Support is enabled in NPM
- Check proxy configuration
- Verify firewall allows WebSocket connections

**Git authentication fails:**
- Set up SSH keys properly
- Use personal access tokens for HTTPS
- Check Git credentials in terminal
- Verify network connectivity to Git host

## Useful Commands

View logs:
```bash
docker logs code-server -f
```

Restart code-server:
```bash
docker restart code-server
```

Access container shell:
```bash
docker exec -it code-server bash
```

Install extension via CLI:
```bash
docker exec code-server code-server --install-extension <extension-id>
```

List installed extensions:
```bash
docker exec code-server code-server --list-extensions
```

Update code-server:
```bash
docker pull codercom/code-server:latest
docker restart code-server
```

Backup projects:
```bash
tar -czf code-server-projects-backup.tar.gz /nfs/vm_shares/herta/apps/code-server/projects/
```

Backup config:
```bash
tar -czf code-server-config-backup.tar.gz /nfs/vm_shares/herta/apps/code-server/config/
```

## Development Workflows

### Web Development

```bash
# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# Create project
cd ~/projects
npx create-react-app my-app
cd my-app
npm start
```

### Python Development

```bash
# Install Python packages
pip install flask django requests pandas numpy

# Create virtual environment
cd ~/projects/my-python-app
python3 -m venv venv
source venv/bin/activate
```

### Docker Development

```bash
# Build and run containers
cd ~/projects/my-docker-app
docker build -t myapp .
docker run -p 3000:3000 myapp
```

## Resources

- [Official Documentation](https://coder.com/docs/code-server)
- [GitHub Repository](https://github.com/coder/code-server)
- [VS Code Documentation](https://code.visualstudio.com/docs)
- [Extension Marketplace](https://open-vsx.org/)
- [Docker Hub](https://hub.docker.com/r/codercom/code-server)
- [FAQ](https://coder.com/docs/code-server/latest/FAQ)
- [Troubleshooting Guide](https://coder.com/docs/code-server/latest/troubleshooting)

## Next Steps

1. Set secure passwords in environment variables
2. Deploy the stack in Portainer
3. Configure NPM proxy for external HTTPS access
4. Install your favorite VS Code extensions
5. Set up Git with SSH keys
6. Configure Settings Sync for seamless experience
7. Create your first project
8. Explore VS Code features and extensions
9. Set up language-specific development environments

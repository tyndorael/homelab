# Homelab Docker Stack

This repository contains Docker compose stacks for managing homelab services with reverse proxy and SSL support.

## Prerequisites

**Install Portainer first!** See `apps/portainer/PORTAINER_SETUP.md` for instructions.

## Available Stacks

### Nginx Proxy Manager
Easy-to-use reverse proxy with web UI for managing SSL certificates and proxy hosts.

**Location**: `apps/nginx-proxy-manager/`
**Setup Guide**: `apps/nginx-proxy-manager/NGINX_SETUP.md`
**Features**:
- Beautiful web interface
- Manual SSL certificate upload
- Access control lists
- Stream proxies for TCP/UDP

### Homepage
Modern, fast, and secure application dashboard with 100+ service integrations.

**Location**: `apps/homepage/`
**Setup Guide**: `apps/homepage/HOMEPAGE_SETUP.md`
**Features**:
- Docker service auto-discovery via labels
- 100+ service widget integrations
- Information widgets (weather, system stats)
- Fast static generation
- Fully customizable themes and layouts
- Secure API proxying

### Dashy
Highly customizable homepage and dashboard for organizing all your services.

**Location**: `apps/dashy/`
**Setup Guide**: `apps/dashy/DASHY_SETUP.md`
**Features**:
- Multi-page support with custom layouts
- Real-time status monitoring
- Dynamic widgets and content
- Multiple themes and customization
- Authentication and multi-user support
- Instant search and keyboard shortcuts
- Icon packs and auto-fetched favicons

### Dockpeek
Lightweight Docker dashboard for quick access to containers and monitoring.

**Location**: `apps/dockpeek/`
**Setup Guide**: `apps/dockpeek/DOCKPEEK_SETUP.md`
**Features**:
- One-click container web access
- Live log streaming
- Image update detection
- Port mapping and management
- Container tagging and organization

### Code-Server
VS Code in your browser - code from anywhere on any device.

**Location**: `apps/code-server/`
**Setup Guide**: `apps/code-server/CODE_SERVER_SETUP.md`
**Features**:
- Full VS Code experience in browser
- Code on tablets, Chromebooks, any device
- Cloud-powered intensive tasks
- Consistent development environment
- VS Code extensions support
- Built-in terminal and Git integration

### Termix
All-in-one SSH server management platform with terminal, tunnels, and file management.

**Location**: `apps/termix/`
**Setup Guide**: `apps/termix/TERMIX_SETUP.md`
**Features**:
- SSH terminal with split-screen (up to 4 panels)
- SSH tunnel management with auto-reconnect
- Remote file manager with code/media preview
- Server stats and monitoring
- User authentication with 2FA and OIDC
- Command snippets and broadcast
- Available on all platforms (web, desktop, mobile)

### Portainer
Docker container management platform with web UI.

**Location**: `apps/portainer/`
**Setup Guide**: `apps/portainer/PORTAINER_SETUP.md`

### Traefik (Alternative)
Cloudflare Tunnel setup for services without port forwarding.

**Location**: `apps/traefik/`
**Setup Guide**: `apps/traefik/CLOUDFLARE_SETUP.md`

## Quick Start

1. Install Portainer
2. Deploy Nginx Proxy Manager stack
3. Upload SSL certificates
4. Deploy Homepage for service dashboard with integrations
5. (Optional) Deploy Dashy for alternative customizable homepage
6. Deploy Dockpeek for container monitoring
7. (Optional) Deploy Code-Server for browser-based development
8. Configure proxy hosts for your services

## Network Architecture

All services use Docker bridge networks for isolation and communication:
- Nginx Proxy Manager exposes ports 80, 443 (public) and 81 (admin)
- Internal services communicate via container names
- External access controlled through NPM proxy hosts

## Support

Each application has its own setup guide with troubleshooting steps. Check the respective `*_SETUP.md` files.

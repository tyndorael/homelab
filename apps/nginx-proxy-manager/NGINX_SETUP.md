# Nginx Proxy Manager Setup Guide

Nginx Proxy Manager is the easiest way to manage reverse proxy and SSL certificates with a beautiful web interface.

## Installation Steps

### 1. Deploy in Portainer

1. Go to **Stacks** → **Add stack**
2. Name it "nginx-proxy-manager"
3. Upload `nginx-proxy-manager-stack.yml` or paste its contents
4. Configure environment variable:
   - `TZ`: Your timezone (e.g., `America/New_York`)
5. Click **Deploy the stack**

### 2. Initial Login

1. Access the admin interface: `http://your-vm-ip:81`
2. Default credentials:
   - **Email**: `admin@example.com`
   - **Password**: `changeme`
3. **Change these immediately** after first login!

### 3. Add SSL Certificates Manually

1. In NPM, go to **SSL Certificates** → **Add SSL Certificate**
2. Choose **Custom** to upload your own certificate files
3. Upload your certificate and private key files
4. Click **Save**

### 4. Add Your First Proxy Host

1. In NPM, go to **Hosts** → **Proxy Hosts**
2. Click **Add Proxy Host**
3. Fill in:
   - **Domain Names**: Your domain (e.g., `portainer.example.com`)
   - **Scheme**: `http` or `https`
   - **Forward Hostname/IP**: Container name (e.g., `portainer`) or IP
   - **Forward Port**: Container port (e.g., `9000`)
   - Enable **Block Common Exploits**
   - Enable **Websockets Support** (if needed)

4. Go to **SSL** tab:
   - Select your uploaded SSL certificate
   - Enable **Force SSL**
   - Enable **HTTP/2 Support**
   - Enable **HSTS Enabled** (optional but recommended)
   - Click **Save**

### 5. Port Forwarding

Forward these ports on your router to your Docker VM:
- **Port 80** (HTTP) - For web traffic
- **Port 443** (HTTPS) - Your secure traffic

**Admin port 81** should NOT be exposed to the internet!

## Access URLs

- **Admin Panel**: http://your-vm-ip:81
- **Your services**: https://your-domain.com

## Example: Exposing Portainer
      - nginx-proxy-manager

networks:
  portainer_network:
  nginx-proxy-manager:
    external: true
```

## Example: Exposing Portainer

Create a Proxy Host in NPM:

1. **Domain**: `portainer.yourdomain.com`
2. **Forward Hostname**: `portainer` (container name) or IP address
3. **Forward Port**: `9000`
4. Go to **SSL** tab and select your certificate
5. Enable **Force SSL**, **HTTP/2**, and **HSTS**
6. Save

Access at: `https://portainer.yourdomain.com`

## Features

✅ **Beautiful Web UI** - No config files needed
✅ **Manual SSL** - Upload your own certificates
✅ **Access Lists** - Control who can access services
✅ **Custom Locations** - Advanced routing
✅ **Stream Proxies** - TCP/UDP proxying
✅ **Dead Simple** - Point and click configuration

## Troubleshooting

**Can't access admin panel:**
- Check container is running: `docker ps | grep nginx-proxy-manager`
- Verify port 81 is not blocked by firewall
- Try: `http://localhost:81` from the VM

**SSL certificate issues:**
- Ensure certificate and private key are valid
- Check certificate hasn't expired
- Verify domain matches certificate CN/SAN

**502 Bad Gateway:**
- Service container not running
- Wrong forward hostname (use container name if on same network)
- Wrong forward port
- Check both containers are on the same network

## Security Best Practices

- Change default admin credentials immediately
- Don't expose port 81 to the internet
- Use strong passwords
- Enable access lists for sensitive services
- Keep NPM updated
- Keep SSL certificates up to date

## Useful Commands

View logs:
```bash
docker logs nginx-proxy-manager -f
```

Restart NPM:
```bash
docker restart nginx-proxy-manager
```

Check container status:
```bash
docker ps | grep nginx-proxy-manager
```

## Next Steps

1. Upload your SSL certificates
2. Add proxy hosts for all your services
3. Set up access lists for authentication
4. Configure custom locations for path-based routing
5. Explore stream proxies for non-HTTP services


# Portainer Setup Guide

Deploy Portainer first, then use it to manage other stacks like Kong.

## Installation Steps

### 1. Prepare the Volume Directory

SSH into your Docker VM and create the directory:

```bash
mkdir -p /nfs/vm_shares/herta/apps/portainer/data
```

### 2. Deploy Portainer

On your Docker VM, run:

```bash
docker compose -f portainer-stack.yml up -d
```

Or manually deploy with docker run:

```bash
docker run -d \
  --name portainer \
  --restart unless-stopped \
  -p 9443:9443 \
  -p 9000:9000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /nfs/vm_shares/herta/apps/portainer/data:/data \
  portainer/portainer-ce:latest
```

### 3. Initial Setup

1. Open your browser and go to: `https://your-vm-ip:9443` (or `http://your-vm-ip:9000`)
2. Create your admin account (you have 5 minutes after first start)
3. Choose **"Get Started"** to connect to the local Docker environment
4. You'll see your Docker endpoint

### 4. Deploy Kong Stack

Once Portainer is running:

1. In Portainer, go to **Stacks** → **Add stack**
2. Name it "kong-gateway"
3. Choose **"Upload"** and select `kong-stack.yml`
   - OR paste the contents from the file
4. Scroll down to **Environment variables**
5. Add your variables from `.env`:
   ```
   KONG_PG_PASSWORD=your-secure-password
   KONGA_TOKEN_SECRET=your-random-token
   DUCKDNS_SUBDOMAINS=your-subdomain
   DUCKDNS_TOKEN=your-duckdns-token
   TZ=America/New_York
   ```
6. Click **Deploy the stack**

### 5. Verify Installation

Check that all services are running:
- Portainer should show all Kong containers as "running"
- Access Konga at `http://your-vm-ip:1337`

## Access URLs

- **Portainer HTTPS**: https://your-vm-ip:9443
- **Portainer HTTP**: http://your-vm-ip:9000

## Important Notes

⚠️ **Port Conflict**: Portainer uses port 8000 for Edge Agent, which conflicts with Kong's proxy port. You have two options:

1. **Disable Portainer Edge Agent** (recommended if not needed):
   - Remove the `8000:8000` port mapping from `portainer-stack.yml`
   
2. **Change Kong proxy port**:
   - Modify Kong's port mapping in `kong-stack.yml` (e.g., `8080:8000`)

## Security Recommendations

- Use HTTPS (port 9443) instead of HTTP
- Create a strong admin password
- Don't expose Portainer to the internet without proper security
- Consider using Portainer Business Edition for RBAC if managing multiple users

## Troubleshooting

**Can't access Portainer:**
- Check if container is running: `docker ps | grep portainer`
- Check logs: `docker logs portainer`
- Verify firewall allows ports 9443 and 9000

**Lost admin password:**
- Stop Portainer, reset password with recovery tool:
  ```bash
  docker stop portainer
  docker run --rm -v /nfs/vm_shares/herta/apps/portainer/data:/data portainer/helper-reset-password
  docker start portainer
  ```

## Updating Portainer

```bash
docker stop portainer
docker rm portainer
docker pull portainer/portainer-ce:latest
# Then re-run the installation command
```

## Next Steps

After Portainer is set up, proceed with deploying the Kong stack as described in `README.md`.

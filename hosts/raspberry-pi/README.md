# Raspberry Pi — edge / control node

Runs the always-on, lightweight services: reverse proxy, Docker management and the dashboard.

| Stack | Port(s) | URL (after NPM setup) |
|---|---|---|
| `nginx-proxy-manager` | 80, 443, 81 (admin) | `https://npm.<domain>` |
| `portainer` | 9443 | `https://portainer.<domain>` |
| `homepage` | 3000 | `https://home.<domain>` |

## Host preparation
1. Flash **Raspberry Pi OS Lite (64-bit)**; prefer booting from an **SSD/NVMe** over the SD card.
2. Give the Pi a **DHCP reservation** (fixed IP) on the router.
3. Harden SSH: key-only auth (`PasswordAuthentication no`), then enable `unattended-upgrades`.
4. Install Docker and allow your user to run it:
   ```bash
   curl -fsSL https://get.docker.com | sh
   sudo usermod -aG docker $USER   # log out/in afterwards
   ```
5. Clone the repo: `git clone <repo> ~/homelab && cd ~/homelab`.

## First start
```bash
make network HOST=raspberry-pi                 # creates the shared `proxy` network (once)
for s in nginx-proxy-manager portainer homepage; do
  cp hosts/raspberry-pi/$s/.env.example hosts/raspberry-pi/$s/.env   # then edit each .env
done
make up HOST=raspberry-pi STACK=nginx-proxy-manager
make up HOST=raspberry-pi STACK=portainer
make up HOST=raspberry-pi STACK=homepage
```

Then:
- **NPM** (`http://<pi-ip>:81`): create the admin account on first login, request a wildcard certificate `*.<domain>` (DNS challenge), and add proxy hosts. Services on the Pi are reachable by container name over the `proxy` network (`portainer:9443` with scheme `https`, `homepage:3000`); Unraid/Mac services by `LAN_IP:port`.
- **Portainer** (`https://<pi-ip>:9443`): create the admin user within 5 minutes of the first start, then *Environments → Add → Agent* for Unraid (`<unraid-ip>:9001`) and the Mac mini (`<mac-ip>:9001`).
- Once everything is proxied, set `ADMIN_BIND` / `PORTAINER_BIND` / `HOMEPAGE_BIND=127.0.0.1` in the `.env` files so the raw ports are no longer exposed on the LAN, then `make up` again.

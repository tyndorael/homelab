# Network

Replace the placeholders with your real values (keep this file free of secrets).

## Hosts
| Host | Role | IP (DHCP reservation) | Hostname |
|---|---|---|---|
| Raspberry Pi | Proxy, Portainer, dashboard | `192.168.1.10` | `pi` |
| Unraid | NAS, media | `192.168.1.20` | `unraid` |
| Mac mini | Development, apps | `192.168.1.30` | `mac-mini` |

## Ports
| Host | Port | Service | Exposure |
|---|---|---|---|
| Pi | 80 / 443 | Nginx Proxy Manager | LAN |
| Pi | 81 | NPM admin | LAN → `127.0.0.1` after setup |
| Pi | 9443 | Portainer | LAN → `127.0.0.1` after setup |
| Pi | 3000 | Homepage | LAN → `127.0.0.1` after setup |
| Unraid | 80/443 | Unraid web UI | LAN |
| Unraid | 9001 | Portainer Agent | LAN (Pi only, ideally) |
| Unraid | 8096 | Jellyfin | LAN |
| Unraid | 8989 / 7878 / 9696 | Sonarr / Radarr / Prowlarr | LAN |
| Unraid | 8080, 6881 tcp/udp | qBittorrent | LAN |
| Mac mini | 9001 | Portainer Agent | LAN (Pi only, ideally) |

## DNS & TLS
1. Pick a domain you own, e.g. `home.example.com`.
2. In your local DNS (router, Pi-hole or AdGuard Home) add a wildcard: `*.home.example.com → 192.168.1.10` (the Pi).
3. In NPM, request one wildcard Let's Encrypt certificate for `*.home.example.com` using the **DNS challenge** (e.g. Cloudflare API token). No ports need to be opened to the internet.
4. Create a proxy host per service (`portainer.home.example.com → portainer:9443 https`, `jellyfin.home.example.com → 192.168.1.20:8096`, …) with the wildcard cert, *Force SSL* and *HTTP/2* enabled. Turn on *Websockets support* for Portainer, Jellyfin and Homepage.

## Remote access
Don't port-forward 80/443. Use Tailscale (subnet router on the Pi) or WireGuard to reach the LAN from outside.

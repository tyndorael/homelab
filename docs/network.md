# Network

LAN `192.168.50.0/24`. Replace the TBD values as machines come online (keep this file free of secrets).

## Hosts
| Host | Role | IP (DHCP reservation) | Hostname |
|---|---|---|---|
| Raspberry Pi 4 (8 GB, microSD) | Proxy, Portainer, dashboard | `192.168.50.106` | `cyrene` |
| Unraid | NAS, media | `192.168.50.x` (TBD) | `unraid` |
| Mac mini | Development, apps | `192.168.50.x` (TBD) | `mac-mini` |

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
1. Domain: a DuckDNS subdomain today (`<name>.duckdns.org`, set as `DOMAIN` in `homepage/.env`); any domain you own works.
2. In your local DNS (router, Pi-hole or AdGuard Home) add a wildcard: `*.<domain> → 192.168.50.106` (the Pi).
3. In NPM, request one wildcard Let's Encrypt certificate for `*.<domain>` using the **DNS challenge** (DuckDNS token today; Cloudflare etc. also work). No ports need to be opened to the internet.
4. Create a proxy host per service (`portainer.<domain> → portainer:9443 https`, `jellyfin.<domain> → <unraid-ip>:8096`, …) with the wildcard cert, *Force SSL* and *HTTP/2* enabled. Turn on *Websockets support* for Portainer, Jellyfin and Homepage.

## Remote access
Don't port-forward 80/443. Use Tailscale (subnet router on the Pi) or WireGuard to reach the LAN from outside.

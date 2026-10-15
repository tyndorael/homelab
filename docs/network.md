# Network

LAN `192.168.50.0/24`. Replace the TBD values as machines come online (keep this file free of secrets).

## Hosts
| Host | Role | IP (DHCP reservation) | Hostname |
|---|---|---|---|
| Raspberry Pi 4 (8 GB, microSD) | Proxy, Portainer, dashboard | `192.168.50.106` | `cyrene` |
| Unraid | NAS, media | `192.168.50.x` (TBD) | `unraid` |
| Mac mini M2 (8 GB) | Development, apps | `192.168.50.206` (Ethernet) | `silverwolf` |

## Ports
| Host | Port | Service | Exposure |
|---|---|---|---|
| Pi | 80 / 443 | Nginx Proxy Manager | LAN |
| Pi | 81 | NPM admin | `127.0.0.1` only (via `npm.<domain>`) |
| Pi | 9443 | Portainer | `127.0.0.1` only (via `portainer.<domain>`) |
| Pi | 3000 | Homepage | `127.0.0.1` only (via `home.<domain>`) |
| Pi | 8084 | Glance | `127.0.0.1` only (via `glance.<domain>`) |
| Pi | 8085 | Gatus | `127.0.0.1` only (via `status.<domain>`) |
| Pi | 8086 | Dozzle | `127.0.0.1` only (via `logs.<domain>`) |
| Pi | 8087 | Termix | `127.0.0.1` only (via `termix.<domain>`) |
| Pi | 9090 | Cockpit (host service) | `127.0.0.1` + `proxy` gateway only (via `cockpit.<domain>`) |
| Pi | 53 tcp/udp | AdGuard Home DNS | LAN |
| Pi | 3001 / 8083 | AdGuard Home setup / UI | `127.0.0.1` only (via `adguard.<domain>`) |
| Pi | 41641/udp | Tailscale (host network) | WAN outbound/UDP, no port forward needed |
| Unraid | 80/443 | Unraid web UI | LAN |
| Unraid | 9001 | Portainer Agent | LAN (Pi only, ideally) |
| Unraid | 8096 | Jellyfin | LAN |
| Unraid | 8989 / 7878 / 9696 | Sonarr / Radarr / Prowlarr | LAN |
| Unraid | 8080, 6881 tcp/udp | qBittorrent | LAN |
| Mac mini | 9001 | Portainer Agent | LAN (Pi only, ideally) |

## DNS & TLS
1. Domain: a DuckDNS subdomain today (`<name>.duckdns.org`, set as `DOMAIN` in `homepage/.env`); any domain you own works.
2. Local DNS is **AdGuard Home on the Pi**: a DNS rewrite `*.<domain> → 192.168.50.106` sends every service name to NPM. The router hands out `192.168.50.106` as DNS (secondary: a public resolver). Details in the [Pi README](../hosts/raspberry-pi/README.md#adguard-home).
3. In NPM, request one wildcard Let's Encrypt certificate for `*.<domain>` using the **DNS challenge** (DuckDNS token today; Cloudflare etc. also work). No ports need to be opened to the internet.
4. Create a proxy host per service (`portainer.<domain> → portainer:9443 https`, `jellyfin.<domain> → <unraid-ip>:8096`, …) with the wildcard cert, *Force SSL* and *HTTP/2* enabled. Turn on *Websockets support* for Portainer, Jellyfin and Homepage.

## Remote access
Don't port-forward 80/443. **Tailscale** runs on the Pi as a subnet router for `192.168.50.0/24`: any device on the tailnet reaches the whole LAN, and with split DNS (`<domain>` → `192.168.50.106`) the same `https://<service>.<domain>` URLs work away from home. Setup in the [Pi README](../hosts/raspberry-pi/README.md#tailscale).

# Network

LAN `192.168.50.0/24`. Replace the TBD values as machines come online (keep this file free of secrets).

## Hosts
| Host | Role | IP (DHCP reservation) | Hostname |
|---|---|---|---|
| Raspberry Pi 4 (8 GB, microSD) | Proxy, Portainer, dashboard | `192.168.50.106` | `cyrene` |
| Unraid (Dell Precision 5820, 10GbE) | NAS, media, VMs | `192.168.50.153` (10GbE) | `herta` |
| Mac mini M2 (8 GB) | Development, apps | `192.168.50.206` (Ethernet) | `silverwolf` |
| Home Assistant OS (VM on Unraid, `br0`) | Home automation | `192.168.50.217` (MAC `52:54:00:b6:ff:3f`) | `homeassistant` |

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
| Pi | 21115–21117 tcp, 21116 udp | RustDesk ID + relay (host network) | LAN / tailnet, never forwarded |
| Unraid | 80/443 | Unraid web UI | LAN (via `herta.<domain>`) |
| Unraid | 9001 | Portainer Agent | LAN (Pi only, ideally) |
| Unraid | 8096 | Jellyfin | LAN |
| Unraid | 8989 / 7878 / 9696 | Sonarr / Radarr / Prowlarr | LAN |
| Unraid | 8080, 6881 tcp/udp | qBittorrent | LAN |
| HA VM | 80 (8123 redirects to 80) | Home Assistant | LAN (via `ha.<domain>`) |
| HA VM | 4357 | HAOS Observer (Supervisor health) | LAN |
| Mac mini | 9001 | Portainer Agent | LAN (Pi only, ideally) |
| Mac mini | 22 | SSH (key only) | LAN |
| Mac mini | 5900 | Screen Sharing (VNC) | LAN / tailnet — see [remote-desktop.md](remote-desktop.md) |
| Mac mini | 7007 | Dozzle agent (mTLS, private cert) | LAN (Pi's Dozzle) |
| Mac mini | 8088 | Open WebUI | LAN (via `ai.<domain>`) |
| Mac mini | 11434 | Ollama (native) | `127.0.0.1` only |

## DNS & TLS
1. Domain: a DuckDNS subdomain today (`<name>.duckdns.org`, set as `DOMAIN` in `homepage/.env`); any domain you own works.
2. Local DNS is **AdGuard Home on the Pi**: a DNS rewrite `*.<domain> → 192.168.50.106` sends every service name to NPM. The router hands out `192.168.50.106` as DNS (secondary: a public resolver). Details in the [Pi README](../hosts/raspberry-pi/README.md#adguard-home).
3. In NPM, request one wildcard Let's Encrypt certificate for `*.<domain>` using the **DNS challenge** (DuckDNS token today; Cloudflare etc. also work). No ports need to be opened to the internet.
4. Create a proxy host per service (`portainer.<domain> → portainer:9443 https`, `jellyfin.<domain> → <unraid-ip>:8096`, …) with the wildcard cert, *Force SSL* and *HTTP/2* enabled. Turn on *Websockets support* for Portainer, Jellyfin, Homepage and Home Assistant.

## Remote access
Don't port-forward 80/443. **Tailscale** runs on the Pi as a subnet router for `192.168.50.0/24`: any device on the tailnet reaches the whole LAN, and with split DNS (`<domain>` → `192.168.50.106`) the same `https://<service>.<domain>` URLs work away from home. Setup in the [Pi README](../hosts/raspberry-pi/README.md#tailscale).

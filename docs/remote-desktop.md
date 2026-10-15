# Remote desktop

How to see and control the Mac mini (`silverwolf`, `192.168.50.206`) from Macs, Windows and any browser — at home or away (through Tailscale; nothing is exposed to the internet).

| Method | From | Install on the Mac mini | Best for |
|---|---|---|---|
| **Built-in Screen Sharing** | Mac (Screen Sharing app), Windows (RealVNC Viewer) | nothing, already on | Mac → Mac, quick access |
| **RustDesk** (self-hosted on the Pi) | Mac, Windows, Linux, iOS, Android | RustDesk app | Smoothest cross-platform, one tool everywhere |
| **Termix Remote Desktop** | any browser (`termix.<domain>`) | nothing (uses Screen Sharing) | When you only have a browser |

## Running without a monitor
macOS still works headless, but with no display attached remote sessions fall back to a low resolution and lose some GPU acceleration. Use **one** of:
- **4K HDMI dummy plug** (recommended, ~$10): the Mac thinks a 4K screen is connected. Works with every client.
- **BetterDisplay** virtual screen (software; must start at login).
- Mac clients only: Screen Sharing's **High Performance** mode creates a virtual display at the client's resolution (Apple silicon, macOS 14+ on both ends).

Auto-login is enabled on the Mac mini, so after a reboot the desktop session exists and every method below works without anyone at the keyboard.

## 1. Built-in Screen Sharing (VNC, port 5900)
Already enabled (*System Settings → General → Sharing → Screen Sharing*).
- **From a Mac**: Finder → *Go → Connect to Server…* → `vnc://192.168.50.206`, or open the **Screen Sharing** app. Log in with the Mac mini's user. In the toolbar choose **High Performance** when both Macs are Apple silicon.
- **From Windows**: install **RealVNC Viewer** (free), connect to `192.168.50.206`, log in with the Mac mini's macOS username and password (RealVNC speaks Apple's authentication). Other VNC viewers (TigerVNC, UltraVNC) need the legacy *"VNC viewers may control screen with password"* option in Screen Sharing settings — avoid it unless needed, that password is limited to 8 characters.

## 2. RustDesk (self-hosted)
The Pi runs the RustDesk ID + relay server (`hosts/raspberry-pi/rustdesk`), so no RustDesk-operated servers are used.

**Mac mini (host)** — `brew install --cask rustdesk`, open it once, then grant in *System Settings → Privacy & Security*:
- **Screen & System Audio Recording** → RustDesk
- **Accessibility** → RustDesk
- (prompted on first connection) **Input Monitoring** → RustDesk

In RustDesk → *Settings → Security*: **set a permanent password** (you set this yourself) and enable **Start RustDesk on login** / service so it runs after reboots.

**Every client and host** (step-by-step for Windows and Mac clients in the [README](../README.md#remote-desktop-to-the-mac-mini); the Mac mini's ID is `80340206`) — *Settings → Network → ID/Relay server*:
| Field | Value |
|---|---|
| ID server | `192.168.50.106` |
| Relay server | `192.168.50.106` |
| API server | *(empty)* |
| Key | contents of `hosts/raspberry-pi/rustdesk/data/id_ed25519.pub` on the Pi |

Read the key on the Pi with `cat ~/homelab/hosts/raspberry-pi/rustdesk/data/id_ed25519.pub`. (It is a public key, but it stays out of git so the server identity can be rotated.) Then connect to the Mac mini's RustDesk **ID** with its permanent password. On the LAN, connections go direct; away from home they work over Tailscale (the Pi routes `192.168.50.0/24`).

## 3. Termix Remote Desktop (browser)
Termix's bundled Remote Desktop plugin talks to `guacd` (in the termix stack). In Termix: add a host → protocol **VNC** → `192.168.50.206`, port `5900`, with the Mac mini's macOS username and password. Clipboard works; it's a bit less fluid than a native client.

## Security
- None of these ports are forwarded on the router; remote access is only via Tailscale.
- Screen Sharing and Termix use the macOS account password; RustDesk uses its own permanent password and only accepts clients that know the server key (`-k _`).

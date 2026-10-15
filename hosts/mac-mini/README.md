# Mac mini — development + app runner

| Stack | Port(s) |
|---|---|
| `portainer-agent` | 9001 |
| `apps/<name>` | per app |

## Hardware & OS
| | |
|---|---|
| Hostname | `silverwolf` |
| IP | `192.168.50.206` (Ethernet `en0`, DHCP reservation; Wi-Fi not connected) |
| Model | Mac mini, Apple M2, 8 GB RAM |
| Storage | 228 GB internal SSD |
| OS | macOS 27.0.1 |
| Docker | OrbStack 2.2 (Docker 29.8, Compose v5.5), started at login |
| SSH | key login as `tyndorael` (the same key as the Pi) |

## Unattended server settings (done 2026-10-15)
The Mac must come back on its own after a power cut, with Docker running, and nobody at the keyboard:
- **FileVault off + auto-login** as `tyndorael`. With FileVault on, macOS waits at the unlock screen after every reboot and OrbStack never starts. The trade-off: the disk isn't encrypted at rest, so keep secrets in `.env` files only, not on the desktop.
- **Power**: `sudo pmset -a sleep 0 disksleep 0 womp 1 autorestart 1 powernap 0` (never sleep, wake on LAN, power on after power failure).
- **OrbStack** starts at login: `orb config set app.start_at_login true`. Containers use `restart: unless-stopped`.
- Homebrew in `/opt/homebrew` (shellenv in `~/.zprofile`).

## Stacks
| Stack | Port(s) | Notes |
|---|---|---|
| `portainer-agent` | 9001 | managed from Portainer on the Pi |
| `dozzle-agent` | 7007 | logs show in `logs.<domain>`; cert pair in `dozzle-agent/data/certs` (copied from the Pi) |
| `apps/open-webui` | 8088 | `ai.<domain>` via NPM |

## Local AI (Ollama + Open WebUI)
- **Ollama runs natively** (`brew install ollama`, `brew services start ollama`): only native macOS processes can use the M2 GPU (Metal), Docker can't. It listens on `127.0.0.1:11434` only; Open WebUI reaches it as `host.docker.internal:11434` (OrbStack).
- **Models**: 8 GB of unified memory is shared with macOS and OrbStack, so stay with small models. Installed: `llama3.2:3b` (2 GB, ~48 tokens/s, 100% GPU). Reasonable additions: `qwen2.5:3b`, `gemma3:4b`; 7–8B models (`qwen2.5:7b`, `llama3.1:8b`, ~4.7 GB) fit only with little else running. Manage with `ollama pull <model>`, `ollama list`, `ollama rm <model>`, `ollama ps`.
- **Open WebUI** (`apps/open-webui`): the first account to sign up becomes **admin** — register immediately after the first start, then *Admin Panel → Settings → General → disable "Enable New Sign Ups"*. Later sign-ups (if re-enabled) wait as `pending`. NPM proxy host: `ai.<domain>` → `http://192.168.50.206:8088`, websockets on.
- Update Ollama with `brew upgrade ollama && brew services restart ollama`.

## Remote desktop
Screen Sharing (VNC) is enabled; RustDesk and browser access via Termix are also set up. Running headless needs an HDMI dummy plug or a virtual display. See [docs/remote-desktop.md](../../docs/remote-desktop.md).

## Host preparation (fresh Mac)
1. Steps above, then `brew install --cask orbstack`, open it once and pick Docker.
2. Clone the repo: `git clone https://github.com/tyndorael/homelab.git ~/homelab`.

## Start
```bash
cp hosts/mac-mini/portainer-agent/.env.example hosts/mac-mini/portainer-agent/.env   # same AGENT_SECRET as the Pi
make up HOST=mac-mini STACK=portainer-agent
```
Then in Portainer (on the Pi): *Environments → Add environment → Docker Standalone → Agent*, address `192.168.50.206:9001`. The agent only mounts the Docker socket (macOS keeps volumes inside OrbStack's VM).

## Adding an app
```bash
cp -R templates/service hosts/mac-mini/apps/<name>
# edit compose.yaml + .env.example, then:
cp hosts/mac-mini/apps/<name>/.env.example hosts/mac-mini/apps/<name>/.env
make up HOST=mac-mini STACK=apps/<name>
```
Images must have an `arm64` build (or run them with `platform: linux/amd64`, slower via emulation).
Keep throwaway dev containers (project databases, etc.) in each project's own repo; `apps/` is for long-running services you want listed in the homelab.

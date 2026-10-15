# Mac mini — development + app runner

| Stack | Port(s) |
|---|---|
| `portainer-agent` | 9001 |
| `apps/<name>` | per app |

## Host preparation
1. Install a Docker runtime: **OrbStack** (lighter, recommended on Apple Silicon) or **Docker Desktop**.
   - Docker Desktop: *Settings → Advanced → Allow the default Docker socket to be used*.
   - Enable "start at login" so apps come back after a reboot.
2. *System Settings → Energy*: prevent automatic sleep and enable "Start up automatically after a power failure".
3. Give the Mac a DHCP reservation and clone the repo (e.g. `~/homelab`).

## Start
```bash
cp hosts/mac-mini/portainer-agent/.env.example hosts/mac-mini/portainer-agent/.env   # same AGENT_SECRET as the Pi
make up HOST=mac-mini STACK=portainer-agent
```

## Adding an app
```bash
cp -R templates/service hosts/mac-mini/apps/<name>
# edit compose.yaml + .env.example, then:
cp hosts/mac-mini/apps/<name>/.env.example hosts/mac-mini/apps/<name>/.env
make up HOST=mac-mini STACK=apps/<name>
```
Images must have an `arm64` build (or run them with `platform: linux/amd64`, slower via emulation).
Keep throwaway dev containers (project databases, etc.) in each project's own repo; `apps/` is for long-running services you want listed in the homelab.

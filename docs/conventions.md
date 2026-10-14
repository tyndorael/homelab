# Conventions

Every stack in `hosts/<host>/<stack>/` follows these rules. `templates/service/` already applies them.

## Layout
- One folder = one Compose project: `compose.yaml` + `.env.example` (+ optional tracked config).
- Top-level `name:` set explicitly; no `version:` key (obsolete).
- Stacks are managed with `make <target> HOST=… STACK=…` or `docker compose` inside the folder.

## Images
- **Pin exact tags** (`2.45.2`, `v2.5.0`, `…-ls328`), never `:latest` — upgrades become explicit, reviewable commits.
- Renovate (`renovate.json`) opens PRs for new tags; majors wait for approval on the dependency dashboard.
- Upgrade on the host with `git pull && make update HOST=… STACK=…`.
- On the Pi and Mac mini, check the image has an `arm64` build.

## Storage
- **Bind mounts only, relative to the compose file**: `./data`, `./config`, `./config/<app>` for multi-app stacks. Gitignored.
- No named volumes and no network mounts for app state (SQLite over NFS/SMB corrupts).
- Exception: bulk media on Unraid via `${DATA_ROOT}` (one share, single `/data` path in every container).

## Configuration & secrets
- All host-specific values and secrets in `.env` (gitignored); every variable documented in `.env.example`.
- Required secrets use `${VAR:?message}` so the stack refuses to start without them.
- `TZ`, `PUID`, `PGID` on every service (Pi/Mac `1000:1000`, Unraid `99:100` + `UMASK=002`).

## Runtime
- `restart: unless-stopped`.
- `security_opt: [no-new-privileges:true]`.
- A `healthcheck` whenever the image ships a way to test itself.
- Log rotation via the `x-logging` anchor (`json-file`, 10 MB × 3) — protects the Pi's storage.
- Docker socket: only Portainer and its agents mount it directly; anything that only needs to *read* container state goes through a socket proxy (see `homepage`).

## Networking
- Pi: services that NPM proxies join the external `proxy` network and are addressed by container name.
- Unraid / Mac: NPM proxies them by `LAN_IP:port`.
- Once a service is proxied, bind its raw port to `127.0.0.1` (or remove it) instead of the whole LAN.
- Never port-forward from the internet; use a VPN (Tailscale/WireGuard) for remote access.

## Adding a service
1. `cp -R templates/service hosts/<host>/<name>` and edit `compose.yaml` / `.env.example`.
2. `cp .env.example .env`, fill it, `make validate`.
3. `make up HOST=<host> STACK=<name>`, add a proxy host in NPM and an entry in Homepage's `services.yaml`.
4. Add its port to [network.md](network.md) and commit.

# Homelab — notes for Claude

Docker Compose homelab, one folder per stack under `hosts/<host>/<stack>/`. Start with `README.md`, `docs/conventions.md` and `docs/network.md`. Machine-specific values (domain, key paths) are in `CLAUDE.local.md` (gitignored).

## Hosts
| Host | Name | IP | SSH | Repo checkout on the host |
|---|---|---|---|---|
| Raspberry Pi 4 (microSD) | cyrene | 192.168.50.106 | `tyndorael@` | `~/homelab` (has `make`) |
| Unraid 7.3 on Dell Precision 5820 | herta | 192.168.50.153 | `root@` | `/mnt/user/appdata/homelab` (no `make`, use `docker compose` in the stack folder) |
| Mac mini M2 (OrbStack) | silverwolf | 192.168.50.206 | `tyndorael@` | `~/homelab` runs the stacks; `~/Documents/Development/homelab` is a dev clone |
| Home Assistant OS VM on herta | homeassistant | 192.168.50.217 | — | — |

- SSH to every host with the key in `CLAUDE.local.md`, using `-o BatchMode=yes` and **always the IP** (old host keys exist for some names).
- On the Mac mini, non-login SSH has no `docker` in PATH: use `/usr/local/bin/docker` or `zsh -lc '…'`.
- The local shell is **zsh**: quote globs (`--include='*.md'`). Use small shell functions for repeated SSH calls; zsh doesn't word-split a variable holding a command.

## How changes are made
1. Edit in this repo, run `make validate`, commit **directly to `main`** (no PRs unless asked) and push.
2. On the host: `git pull --ff-only`, then `make up HOST=<host> STACK=<stack>` (Pi), or `docker compose up -d` in the stack folder (herta, Mac mini).
3. Verify after deploying: container health, the app's HTTP endpoint, and Gatus. Gatus should be all green; check it with `curl -s http://127.0.0.1:8085/api/v1/endpoints/statuses` on the Pi.
4. Keep the docs in the same commit: the host README, `docs/network.md` (IPs/ports) and the `.env.example` files.

## Conventions (see docs/conventions.md)
- Pinned image tags (never `latest`; pick releases at least ~2 weeks old), a `x-logging` anchor (json-file 10m × 3), `restart: unless-stopped`, `no-new-privileges`, healthchecks where possible.
- State in local bind mounts (`./data`, `./config`), gitignored. Secrets only in `.env` (gitignored); every variable has a `.env.example` entry.
- Pi: services join the external `proxy` network; admin ports bind to `127.0.0.1` (`*_BIND` vars). NPM proxies by container name. Unraid/Mac services are proxied by `IP:port`.
- Docker socket access goes through a read-only socket proxy where the app allows it.

## Service-specific gotchas
- **Gatus** doesn't reload config. After changing `gatus/config/config.yaml`: `docker restart gatus`.
- **Homepage** pre-renders its page. The healthcheck calls `/api/revalidate`, so changes appear within a minute (or `make up`). Widget secrets are `HOMEPAGE_VAR_*` env vars.
- **Glance** hot-reloads, and it expands `${VAR}` even inside YAML comments.
- **Dozzle**: remote agents are in `REMOTE_AGENTS` (`ip:7007|label`, comma-separated) in the Pi's `dozzle/.env`. Agents need the Pi's private cert pair copied to `dozzle-agent/data/certs`.
- **Portainer agents** use the same `AGENT_SECRET` as the Pi's Portainer.
- **Unraid**: the OS runs from RAM. Persistent changes go on the flash (`/boot/config`), e.g. the docker compose plugin in `/boot/config/go` (see `hosts/unraid/host/docker-compose/install.sh`). Shares `appdata`/`system`/`domains` are exclusive on the ZFS `cache` pool; media is in `/mnt/user/data/{torrents,media}`, owned 99:100. Jellyfin uses the RTX 3050 via the nvidia runtime.
- **NPM** uses one wildcard certificate (`*.<domain>`, DNS challenge). The user creates proxy hosts in the NPM UI; Claude adds the matching Gatus/Homepage/Glance entries.

## Safety rules agreed with the user
- **Never type or use passwords.** The user installs SSH keys, logs in to UIs and creates admin accounts themselves.
- **Never print secrets** (`.env` values, API keys, private keys). Move them between hosts with pipes (`ssh a 'cat …' | ssh b 'cat > …'`) and confirm with checksums or line counts.
- **Ask before anything destructive or hard to undo**: wiping or formatting disks, deleting data, stopping the Unraid array, changing router or BIOS settings. Read-only inspection is fine without asking.
- Short network interruptions on a host (e.g. NIC tests) run as a detached script that restores the setting by itself.

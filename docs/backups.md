# Backups

Follow 3-2-1: three copies, two different media, one off-site.

## What to back up
| Item | Where | Why |
|---|---|---|
| This repo | GitHub | compose files, tracked config, docs |
| `.env` files | password manager / encrypted copy | secrets are not in git |
| `hosts/*/*/data`, `config`, `letsencrypt` | stack folders | app state |
| Media library | Unraid array (parity is **not** a backup) | replaceable vs. irreplaceable — decide per share |

## How
- **Pi / Mac mini**: `scripts/backup.sh <host> <stack> <dest>` stops the stack, archives its folder and restarts it (keeps the 7 newest). Point `<dest>` at an Unraid share and schedule it with cron, e.g.:
  ```cron
  30 3 * * * cd ~/homelab && scripts/backup.sh raspberry-pi portainer /mnt/backups/pi >> /tmp/backup.log 2>&1
  ```
- **Unraid**: the *Appdata Backup* plugin covers `/mnt/user/appdata` (including `homelab/`); add an off-site copy (e.g. Backblaze B2 via rclone/Duplicacy).

## Restore
1. Clone the repo, restore `.env`.
2. Extract the archive into `hosts/<host>/` (it contains the stack folder).
3. `make up HOST=<host> STACK=<stack>`.

Test a restore at least once — an untested backup isn't a backup.

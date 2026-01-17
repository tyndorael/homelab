# Health Stack (wger)

Docker Compose stack for the wger fitness/workout tracker.

## Prereqs
- Docker + Docker Compose
- External network `nginx-proxy-manager` already created (from infrastructure stack)
- NFS or local path for data (defaults to `/nfs/vm_shares/herta/apps/wger`)

## Configure
Create a `.env` in this folder (adjust paths if you prefer different storage):

```env
TZ=UTC
WGER_DB_NAME=wger
WGER_DB_USER=wger
WGER_DB_PASSWORD=change-me
WGER_SECRET_KEY=change-me
WGER_ALLOWED_HOSTS=*
WGER_ADMIN_USER=admin
WGER_ADMIN_EMAIL=admin@example.com
WGER_ADMIN_PASSWORD=change-me
```

Change all `change-me` values to strong secrets before deploying.

## Deploy
```
cd stacks/health
mkdir -p /nfs/vm_shares/herta/apps/wger/{postgres,media,static}
docker compose -f health-stack.yml --env-file .env up -d
```
Access: http://<host>:8002

## Reverse proxy (optional)
- Add a Proxy Host in NPM pointing to `wger:8000`, enable SSL and websockets.

## Data locations
- Postgres: `/nfs/vm_shares/herta/apps/wger/postgres`
- Media: `/nfs/vm_shares/herta/apps/wger/media`
- Static: `/nfs/vm_shares/herta/apps/wger/static`

## Updates
```
docker compose -f health-stack.yml --env-file .env pull
docker compose -f health-stack.yml --env-file .env up -d
docker image prune -f
```

## Notes
- Admin user is created from `WGER_ADMIN_*` on first startup.
- Set `WGER_ALLOWED_HOSTS` to your domain when using HTTPS/reverse proxy.
- If you change DB creds later, update both `.env` and Postgres passwords.

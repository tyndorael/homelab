# Finance Stack (Ghostfolio)

Docker Compose stack for Ghostfolio (open-source wealth/portfolio tracker).

## Prereqs
- Docker + Docker Compose
- External network `nginx-proxy-manager` already created (from infrastructure stack)
- Storage path for Postgres (defaults to `/nfs/vm_shares/herta/apps/ghostfolio`)

## Configure
Create a `.env` in this folder (change all `change-me` secrets):

```env
TZ=UTC
GHOSTFOLIO_DB_NAME=ghostfolio
GHOSTFOLIO_DB_USER=ghostfolio
GHOSTFOLIO_DB_PASSWORD=change-me
GHOSTFOLIO_JWT_SECRET=change-me
GHOSTFOLIO_JWT_EXPIRES_IN=12h
GHOSTFOLIO_URL=https://ghostfolio.example.com
```

## Deploy
```
cd stacks/finance
mkdir -p /nfs/vm_shares/herta/apps/ghostfolio/postgres
docker compose -f finance-stack.yml --env-file .env up -d
```
Access: http://<host>:3333 (or your proxied domain)

## Reverse proxy (optional)
- In NPM, create a Proxy Host to `ghostfolio:3333`, enable SSL and websockets.

## Data locations
- Postgres: `/nfs/vm_shares/herta/apps/ghostfolio/postgres`

## Updates
```
docker compose -f finance-stack.yml --env-file .env pull
docker compose -f finance-stack.yml --env-file .env up -d
docker image prune -f
```

## Notes
- Ghostfolio credentials are set in the web UI after first launch (sign-up flow).
- `GHOSTFOLIO_URL` should match the public URL when using a reverse proxy.
- Database password and JWT secret must be strong; rotate if exposed.

.PHONY: network core-up core-down media-up media-down pull logs-core logs-media ps

CORE_DIR  := stacks/core
MEDIA_DIR := stacks/media

network:
	docker network create homelab 2>/dev/null || true

core-up: network
	docker compose -f $(CORE_DIR)/docker-compose.yml --env-file $(CORE_DIR)/.env up -d

core-down:
	docker compose -f $(CORE_DIR)/docker-compose.yml --env-file $(CORE_DIR)/.env down

media-up: network
	docker compose -f $(MEDIA_DIR)/docker-compose.yml --env-file $(MEDIA_DIR)/.env up -d

media-down:
	docker compose -f $(MEDIA_DIR)/docker-compose.yml --env-file $(MEDIA_DIR)/.env down

pull:
	docker compose -f $(CORE_DIR)/docker-compose.yml pull
	docker compose -f $(MEDIA_DIR)/docker-compose.yml pull

logs-core:
	docker compose -f $(CORE_DIR)/docker-compose.yml --env-file $(CORE_DIR)/.env logs -f

logs-media:
	docker compose -f $(MEDIA_DIR)/docker-compose.yml --env-file $(MEDIA_DIR)/.env logs -f

ps:
	docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

.PHONY: network core-up core-down media-up media-down tools-up tools-down ai-up ai-down pull logs-core logs-media logs-tools logs-ai ps

CORE_DIR  := stacks/core
MEDIA_DIR := stacks/media
TOOLS_DIR := stacks/tools
AI_DIR    := stacks/ai

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

tools-up: network
	docker compose -f $(TOOLS_DIR)/docker-compose.yml --env-file $(TOOLS_DIR)/.env up -d

tools-down:
	docker compose -f $(TOOLS_DIR)/docker-compose.yml --env-file $(TOOLS_DIR)/.env down

ai-up: network
	docker compose -f $(AI_DIR)/docker-compose.yml --env-file $(AI_DIR)/.env up -d

ai-down:
	docker compose -f $(AI_DIR)/docker-compose.yml --env-file $(AI_DIR)/.env down

pull:
	docker compose -f $(CORE_DIR)/docker-compose.yml pull
	docker compose -f $(MEDIA_DIR)/docker-compose.yml pull
	docker compose -f $(TOOLS_DIR)/docker-compose.yml pull
	docker compose -f $(AI_DIR)/docker-compose.yml pull

logs-core:
	docker compose -f $(CORE_DIR)/docker-compose.yml --env-file $(CORE_DIR)/.env logs -f

logs-media:
	docker compose -f $(MEDIA_DIR)/docker-compose.yml --env-file $(MEDIA_DIR)/.env logs -f

logs-tools:
	docker compose -f $(TOOLS_DIR)/docker-compose.yml --env-file $(TOOLS_DIR)/.env logs -f

logs-ai:
	docker compose -f $(AI_DIR)/docker-compose.yml --env-file $(AI_DIR)/.env logs -f

ps:
	docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

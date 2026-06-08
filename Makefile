.PHONY: network core-up core-down media-up media-down tools-up tools-down ai-up ai-down remote-up remote-down diagrams-up diagrams-down cockpit-install pull logs-core logs-media logs-tools logs-ai logs-remote logs-diagrams ps

CORE_DIR     := stacks/core
MEDIA_DIR    := stacks/media
TOOLS_DIR    := stacks/tools
AI_DIR       := stacks/ai
REMOTE_DIR   := stacks/remote
DIAGRAMS_DIR := stacks/diagrams

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

remote-up: network
	docker compose -f $(REMOTE_DIR)/docker-compose.yml --env-file $(REMOTE_DIR)/.env up -d

remote-down:
	docker compose -f $(REMOTE_DIR)/docker-compose.yml --env-file $(REMOTE_DIR)/.env down

diagrams-up: network
	docker compose -f $(DIAGRAMS_DIR)/docker-compose.yml --env-file $(DIAGRAMS_DIR)/.env up -d

diagrams-down:
	docker compose -f $(DIAGRAMS_DIR)/docker-compose.yml --env-file $(DIAGRAMS_DIR)/.env down

# Cockpit manages the host directly (systemd, packages, host-user login),
# so it is installed on the host rather than run as a container.
cockpit-install:
	sudo apt update && sudo apt install -y cockpit cockpit-networkmanager cockpit-storaged cockpit-packagekit
	sudo systemctl enable --now cockpit.socket
	@echo "Cockpit is up on https://$$(hostname -I | awk '{print $$1}'):9090"

pull:
	docker compose -f $(CORE_DIR)/docker-compose.yml pull
	docker compose -f $(MEDIA_DIR)/docker-compose.yml pull
	docker compose -f $(TOOLS_DIR)/docker-compose.yml pull
	docker compose -f $(AI_DIR)/docker-compose.yml pull
	docker compose -f $(REMOTE_DIR)/docker-compose.yml pull
	docker compose -f $(DIAGRAMS_DIR)/docker-compose.yml pull

logs-core:
	docker compose -f $(CORE_DIR)/docker-compose.yml --env-file $(CORE_DIR)/.env logs -f

logs-media:
	docker compose -f $(MEDIA_DIR)/docker-compose.yml --env-file $(MEDIA_DIR)/.env logs -f

logs-tools:
	docker compose -f $(TOOLS_DIR)/docker-compose.yml --env-file $(TOOLS_DIR)/.env logs -f

logs-ai:
	docker compose -f $(AI_DIR)/docker-compose.yml --env-file $(AI_DIR)/.env logs -f

logs-remote:
	docker compose -f $(REMOTE_DIR)/docker-compose.yml --env-file $(REMOTE_DIR)/.env logs -f

logs-diagrams:
	docker compose -f $(DIAGRAMS_DIR)/docker-compose.yml --env-file $(DIAGRAMS_DIR)/.env logs -f

ps:
	docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

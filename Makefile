# Usage: make <target> HOST=<raspberry-pi|unraid|mac-mini> STACK=<stack folder>
#   make up HOST=raspberry-pi STACK=portainer
#   make validate            # check every compose.yaml in the repo

HOST  ?=
STACK ?=
DIR   := hosts/$(HOST)/$(STACK)
COMPOSE = docker compose --project-directory $(DIR) -f $(DIR)/compose.yaml

.PHONY: help up down restart pull update logs ps config network validate check-args

help:
	@grep -E '^#' Makefile | sed 's/^# \{0,1\}//'
	@echo "Targets: up down restart pull update logs ps config network validate"

check-args:
	@test -n "$(HOST)" -a -n "$(STACK)" || { echo "HOST and STACK are required"; exit 1; }
	@test -f $(DIR)/compose.yaml || { echo "$(DIR)/compose.yaml not found"; exit 1; }
	@test -f $(DIR)/.env -o ! -f $(DIR)/.env.example || { echo "Missing $(DIR)/.env (copy from .env.example)"; exit 1; }

up: check-args
	$(COMPOSE) up -d --remove-orphans

down: check-args
	$(COMPOSE) down

restart: check-args
	$(COMPOSE) restart

pull: check-args
	$(COMPOSE) pull

update: pull up   ## pull new images, recreate changed containers
	docker image prune -f

logs: check-args
	$(COMPOSE) logs -f --tail=100

ps: check-args
	$(COMPOSE) ps

config: check-args
	$(COMPOSE) config

network:   ## shared reverse-proxy network on the Pi
	docker network inspect proxy >/dev/null 2>&1 || docker network create proxy

validate:
	@set -e; for f in $$(find hosts templates -name compose.yaml | sort); do \
		d=$$(dirname $$f); env=$$d/.env; [ -f $$env ] || env=$$d/.env.example; \
		ef=""; [ -f $$env ] && ef="--env-file $$env"; \
		docker compose --project-directory $$d -f $$f $$ef config -q && echo "ok  $$f"; \
	done

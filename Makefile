.DEFAULT_GOAL := start
.PHONY: help start start-build stop stop-volumes status shell shell-list

# make help
# make shell service=cryptomation-frontend
# make shell service=nginx shell_bin=sh
service   ?= cryptomation-frontend
shell_bin ?= bash

help: ## Show available make commands
	@awk 'BEGIN { FS = ":.*?## "; printf "Usage:\n  make <target>\n\nTargets:\n" } \
	  /^[a-zA-Z0-9_-]+:.*?## / { printf "  %-16s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf '\nVariables:\n'
	@printf '  %-16s %s\n' 'service' 'Container for make shell (default: $(service))'
	@printf '  %-16s %s\n' 'shell_bin' 'Shell binary (default: $(shell_bin))'
	@printf '\nExamples:\n'
	@printf '  make shell service=cryptomation-monolith\n'
	@printf '  make shell service=nginx shell_bin=sh\n'

start: ## Start infra and all project containers
	./scripts/start.sh

start-build: ## Start and rebuild images
	./scripts/start.sh --build

stop: ## Stop the stack
	./scripts/stop.sh

stop-volumes: ## Stop the stack and remove volumes
	./scripts/stop.sh --volumes

status: ## Show container status
	./scripts/status.sh

shell: ## Open a shell in a running service (see service / shell_bin)
	./scripts/shell.sh $(service) $(shell_bin)

shell-list: ## List running services you can join with make shell
	./scripts/shell-list.sh

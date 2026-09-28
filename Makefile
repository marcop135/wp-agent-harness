# Thin wrapper over ./bin. Every target is one script; nothing is duplicated.

.DEFAULT_GOAL := help
.PHONY: help setup start stop restart reset status logs test test-fast connect disconnect wp shell

help: ## Show this help
	@grep -hE '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "} {printf "  \033[1m%-12s\033[0m %s\n", $$1, $$2}'

setup: ## Build, start and provision the whole environment
	@./bin/setup

start: ## Start the Docker services
	@./bin/start

stop: ## Stop the Docker services, keeping all data
	@./bin/stop

restart: stop start ## Stop then start

reset: ## DESTRUCTIVE: destroy volumes and rebuild from scratch
	@./bin/reset

status: ## Report container, WordPress, ability and MCP health
	@./bin/status

logs: ## Show Docker logs
	@./bin/logs

test: ## Run the full test suite, Claude Code layer included
	@./bin/test

test-fast: ## Run layers 1-3 only (no model turns)
	@./bin/test --skip-claude

connect: ## Register the MCP server with Claude Code
	@./bin/connect

disconnect: ## Remove the MCP server from Claude Code
	@./bin/connect --remove

wp: ## Run WP-CLI in the container: make wp ARGS="plugin list"
	@./bin/wp $(ARGS)

shell: ## Open a shell in the WordPress container
	@docker compose exec wordpress bash

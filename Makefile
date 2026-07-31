.PHONY: start stop start-build stop-volumes status shell shell-list

# make shell
# make shell service=cryptomation-frontend
# make shell service=nginx shell_bin=sh
# make shell-list
service   ?= cryptomation-frontend
shell_bin ?= bash

start:
	./scripts/start.sh

start-build:
	./scripts/start.sh --build

stop:
	./scripts/stop.sh

stop-volumes:
	./scripts/stop.sh --volumes

status:
	./scripts/status.sh

shell:
	./scripts/shell.sh $(service) $(shell_bin)

shell-list:
	./scripts/shell-list.sh

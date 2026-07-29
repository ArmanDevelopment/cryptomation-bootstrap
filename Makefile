.PHONY: start stop start-build stop-volumes status

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

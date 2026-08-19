#!/usr/bin/env bash
# Bootstrap setup after containers are up.
# Invoked by scripts/start.sh (also runs each projects/*/scripts/after-start.sh).
#
# Available env: ROOT, BUILD_FLAG
set -euo pipefail

: "${ROOT:?ROOT must be set by start.sh}"

echo "[nginx] Reloading..."
# Drop leftover vhost files from the old per-project server-block layout
# (conf.d is not a volume; a reused container can keep stale *.conf).
docker exec cryptomation_nginx sh -c '
  for f in /etc/nginx/conf.d/*.conf; do
    [ -f "$f" ] || continue
    [ "$(basename "$f")" = default.conf ] || rm -f "$f"
  done
'
docker exec cryptomation_nginx nginx -s reload

# shellcheck disable=SC1091
set -a
source "$ROOT/.env"
set +a

PORT="${NGINX_HTTP_PORT:-80}"
HOST="${NGINX_SERVER_NAME:-cryptomation.local}"
if [[ "$PORT" == "80" ]]; then
  URL="http://${HOST}/"
else
  URL="http://${HOST}:${PORT}/"
fi

echo ""
echo "All services up."
echo ""
echo "1) Map the domain (once) — requires sudo:"
echo "     grep -q '${HOST}' /etc/hosts || echo '127.0.0.1  ${HOST}' | sudo tee -a /etc/hosts"
echo "2) App:   $URL"
echo "   API:   ${URL}api/ping"
MAIL_UI_PORT="${MAILPIT_UI_PORT:-8025}"
echo "   Mail:  http://127.0.0.1:${MAIL_UI_PORT}"
echo "   (NGINX_HTTP_PORT=${PORT}, NGINX_SERVER_NAME=${HOST}, MAILPIT_UI_PORT=${MAIL_UI_PORT})"

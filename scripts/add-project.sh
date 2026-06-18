#!/usr/bin/env bash
# Scaffold a new project entry in the bootstrap.
# Usage: ./scripts/add-project.sh <project-name> <local-domain>
# Example: ./scripts/add-project.sh cryptomation-api api.cryptomation.local
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAME="${1:-}"
DOMAIN="${2:-}"

if [[ -z "$NAME" || -z "$DOMAIN" ]]; then
  echo "Usage: $0 <project-name> <local-domain>"
  exit 1
fi

DEST="$ROOT/projects/$NAME"
TMPL="$ROOT/projects/cryptomation-frontend"

if [[ -d "$DEST" ]]; then
  echo "ERROR: $DEST already exists."
  exit 1
fi

echo "Scaffolding $NAME..."
cp -r "$TMPL" "$DEST"
rm -f "$DEST/.env"

# Generate nginx conf.d entry from template
sed \
  -e "s/cryptomation-frontend/$NAME/g" \
  -e "s/cryptomation\.local/$DOMAIN/g" \
  "$TMPL/nginx/default.conf" \
  > "$ROOT/nginx/conf.d/${NAME}.conf"

echo ""
echo "Done. Next steps:"
echo "  1. Edit projects/$NAME/docker-compose.yml — update context, service name"
echo "  2. Edit nginx/conf.d/${NAME}.conf if upstream/domain differs"
echo "  3. cp projects/$NAME/.env.example projects/$NAME/.env && edit it"
echo "  4. Add to /etc/hosts:  127.0.0.1  $DOMAIN"
echo "  5. docker compose -f projects/$NAME/docker-compose.yml up -d"
echo "     docker exec cryptomation_nginx nginx -s reload"

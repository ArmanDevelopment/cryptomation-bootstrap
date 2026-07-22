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

# Generate nginx template (literal domain for new projects; frontend uses NGINX_SERVER_NAME)
sed \
  -e "s/cryptomation-frontend/$NAME/g" \
  -e "s/\${NGINX_SERVER_NAME}/$DOMAIN/g" \
  "$TMPL/nginx/default.conf" \
  > "$ROOT/nginx/templates/${NAME}.conf.template"

echo ""
echo "Done. Next steps:"
echo "  1. Edit projects/$NAME/docker-compose.yml — update context, service name"
echo "     (keep include of ../../compose.infra.yml)"
echo "  2. Add include in docker-compose.yml:"
echo "       - path: projects/$NAME/docker-compose.yml"
echo "  3. Edit nginx/templates/${NAME}.conf.template if upstream differs"
echo "  4. cp projects/$NAME/.env.example projects/$NAME/.env && edit it"
echo "  5. Add to /etc/hosts:  127.0.0.1  $DOMAIN"
echo "  6. ./scripts/start.sh"

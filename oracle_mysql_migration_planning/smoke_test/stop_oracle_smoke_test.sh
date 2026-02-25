#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.oracle-free.yml"
PURGE_DATA="${PURGE_DATA:-0}"

if [[ "$PURGE_DATA" == "1" ]]; then
  echo "[INFO] Stopping container and removing volumes (PURGE_DATA=1)..."
  docker compose -f "$COMPOSE_FILE" down -v
else
  echo "[INFO] Stopping container (data volume preserved)..."
  docker compose -f "$COMPOSE_FILE" down
fi


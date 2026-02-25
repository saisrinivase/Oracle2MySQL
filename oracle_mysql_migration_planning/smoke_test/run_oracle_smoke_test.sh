#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.oracle-free.yml"
SQL_DIR="$SCRIPT_DIR/../sql"
STATIC_CHECK_SCRIPT="$SQL_DIR/99_preflight_static_check.sh"
REPORT_ROOT_HOST="$SCRIPT_DIR/reports"

ORACLE_PASSWORD="${ORACLE_PASSWORD:-oracle123}"
APP_USER="${APP_USER:-OMM_APP}"
APP_USER_PASSWORD="${APP_USER_PASSWORD:-omm_app_pwd}"
ORACLE_HOST_PORT="${ORACLE_HOST_PORT:-15211}"
OWNER_FILTER="${OWNER_FILTER:-OMM_%}"
RESET_DB="${RESET_DB:-0}"

RUN_TS="$(date '+%Y%m%d_%H%M%S')"
REPORT_HOST_DIR="$REPORT_ROOT_HOST/$RUN_TS"
REPORT_CONTAINER_DIR="/workspace/reports/$RUN_TS"

log() { printf '[INFO] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; exit 1; }

oracle_sql_system() {
  local sql_text="$1"
  docker compose -f "$COMPOSE_FILE" exec -T oracle bash -lc \
    "sqlplus -s system/${ORACLE_PASSWORD}@//localhost:1521/FREEPDB1" <<< "$sql_text"
}

oracle_sql_app() {
  local sql_text="$1"
  docker compose -f "$COMPOSE_FILE" exec -T oracle bash -lc \
    "sqlplus -s ${APP_USER}/${APP_USER_PASSWORD}@//localhost:1521/FREEPDB1" <<< "$sql_text"
}

[[ -x "$STATIC_CHECK_SCRIPT" ]] || fail "Missing static check script: $STATIC_CHECK_SCRIPT"
"$STATIC_CHECK_SCRIPT"

mkdir -p "$REPORT_HOST_DIR"

export ORACLE_PASSWORD APP_USER APP_USER_PASSWORD ORACLE_HOST_PORT

if [[ "$RESET_DB" == "1" ]]; then
  log "RESET_DB=1 set. Recreating Oracle container and data volume."
  docker compose -f "$COMPOSE_FILE" down -v
fi

log "Starting Oracle Free container on host port $ORACLE_HOST_PORT ..."
docker compose -f "$COMPOSE_FILE" up -d oracle

log "Waiting for Oracle to become ready ..."
probe_sql=$'set heading off feedback off verify off pages 0\nselect 1 from dual;\nexit;\n'
max_attempts=120
attempt=1
ready=0
while [[ $attempt -le $max_attempts ]]; do
  if oracle_sql_system "$probe_sql" 2>/dev/null | tr -d '\r' | awk 'NF {print $0}' | grep -q '^1$'; then
    ready=1
    break
  fi
  if (( attempt % 10 == 0 )); then
    log "Still waiting for Oracle (attempt $attempt/$max_attempts)..."
  fi
  sleep 5
  attempt=$((attempt + 1))
done

[[ $ready -eq 1 ]] || {
  docker compose -f "$COMPOSE_FILE" logs --tail=120 oracle || true
  fail "Oracle did not become ready in time."
}

log "Oracle is ready. Seeding source objects ..."
seed_sql=$'whenever sqlerror exit sql.sqlcode\n@/workspace/seed/01_seed_oracle_source.sql\nexit;\n'
oracle_sql_app "$seed_sql" >/dev/null

log "Running stage 1/2/3 toolkit with OWNER_FILTER=$OWNER_FILTER ..."
docker compose -f "$COMPOSE_FILE" exec -T oracle bash -lc \
  "cd /workspace/sql && sqlplus -s ${APP_USER}/${APP_USER_PASSWORD}@//localhost:1521/FREEPDB1 @00_run_stage_1_2_3.sql '${OWNER_FILTER}' '${REPORT_CONTAINER_DIR}'" \
  >/dev/null

required_pages=(
  "index.html"
  "discover.html"
  "assess.html"
  "plan.html"
  "discover_objects.html"
  "assess_findings.html"
  "plan_actions.html"
  "source_target.html"
  "target_blueprint.html"
  "dependency_graph.html"
  "schema_complexity.html"
)

for page in "${required_pages[@]}"; do
  [[ -f "$REPORT_HOST_DIR/$page" ]] || fail "Expected report page missing: $REPORT_HOST_DIR/$page"
done

log "Smoke test completed successfully."
log "Oracle endpoint: localhost:$ORACLE_HOST_PORT/FREEPDB1"
log "Main report: $REPORT_HOST_DIR/index.html"
log "All reports folder: $REPORT_HOST_DIR"
log "To stop container: $SCRIPT_DIR/stop_oracle_smoke_test.sh"

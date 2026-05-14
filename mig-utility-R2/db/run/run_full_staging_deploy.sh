#!/usr/bin/env bash
# Full staging rollout: SYS creates schema -> staging user runs 01/02/03 DDL -> deploy packages.
# Logs: db/logs/sql/*.LOG (cwd for sqlplus is db/run).
#
# Requires:
#   - sqlplus on PATH (Oracle Instant Client or full client)
#   - env/.env with TARGET_DB_HOST, TARGET_DB_PORT, TARGET_DB_SERVICE_NAME, TARGET_DB_USER, TARGET_DB_PASSWORD
#
# Sysdba (step 1) connect — pick one:
#   export SYSDBA_SQLPLUS_CONNECT='sys/your_sys_password@10.0.9.27:1521/pdb1 as sysdba'
#   ./run_full_staging_deploy.sh
#
# Or pass the same string as the first argument (overrides the env var):
#   ./run_full_staging_deploy.sh 'sys/...@10.0.9.27:1521/pdb1 as sysdba'
#
# If TARGET_DB_USER already exists, schema creation fails (ORA-01920). Drop the user first
# for a clean retest, or run only DDL + packages with run_ddl_tables.sh and deploy_packages.sh.

set -euo pipefail
RUN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$RUN_DIR/../.." && pwd)"

if [[ ! -f "$ROOT/env/.env" ]]; then
  echo "Missing $ROOT/env/.env" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
source "$ROOT/env/.env"
set +a

: "${TARGET_DB_HOST:?TARGET_DB_HOST missing in env/.env}"
: "${TARGET_DB_PORT:?TARGET_DB_PORT missing in env/.env}"
: "${TARGET_DB_SERVICE_NAME:?TARGET_DB_SERVICE_NAME missing in env/.env}"
: "${TARGET_DB_USER:?TARGET_DB_USER missing in env/.env}"
: "${TARGET_DB_PASSWORD:?TARGET_DB_PASSWORD missing in env/.env}"

SYS_CONNECT="${SYSDBA_SQLPLUS_CONNECT:-${1:-}}"
if [[ -z "$SYS_CONNECT" ]]; then
  echo "Provide SYSDBA connect: export SYSDBA_SQLPLUS_CONNECT='sys/... as sysdba' or pass it as arg 1." >&2
  exit 1
fi

STAGING_CONNECT="${TARGET_DB_USER}/${TARGET_DB_PASSWORD}@${TARGET_DB_HOST}:${TARGET_DB_PORT}/${TARGET_DB_SERVICE_NAME}"

if ! command -v sqlplus >/dev/null 2>&1; then
  echo "sqlplus not found on PATH. Install Oracle SQL*Plus or Instant Client + sqlplus." >&2
  exit 1
fi

echo "== 1/3 Create staging user (SYS) =="
"$RUN_DIR/create_staging_schema.sh" "$SYS_CONNECT"

echo "== 2/3 Create tables (staging schema) =="
"$RUN_DIR/run_ddl_tables.sh" "$STAGING_CONNECT"

echo "== 3/3 Deploy packages (staging schema) =="
"$RUN_DIR/deploy_packages.sh" "$STAGING_CONNECT"

echo "Done. Spool files: $ROOT/db/logs/sql/"

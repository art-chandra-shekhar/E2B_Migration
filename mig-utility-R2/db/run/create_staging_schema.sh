#!/usr/bin/env bash
# Create staging Oracle user using TARGET_DB_USER and TARGET_DB_PASSWORD from env/.env.
# Usage: ./create_staging_schema.sh [sqlplus_connect]
# Example: ./create_staging_schema.sh 'sys/oracle@10.0.9.27:1521/pdb1 as sysdba'
# Default connect: / as sysdba (local BEQ).

set -euo pipefail
RUN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$(cd "$RUN_DIR/../.." && pwd)/env/.env"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ENV_FILE"
  set +a
else
  echo "Missing env file: $ENV_FILE" >&2
  exit 1
fi

: "${TARGET_DB_USER:?TARGET_DB_USER is not set (expected in env/.env)}"
: "${TARGET_DB_PASSWORD:?TARGET_DB_PASSWORD is not set (expected in env/.env)}"

CONNECT="${1:-/ as sysdba}"

mkdir -p "$RUN_DIR/../logs/sql"
cd "$RUN_DIR"
exec sqlplus -L "$CONNECT" @"$RUN_DIR/create_staging_schema.sql" "$TARGET_DB_USER" "$TARGET_DB_PASSWORD"

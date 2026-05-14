#!/usr/bin/env bash
# Run 01/02/03 table DDL in order; spool files go to db/logs/sql/ (see each .sql header).
# Usage: ./run_ddl_tables.sh <sqlplus_connect>
# Example: ./run_ddl_tables.sh 'mg_owner/secret@10.0.9.27:1521/pdb1'

set -euo pipefail
RUN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DDL_DIR="$RUN_DIR/../ddl"
CONNECT="${1:?Usage: $0 <sqlplus_connect>}"

mkdir -p "$RUN_DIR/../logs/sql"
cd "$RUN_DIR"
for f in 01_create_config_tables.sql 02_create_target_tables.sql 03_create_source_tables.sql; do
  sqlplus -L "$CONNECT" @"$DDL_DIR/$f"
done

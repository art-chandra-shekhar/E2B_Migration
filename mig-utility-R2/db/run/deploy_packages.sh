#!/usr/bin/env bash
# Deploy packages via deploy_packages.sql (spool under db/logs/sql/).
# Usage: ./deploy_packages.sh <sqlplus_connect>
# Example: ./deploy_packages.sh 'mg_owner/secret@10.0.9.27:1521/pdb1'

set -euo pipefail
RUN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONNECT="${1:?Usage: $0 <sqlplus_connect>}"

mkdir -p "$RUN_DIR/../logs/sql"
cd "$RUN_DIR"
exec sqlplus -L "$CONNECT" @"$RUN_DIR/deploy_packages.sql"

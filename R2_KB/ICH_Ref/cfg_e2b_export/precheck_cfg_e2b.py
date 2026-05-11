#!/usr/bin/env python3
"""
Precheck script for CFG_E2B export.

Checks:
1) Oracle connection
2) Filtered row count using exact profile match
"""

import argparse
import oracledb


def main() -> None:
    parser = argparse.ArgumentParser(description="Precheck CFG_E2B connection and row count")
    parser.add_argument("--host", required=True, help="Oracle host")
    parser.add_argument("--port", type=int, default=1521, help="Oracle port")
    parser.add_argument("--service", required=True, help="Oracle service name")
    parser.add_argument("--user", required=True, help="Oracle username")
    parser.add_argument("--password", required=True, help="Oracle password")
    parser.add_argument("--owner", default="ESM_OWNER", help="Schema owner")
    parser.add_argument("--table", default="CFG_E2B", help="Table name")
    parser.add_argument(
        "--profile",
        default="ICH-ICSR V2.1 MESSAGE TEMPLATE",
        help="Exact PROFILE filter value",
    )
    args = parser.parse_args()

    dsn = f"{args.host}:{args.port}/{args.service}"
    conn = oracledb.connect(user=args.user, password=args.password, dsn=dsn)
    cur = conn.cursor()

    sql = f"SELECT COUNT(1) FROM {args.owner}.{args.table} WHERE profile = :p"
    cur.execute(sql, p=args.profile)
    count = cur.fetchone()[0]

    print("connection_status=SUCCESS")
    print(f"profile_filter={args.profile}")
    print(f"filtered_count={count}")

    cur.close()
    conn.close()


if __name__ == "__main__":
    main()

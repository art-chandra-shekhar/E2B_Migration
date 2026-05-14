#!/usr/bin/env python3
"""Load E2B(R2) XML files from input/e2b_r2_xml into SRC tables."""

from __future__ import annotations

import argparse
import re
from collections import defaultdict
from pathlib import Path
from typing import Any
import xml.etree.ElementTree as ET

# Keys must match CREATE TABLE names in the DDL file (default: 03_create_source_tables.sql).
TABLE_CONTEXT = {
    "S_SAFETYREPORT": (None, "safetyreport"),
    "S_PRIMARYSOURCE": ("safetyreport", "primarysource"),
    "S_SENDER": ("safetyreport", "sender"),
    "S_RECEIVER": ("safetyreport", "receiver"),
    "S_PATIENT": ("safetyreport", "patient"),
    "S_MEDICALHISTORYEPISODE": ("patient", "medicalhistoryepisode"),
    "S_REACTION": ("patient", "reaction"),
    "S_TEST": ("patient", "test"),
    "S_DRUG": ("patient", "drug"),
    "S_ACTIVESUBSTANCE": ("drug", "activesubstance"),
    "S_DRUGREACTIONRELATEDNESS": ("drug", "drugreactionrelatedness"),
    "S_SUMMARY": ("patient", "summary"),
    "S_REPORTDUPLICATE": ("safetyreport", "reportduplicate"),
    "S_PATIENTDEATH": ("patient", "patientdeath"),
    "S_PATIENTDEATHCAUSE": ("patientdeath", "patientdeathcause"),
    "S_LINKEDREPORT": ("safetyreport", "linkedreport"),
    "S_PATIENTPASTDRUGTHERAPY": ("patient", "patientpastdrugtherapy"),
    "S_PATIENTAUTOPSY": ("patientdeath", "patientautopsy"),
}

def parse_env(env_path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for line in env_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip()
    return values


def parse_table_columns(ddl_path: Path) -> dict[str, list[str]]:
    ddl = ddl_path.read_text(encoding="utf-8")
    matches = re.findall(
        r"CREATE\s+TABLE\s+([A-Z_]+)\s*\((.*?)\);",
        ddl,
        flags=re.IGNORECASE | re.DOTALL,
    )
    table_columns: dict[str, list[str]] = {}
    for table_name, table_body in matches:
        columns: list[str] = []
        for raw_line in table_body.splitlines():
            line = raw_line.strip().rstrip(",")
            if not line or line.upper().startswith("PRIMARY KEY"):
                continue
            col_name = line.split()[0].upper()
            columns.append(col_name)
        table_columns[table_name.upper()] = columns
    return table_columns


def child_text(node: ET.Element, tag: str) -> str | None:
    child = node.find(tag)
    if child is None or child.text is None:
        return None
    value = child.text.strip()
    return value if value else None


def build_row(columns: list[str], node: ET.Element, keys: dict[str, Any]) -> dict[str, Any]:
    row: dict[str, Any] = {}
    for col in columns:
        if col in keys:
            row[col] = str(keys[col]) if keys[col] is not None else None
            continue
        row[col] = child_text(node, col.lower())
    return row


def parse_xml_rows(xml_file: Path, table_columns: dict[str, list[str]], ichicsr_seq: int) -> dict[str, list[dict[str, Any]]]:
    tree = ET.parse(xml_file)
    root = tree.getroot()
    rows: dict[str, list[dict[str, Any]]] = defaultdict(list)

    for safety_idx, safety in enumerate(root.findall("safetyreport"), start=1):
        safety_keys = {"ICHICSR_SEQ": ichicsr_seq, "SAFETYREPORT_SEQ": safety_idx}
        rows["S_SAFETYREPORT"].append(build_row(table_columns["S_SAFETYREPORT"], safety, safety_keys))

        for table in ("S_PRIMARYSOURCE", "S_SENDER", "S_RECEIVER", "S_REPORTDUPLICATE", "S_LINKEDREPORT"):
            _, tag = TABLE_CONTEXT[table]
            for idx, node in enumerate(safety.findall(tag), start=1):
                keys = {**safety_keys, f"{table}_SEQ": idx}
                rows[table].append(build_row(table_columns[table], node, keys))

        for patient_idx, patient in enumerate(safety.findall("patient"), start=1):
            patient_keys = {**safety_keys, "PATIENT_SEQ": patient_idx}
            rows["S_PATIENT"].append(build_row(table_columns["S_PATIENT"], patient, patient_keys))

            for table in ("S_MEDICALHISTORYEPISODE", "S_REACTION", "S_TEST", "S_SUMMARY", "S_PATIENTPASTDRUGTHERAPY"):
                _, tag = TABLE_CONTEXT[table]
                for idx, node in enumerate(patient.findall(tag), start=1):
                    keys = {**patient_keys, f"{table}_SEQ": idx}
                    rows[table].append(build_row(table_columns[table], node, keys))

            for death_idx, death in enumerate(patient.findall("patientdeath"), start=1):
                death_keys = {**patient_keys, "PATIENTDEATH_SEQ": death_idx}
                rows["S_PATIENTDEATH"].append(build_row(table_columns["S_PATIENTDEATH"], death, death_keys))

                for table in ("S_PATIENTDEATHCAUSE", "S_PATIENTAUTOPSY"):
                    _, tag = TABLE_CONTEXT[table]
                    for idx, node in enumerate(death.findall(tag), start=1):
                        keys = {**death_keys, f"{table}_SEQ": idx}
                        rows[table].append(build_row(table_columns[table], node, keys))

            for drug_idx, drug in enumerate(patient.findall("drug"), start=1):
                drug_keys = {**patient_keys, "DRUG_SEQ": drug_idx}
                rows["S_DRUG"].append(build_row(table_columns["S_DRUG"], drug, drug_keys))

                for table in ("S_ACTIVESUBSTANCE", "S_DRUGREACTIONRELATEDNESS"):
                    _, tag = TABLE_CONTEXT[table]
                    for idx, node in enumerate(drug.findall(tag), start=1):
                        keys = {**drug_keys, f"{table}_SEQ": idx}
                        rows[table].append(build_row(table_columns[table], node, keys))

    return rows


def insert_rows(
    connection: Any,
    table_columns: dict[str, list[str]],
    rows_by_table: dict[str, list[dict[str, Any]]],
) -> None:
    with connection.cursor() as cursor:
        for table, columns in table_columns.items():
            rows = rows_by_table.get(table, [])
            if not rows:
                continue
            bind_cols = ", ".join(columns)
            bind_vals = ", ".join(f":{i + 1}" for i in range(len(columns)))
            sql = f"INSERT INTO {table} ({bind_cols}) VALUES ({bind_vals})"
            data = [tuple(row.get(col) for col in columns) for row in rows]
            cursor.executemany(sql, data)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Load E2B(R2) XML data into SRC tables.")
    parser.add_argument(
        "--input-dir",
        default="input/e2b_r2_xml",
        help="Folder that contains .XML files.",
    )
    parser.add_argument(
        "--ddl-file",
        default="db/ddl/03_create_source_tables.sql",
        help="DDL file used to infer E2B(R2) SRC table columns.",
    )
    parser.add_argument(
        "--env-file",
        default="env/.env",
        help="Env file with TARGET_DB_* keys.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Parse XML and print row counts without inserting into DB.",
    )
    return parser


def main() -> int:
    args = build_parser().parse_args()

    base_dir = Path(__file__).resolve().parent
    input_dir = (base_dir / args.input_dir).resolve()
    ddl_file = (base_dir / args.ddl_file).resolve()
    env_file = (base_dir / args.env_file).resolve()

    if not input_dir.exists():
        raise FileNotFoundError(f"Input directory not found: {input_dir}")
    if not ddl_file.exists():
        raise FileNotFoundError(f"DDL file not found: {ddl_file}")
    if not env_file.exists():
        raise FileNotFoundError(f"Env file not found: {env_file}")

    xml_files = sorted(input_dir.glob("*.XML")) + sorted(input_dir.glob("*.xml"))
    if not xml_files:
        raise FileNotFoundError(f"No XML files found in {input_dir}")

    table_columns = parse_table_columns(ddl_file)
    all_rows: dict[str, list[dict[str, Any]]] = defaultdict(list)

    for ichicsr_seq, xml_file in enumerate(xml_files, start=1):
        file_rows = parse_xml_rows(xml_file, table_columns, ichicsr_seq)
        for table, rows in file_rows.items():
            all_rows[table].extend(rows)

    print("Rows prepared from XML:")
    for table in sorted(table_columns):
        print(f"  {table}: {len(all_rows.get(table, []))}")

    if args.dry_run:
        print("Dry run completed. No data inserted.")
        return 0

    import oracledb

    env_values = parse_env(env_file)
    dsn = f"{env_values['TARGET_DB_HOST']}:{env_values['TARGET_DB_PORT']}/{env_values['TARGET_DB_SERVICE_NAME']}"
    with oracledb.connect(
        user=env_values["TARGET_DB_USER"],
        password=env_values["TARGET_DB_PASSWORD"],
        dsn=dsn,
    ) as conn:
        insert_rows(conn, table_columns, all_rows)
        conn.commit()

    print("Load completed successfully.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

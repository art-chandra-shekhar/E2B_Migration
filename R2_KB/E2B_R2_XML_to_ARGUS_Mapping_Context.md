# E2B R2 XML to ARGUS Mapping Context (Using CFG_E2B Export Artifacts)

## Purpose
This document captures the recommended process to derive XML-to-`ARGUS_APP` mapping logic for import migration using exported `CFG_E2B` artifacts.

`CFG_E2B` is the practical source of truth for Argus export mappings (ARGUS -> E2B R2 XML). For migration/import design, reverse engineer this logic into XML -> source staging -> `ARGUS_APP`.

## Primary Source Artifacts (CFG_E2B Export)
Use these files together:

- `src/entities/E2B_R2/ICH_Ref/cfg_e2b_export/CFG_E2B_non_clob_filtered.xlsx`
- `src/entities/E2B_R2/ICH_Ref/cfg_e2b_export/CFG_E2B_clob_manifest_filtered.xlsx`
- `src/entities/E2B_R2/ICH_Ref/cfg_e2b_export/clob_exports/*.txt`

Profile filter used for export:
- `PROFILE = 'ICH-ICSR V2.1 MESSAGE TEMPLATE'`

Rows exported with this filter:
- `262`

## Why CFG_E2B Export Artifacts Are Required
The SQL/procedure fields (`AE_SELECT_STMT`, `AE_USER_PROC`, `CHILD_ONLY_SQL`) are CLOB columns and may be truncated or blank in normal spreadsheet exports.

The export folder avoids this by:
- keeping non-CLOB metadata in Excel,
- storing each CLOB as a dedicated `.txt` file,
- linking rows to CLOB files via manifest.

## Key Mapping Fields (from Non-CLOB Excel)
From `CFG_E2B_non_clob_filtered.xlsx`:
- `DTD_ELEMENT`: XML tag/element name.
- `PARENT_ELEMENT`: parent XML tag in hierarchy.
- `AE_SELECT_STMT_ELEMENT_ASSOC`: which SQL element context the tag maps to.
- `AE_SELECT_STMT_COL_POSITION`: position of tag output in associated select statement.
- Additional useful metadata: `HIE_LEVEL`, `REPEATABLE`, `MANDATORY`, `DTD_TYPE`, `DATA_ELEMENT`.

## How to Resolve DTD Element -> AE_SELECT_STMT

1. Find target row in `CFG_E2B_non_clob_filtered.xlsx` using `DTD_ELEMENT`.
2. Open `CFG_E2B_clob_manifest_filtered.xlsx`.
3. Match row (recommended by `row_num`; alternatively by `DTD_ELEMENT` + `PROFILE`).
4. Read `AE_SELECT_STMT_file` from manifest.
5. Open that file in `clob_exports`.
6. Use full SQL text from that file for reverse engineering.

## Critical Inheritance Rule (Parent Fallback)
Some tags have no direct SQL file. In that case, resolve recursively through parent:

1. Start at row where `DTD_ELEMENT = <current_element>`.
2. If `AE_SELECT_STMT_file` exists, use it.
3. If missing, read `PARENT_ELEMENT`.
4. Move to row where `DTD_ELEMENT = PARENT_ELEMENT`.
5. Repeat until a SQL file is found or hierarchy ends.

Capture these derived fields in analysis output:
- `resolved_sql_source_element`
- `resolved_ae_select_stmt_file`
- `inheritance_depth`

This is mandatory for accurate extraction.

## Observed Resolution Statistics (CFG_E2B Export)
- Rows in profile scope: `262`
- Rows with `AE_SELECT_STMT` CLOB file: available via manifest + `clob_exports`
- CLOB types exported: `AE_SELECT_STMT`, `AE_USER_PROC`, `CHILD_ONLY_SQL`

## Major XML Block to Argus Source Table Families (Observed in CLOB SQL Files)

- `ICHICSRMESSAGEHEADER` -> `CFG_PROFILE`
- `PRIMARYSOURCE` -> `CASE_REPORTER_LIT_ALL`
- `SENDER`, `RECEIVER` -> `LM_REGULATORY_CONTACT`
- `PATIENT` -> `CASE_PAT_INFO`, `CASE_PREGNANCY`
- `MEDICALHISTORYEPISODE`, `PATIENTPASTDRUGTHERAPY` -> `CASE_PAT_HIST`
- `PATIENTDEATH` -> `CASE_DEATH`, `CASE_DEATH_DETAILS`
- `PARENT` -> `CASE_PARENT_INFO`, `CASE_PAT_HIST`
- `REACTION` -> `CASE_EVENT`
- `TEST` -> `CASE_LAB_DATA` (with lookups such as `LM_DOSE_UNITS`)
- `ACTIVESUBSTANCE` -> `CASE_PROD_INGREDIENT` (plus `CASE_PRODUCT` / product views)
- `DRUGRECURRENCE` -> `CASE_PRODUCT`
- `DRUGREACTIONRELATEDNESS` -> `CASE_PRODUCT` (plus `CMN_FIELDS`, `CMN_PROFILE`)
- `SUMMARY` -> `CASE_MASTER`

Note: some product-level tags (for example `MEDICINALPRODUCT`, `DRUGINDICATION`) resolve through shared parent SQL contexts. Use `AE_SELECT_STMT_ELEMENT_ASSOC` + `AE_SELECT_STMT_COL_POSITION` and parent fallback to map correctly.

## Reverse Engineering Guidance for XML -> ARGUS Import Design

### 1) Build a Resolved Mapping View First
Create an intermediate mapping dataset with:
- `dtd_element`
- `parent_element`
- `resolved_sql_source_element` (where SQL was found)
- `resolved_ae_select_stmt_file`
- `resolved_ae_select_stmt` (optional loaded SQL text)
- `inheritance_depth`
- `ae_select_stmt_element_assoc`
- `ae_select_stmt_col_position`

Do not design direct XML->table mapping from raw columns without this resolution step.

### 2) Separate Mapping into Two Layers
- **Layer A: XML to staging/source tables** (Python parser + sequence preservation for repeating nodes).
- **Layer B: staging/source to `ARGUS_APP`** (PL/SQL migration packages).

Use CFG_E2B SQL artifacts as evidence for likely Argus targets, but keep import transformations independent from export formatting logic.

### 3) Preserve Repeating Context
For tags under repeating blocks (`reaction`, `drug`, `test`, `primarysource`, etc.):
- Keep XML ordinal/sequence in source tables.
- Keep parent-report and parent-node keys.
- Carry this into package processing order.

### 4) Respect Codelist and Lookup Behavior
CFG_E2B SQL includes codelist/lookup usage (for example `LM_%`, `CFG_%`, utility packages).
For import:
- keep raw XML code values in stage
- validate/decode via controlled package logic and LM/CFG joins
- centralize code translation in PL/SQL for consistency.

## Suggested Next Artifact (Optional but Recommended)
Generate a machine-readable resolved mapping file (CSV or table) with one row per `DTD_ELEMENT`, resolved SQL file, and inherited context. This will accelerate:
- source table design,
- package template generation,
- test-case design for XML import validation.

## Caution Notes
- CFG_E2B logic is export-oriented; import behavior may differ for edge cases.
- Some SQL expressions are formatting-centric (for XML output) and should not be copied as-is into import logic.
- Parent inheritance can span multiple levels; implement recursive resolution, not only one parent hop.

## Traceability
- CFG_E2B export artifacts:
  - `src/entities/E2B_R2/ICH_Ref/cfg_e2b_export/CFG_E2B_non_clob_filtered.xlsx`
  - `src/entities/E2B_R2/ICH_Ref/cfg_e2b_export/CFG_E2B_clob_manifest_filtered.xlsx`
  - `src/entities/E2B_R2/ICH_Ref/cfg_e2b_export/clob_exports`
- Prior workbook reference:
  - `src/entities/E2B_R2/E2B R2 Mapping.xlsx`
- XML structure references:
  - `src/entities/E2B_R2/ICH_Ref/ich-icsr-v2_1.dtd`
  - `src/entities/E2B_R2/ICH_Ref/testdata/ich-icsr-v2-1-testdata.sgm`

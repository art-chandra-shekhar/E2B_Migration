# E2B R2 DTD → ESM Table Mapping

## Purpose

Reference mapping between **ICH ICSR v2.1 DTD-driven XML elements** (per `E2B_R2_XML_Migration_Context.md`) and **Argus ESM staging tables** (from `esm_tables_description.sql`). Use for migration design, Python XML ingestion, PL/SQL load order, and agent context.

Project staging mirrors ESM/DTD block names as `S_*` tables in `mig-utility-R2/db/ddl/03_create_source_tables.sql`.

## Reference Inputs

| Source | Location |
|--------|----------|
| Migration context | `R2_KB/ICH_Ref/E2B_R2_XML_Migration_Context.md` |
| DTD | `R2_KB/ICH_Ref/ich-icsr-v2_1.dtd` |
| ESM DDL | `esm_tables_description.sql` (Argus ESM schema export) |
| Project staging DDL | `mig-utility-R2/db/ddl/03_create_source_tables.sql` |

## Core DTD Hierarchy

```text
ichicsr
  -> ichicsrmessageheader (single)
  -> safetyreport+ (one or more reports in a message)
       -> reportduplicate*
       -> linkedreport*
       -> primarysource+
       -> sender
       -> receiver
       -> patient
            -> medicalhistoryepisode*
            -> patientpastdrugtherapy*
            -> patientdeath?
                 -> patientdeathcause*
                 -> patientautopsy*
            -> parent?
                 -> parentmedicalhistoryepisode*
                 -> parentpastdrugtherapy*
            -> reaction+
            -> test*
            -> drug+
                 -> activesubstance*
                 -> drugrecurrence*
                 -> drugreactionrelatedness*
            -> summary?
```

## Cardinality (DTD notation)

| Marker | Meaning | Staging implication |
|--------|---------|---------------------|
| (none) | Mandatory single | Required validation; 1 row or embedded columns |
| `?` | Optional single (0..1) | Nullable parent/child |
| `*` | Optional repeating (0..n) | Child table + sequence column |
| `+` | Mandatory repeating (1..n) | Child table + required validation |

---

## Message level

| DTD element | Cardinality | ESM match | Project `S_*` |
|-------------|-------------|-----------|---------------|
| `ichicsr` | 1 (root) | `MESSAGES` (whole XML) | (no table; `ICHICSR_SEQ` on children) |
| `ichicsrmessageheader` | 1 | `MESSAGES.MESSAGEHEADER` (`MESSAGEHEADER_TY`) | (no table yet) |

**Supporting ESM:** `MESSAGES`, `MESSAGE_PAYLOAD`

---

## DTD block → ESM table → `S_*` staging

| DTD block | Cardinality | ESM table | `S_*` table |
|-----------|-------------|-----------|-------------|
| `safetyreport` | 1+ | `SAFETYREPORT` | `S_SAFETYREPORT` |
| `reportduplicate` | 0..n | `REPORTDUPLICATE` | `S_REPORTDUPLICATE` |
| `linkedreport` | 0..n | `LINKEDREPORT` | `S_LINKEDREPORT` |
| `primarysource` | 1..n | `PRIMARYSOURCE` | `S_PRIMARYSOURCE` |
| `sender` | 1 | `SENDER` | `S_SENDER` |
| `receiver` | 1 | `RECEIVER` | `S_RECEIVER` |
| `patient` | 1 | `PATIENT` | `S_PATIENT` |
| `medicalhistoryepisode` | 0..n | `MEDICALHISTORYEPISODE` | `S_MEDICALHISTORYEPISODE` |
| `patientpastdrugtherapy` | 0..n | `PATIENTPASTDRUGTHERAPY` | `S_PATIENTPASTDRUGTHERAPY` |
| `patientdeath` | 0..1 | `PATIENTDEATH` | `S_PATIENTDEATH` |
| `patientdeathcause` | 0..n | `PATIENTDEATHCAUSE` | `S_PATIENTDEATHCAUSE` |
| `patientautopsy` | 0..n | `PATIENTAUTOPSY` | `S_PATIENTAUTOPSY` |
| `parent` | 0..1 | `PARENT` | `S_PARENT` |
| `parentmedicalhistoryepisode` | 0..n | `PARENTMEDICALHISTORYEPISODE` | `S_PARENTMEDICALHISTORYEPISODE` |
| `parentpastdrugtherapy` | 0..n | `PARENTPASTDRUGTHERAPY` | `S_PARENTPASTDRUGTHERAPY` |
| `reaction` | 1..n | `REACTION` | `S_REACTION` |
| `test` | 0..n | `TEST` | `S_TEST` |
| `drug` | 1..n | `DRUG` | `S_DRUG` |
| `activesubstance` | 0..n | `ACTIVESUBSTANCE` | `S_ACTIVESUBSTANCE` |
| `drugrecurrence` | 0..n | `DRUGRECURRENCE` | `S_DRUGRECURRENCE` |
| `drugreactionrelatedness` | 0..n | `DRUGREACTIONRELATEDNESS` | `S_DRUGREACTIONRELATEDNESS` |
| `summary` | 0..1 | `SUMMARY` | `S_SUMMARY` |

Scalar fields under `safetyreport`, `patient`, `drug`, etc. are **columns** on the corresponding `S_*` table (not separate tables).

---

## ESM parent-key hierarchy

```text
MESSAGES (MSG_ID)
 └── SAFETYREPORT (REPORT_ID, MSG_ID)
      ├── REPORTDUPLICATE, LINKEDREPORT, PRIMARYSOURCE, SENDER, RECEIVER
      └── PATIENT (REPORT_ID)  — 1:1 with report
           ├── MEDICALHISTORYEPISODE, PATIENTPASTDRUGTHERAPY
           ├── PATIENTDEATH → PATIENTDEATHCAUSE, PATIENTAUTOPSY
           ├── PARENT → PARENTMEDICALHISTORYEPISODE, PARENTPASTDRUGTHERAPY
           ├── REACTION, TEST
           ├── DRUG → ACTIVESUBSTANCE, DRUGRECURRENCE, DRUGREACTIONRELATEDNESS
           └── SUMMARY
```

---

## `S_*` staging conventions

| Column pattern | Purpose |
|----------------|---------|
| `ICHICSR_SEQ`, `SAFETYREPORT_SEQ`, `PATIENT_SEQ`, `DRUG_SEQ`, … | XML hierarchy / load order keys |
| `*_SEQ` on repeating blocks | Occurrence sequence (`xml_seq_num` intent) |
| `CASE_NUMBER` | Migration business key (custom) |
| `GEN_SEQ`, `EVT_SEQ_NUM`, `PROD_SEQ_NUM`, `DRUG_SEQ_NUM` | Argus correlation (custom) |

**Intentionally excluded from `S_*` (ESM operational / R3):** `REPORT_ID`, `MSG_ID`, `*_ID`, `ENTERPRISE_ID`, workflow columns (`PROCESSED`, `STATUS`, …), `*R3` columns, full `SAFETYREPORT` BLOB/workflow fields.

**R2 DTD column coverage:** `S_*` tables include all R2 DTD leaf elements for their block (as `VARCHAR2(4000)` raw XML values) plus the custom columns above.

---

## Related ESM tables (out of scope for R2 staging)

| ESM table | Notes |
|-----------|--------|
| `CASESUMMARYNARRATIVE` | R3 narrative |
| `DRUGREACTIONRELATEDNESSR3`, `DRUGEVENTMATRIX`, `DRUGADDITIONALINFO` | R3 extensions |
| `DOCHELDBYSENDER` | R3 documents (R2: `documentlist` on `SAFETYREPORT`) |
| `STUDYIDENTIFICATION`, `STUDYREGISTRATION` | R3 (R2 study fields on `PRIMARYSOURCE`) |
| `EXTENSION`, `ACKNOWLEDGMENT` | Non-R2 ICSR body |

**Config / mapping:** `CFG_E2B`, `CFG_ESM_PARENT_MAPPING`, `LM_DTD_ELEMENT_MAPPING`, etc.

---

## Argus-derived staging (non-XML `S_*`)

These support Argus → target migration, not DTD XML parse:

- `S_CASELEVEL`, `S_CASEPRODUCTLEVEL`, `S_CASEEVENTLEVEL`, `S_PRODUCTEVENTLEVEL`
- `S_REPORTERLEVEL`, `S_SUBMISSIONLEVEL`

---

## Suggested migration load order

1. Message context (`ICHICSR_SEQ` / future message header staging)
2. `S_SAFETYREPORT`
3. `S_REPORTDUPLICATE`, `S_LINKEDREPORT`, `S_PRIMARYSOURCE`, `S_SENDER`, `S_RECEIVER`
4. `S_PATIENT`
5. `S_REACTION`, `S_DRUG` (+ `S_ACTIVESUBSTANCE`, `S_DRUGRECURRENCE`, `S_DRUGREACTIONRELATEDNESS`)
6. `S_TEST`, `S_MEDICALHISTORYEPISODE`, `S_PATIENTPASTDRUGTHERAPY`, death/parent blocks
7. `S_SUMMARY`

---

## Traceability

- Structure/cardinality: `E2B_R2_XML_Migration_Context.md`, `ich-icsr-v2_1.dtd`
- ESM definitions: `esm_tables_description.sql`
- Staging DDL audit applied: 2026-05-21

# E2B R2 XML Migration Context (ICSR -> Source -> ARGUS_APP)

## Purpose
This document captures the E2B R2 XML structure used for ICSR adverse event case exchange and translates it into migration design context for:

1. Python-based XML ingestion into source staging tables.
2. PL/SQL migration packages that move staged data into `ARGUS_APP` case tables.

It is intended as a practical reference so developers do not need to re-parse the full DTD for initial template implementation.

## Reference Inputs
- DTD schema: `ich-icsr-v2_1.dtd`
- Sample instance: `testdata/ich-icsr-v2-1-testdata.sgm`

## Core Hierarchy (DTD-Driven)

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

## Cardinality Rules (From DTD Notation)
- `?` = optional single block or field (0..1)
- `*` = optional repeating block (0..n)
- `+` = mandatory repeating block (1..n)
- no suffix = mandatory single block or field (exactly 1)

These markers should directly drive source-table parent-child design and required-field validation strategy.

## Single-Block Sections (Good Parent/Staging-Header Candidates)

### Message Scope
- `ichicsrmessageheader` (single per XML message)
  - Includes: `messagetype`, `messageformatversion`, `messageformatrelease`, `messagenumb`, sender/receiver identifiers, message date/date format.

### Safety Report Scope
- `safetyreport` core data (one row per report in a message)
  - Key identifiers and case-level attributes such as:
    - `safetyreportid`
    - case-level country/dates/seriousness flags
    - duplicate/nullification indicators

### Required Embedded Single Blocks Under `safetyreport`
- `sender` (single)
- `receiver` (single)
- `patient` (single, but with many repeating nested children)

### Optional Single Blocks Under `patient`
- `patientdeath` (optional, includes its own repeating child blocks)
- `parent` (optional, includes its own repeating child blocks)
- `summary` (optional narrative and comments block)

## Repeating/Nested Sections (Good Child Staging Candidates)

### Under `safetyreport`
- `reportduplicate*`
- `linkedreport*`
- `primarysource+`

### Under `patient`
- `medicalhistoryepisode*`
- `patientpastdrugtherapy*`
- `reaction+` (multiple adverse events possible)
- `test*`
- `drug+` (multiple suspect/concomitant products possible)

### Under `patientdeath`
- `patientdeathcause*`
- `patientautopsy*`

### Under `parent`
- `parentmedicalhistoryepisode*`
- `parentpastdrugtherapy*`

### Under `drug`
- `activesubstance*`
- `drugrecurrence*`
- `drugreactionrelatedness*`

## Migration Template Guidance

### 1) Source Keying and Relationship Strategy
- Persist both message-level and report-level technical keys.
- Recommended stable business link keys include:
  - `messagenumb` (message identity)
  - `safetyreportid` (case/report identity)
- Add surrogate source row IDs for each staging table and FK links to parent source table rows.

### 2) Preserve Occurrence Order for Repeating Blocks
- For every repeating XML block (`*`/`+`), store an explicit sequence column (for example: `xml_seq_num`).
- This ensures deterministic PL/SQL processing and traceable re-construction of original XML ordering.

### 3) Keep Raw XML Values in Staging
- Do not over-transform in Python ingestion.
- Store coded fields (for example seriousness, route, outcome, age units) as raw XML code values first.
- Perform controlled code translation/validation in PL/SQL migration packages.

### 4) Keep Date + DateFormat Pairs Together
- Many date elements have a paired `*dateformat` element.
- Persist both values in source tables for each date attribute.
- Defer calendar conversion/validation logic to PL/SQL layer where business rules are centralized.

### 5) Handle Long Text as CLOB-Compatible Data
- Narrative and comment fields can be very long (`narrativeincludeclinical`, `sendercomment`, medical history texts).
- Use data types and package APIs that safely support large text.

### 6) Build Migration in Parent-to-Child Sequence
- Suggested package load order (high level):
  1. Message/header source data
  2. Safety report core (case header)
  3. Reporter/source/sender/receiver details
  4. Patient core
  5. Reactions/events
  6. Products/drugs and their child details
  7. Tests/history/parent/death sub-blocks
  8. Narrative/summary text

## Minimal Pseudo-Mapping (Template Intent)
- `ichicsrmessageheader` -> message staging/header table -> migration context and audit linkage
- `safetyreport` core -> case header staging table -> `ARGUS_APP` case-level entities
- `patient` core -> patient staging table -> `ARGUS_APP` case patient entities
- `reaction+` -> reaction/event staging table -> `ARGUS_APP` event/reaction entities
- `drug+` -> product/drug staging table -> `ARGUS_APP` product/suspect drug entities
- `summary` -> narrative staging table -> `ARGUS_APP` narrative/comment entities

Note: Final table-by-table mapping to exact `ARGUS_APP` targets should be completed during package implementation once the project-specific table dictionary and coding rules are finalized.

## Sample File Observations (Practical Implementation Clues)
- The sample `.sgm` includes multiple instances of:
  - `reportduplicate`
  - `linkedreport`
  - `primarysource`
  - `medicalhistoryepisode`
  - `patientpastdrugtherapy`
  - `reaction`
  - `test`
- Nested repeating behavior is present under `patientdeath`, `parent`, and `drug`.
- Text fields include long free-text values that should not be truncated.

## Implementation Notes for Python Parser Templates
- Use schema-aware parsing patterns:
  - one parser routine for single blocks
  - one parser routine for repeating blocks with ordinal capture
- Emit parent row first, then child rows with foreign keys and sequence.
- Capture parsing diagnostics per report:
  - missing required elements (`+` and mandatory singles)
  - invalid date/dateformat combinations
  - unknown/unmapped elements for later extension

## Traceability
All structure and cardinality guidance in this document is based on:
- `src/entities/E2B_R2/ICH_Ref/ich-icsr-v2_1.dtd`
- `src/entities/E2B_R2/ICH_Ref/testdata/ich-icsr-v2-1-testdata.sgm`

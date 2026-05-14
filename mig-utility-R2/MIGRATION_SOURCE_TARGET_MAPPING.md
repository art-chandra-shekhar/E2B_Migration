# Migration Source-to-Target Mapping

Source: `mig-utility-R2/db/packages/08_PKG_MG_MIGRATION_BODY.SQL`

This document lists all target tables written by `pkg_mg_migration`, identifies whether the write is an `INSERT` or `UPDATE`, and maps each target to the source tables or driving cursor/query used in the package body.

## Notes

- "Currently invoked" means the procedure call is active inside `p_mg_execution`.
- "Defined but not invoked" means the procedure contains insert logic, but its call is currently commented out in `p_mg_execution`.
- Some procedures enrich target rows using already-loaded target tables such as `TCASE_MASTER`, `TCASE_STUDY`, `TCASE_PRODUCT`, and `TCASE_EVENT`. Those are included in the source mapping where applicable.
- Some procedures insert placeholder/default rows from `DUAL`; those are noted explicitly.

## Currently Invoked by `p_mg_execution`

| Procedure | Target Table | DML | Source Tables / Driving Query |
| --- | --- | --- | --- |
| `p_mg_case_master` | `TCASE_MASTER` | `INSERT` | `SBL_SAFETYREPORT`, `SBL_CASELEVEL` |
| `p_mg_case_study` | `TCASE_STUDY` | `INSERT` | `SBL_PRIMARYSOURCE`; also checks `SBL_DRUG` for blinded product presence |
| `p_mg_case_literature` | `TCASE_LITERATURE` | `INSERT` | `SBL_PRIMARYSOURCE` |
| `p_mg_case_pat_info` | `TCASE_PAT_INFO` | `INSERT` | `SBL_PATIENT` |
| `p_mg_case_pat_hist` | `TCASE_PAT_HIST` | `INSERT` | `SBL_PATIENTPASTDRUGTHERAPY`, `SBL_MEDICALHISTORYEPISODE` |
| `p_mg_case_lab_data` | `TCASE_LAB_DATA` | `INSERT` | `SBL_TEST` |
| `p_mg_case_pat_tests` | `TCASE_PAT_TESTS` | `INSERT` | `SBL_PATIENT` |
| `p_mg_case_event` | `TCASE_EVENT` | `INSERT` | `SBL_REACTIONS`, `SBL_CASEEVENTLEVEL` |
| `p_mg_case_product` | `TCASE_PRODUCT` | `INSERT` | `SBL_DRUG`, `SBL_CASEPRODUCTLEVEL`, `SBL_PRODUCTEVENTLEVEL`, `TCASE_STUDY`, `TLM_PRODUCT`, `TLM_LICENSE` |
| `p_mg_case_product` | `TCASE_PROD_DRUGS` | `INSERT` | `SBL_DRUG`, `SBL_CASEPRODUCTLEVEL`, `TLM_PRODUCT` |
| `p_mg_case_product` | `TCASE_DOSE_REGIMENS` | `INSERT` | `SBL_DRUG` via cursor `c_case_dose_regimens` |
| `p_mg_case_prod_ingredient` | `TCASE_PROD_INGREDIENT` | `INSERT` | `TCASE_PRODUCT`, `TLM_PRODUCT`, `TLM_PF_INGREDIENTS`, `SBL_DRUG`, `SBL_ACTIVESUBSTANCE` |
| `p_mg_case_prod_indications` | `TCASE_PROD_INDICATIONS` | `INSERT` | `SBL_DRUG` |
| `p_mg_case_event_assess` | `TCASE_EVENT_ASSESS` | `INSERT` | `TCASE_PRODUCT`, `TCASE_EVENT`, `TCASE_MASTER`, `SBL_PRODUCTEVENTLEVEL`, `TLM_LICENSE`, `TLM_LIC_PRODUCTS`, `TLM_COUNTRIES` |
| `p_mg_case_comments` | `TCASE_COMMENTS` | `INSERT` | `SBL_SUMMARY` |
| `p_mg_case_company_cmts` | `TCASE_COMPANY_CMTS` | `INSERT` | `SBL_SUMMARY` |
| `p_mg_case_narrative` | `TCASE_NARRATIVE` | `INSERT` | `SBL_SUMMARY` |
| `p_mg_case_notes_attach` | `TCASE_NOTES_ATTACH` | `INSERT` | `MG_CASE_ADDN_ATTACHMENTS`, `TLM_CLASSIFICATION`; also reads `TCASE_NOTES_ATTACH` to compute next `SORT_ID` |
| `p_mg_case_assess` | `TCASE_ASSESS` | `INSERT` | No source table; inserts a default row using generated/default values |
| `p_mg_case_reporters` | `TCASE_REPORTERS` | `INSERT` | `SBL_PRIMARYSOURCE`, `SBL_REPORTERLEVEL` |
| `p_mg_case_reference` | `TCASE_REFERENCE` | `INSERT` | `SBL_LINKEDREPORT`, `SBL_REPORTDUPLICATE`, `SBL_SAFETYREPORT`, `TLM_REF_TYPES` |
| `p_mg_case_routing` | `TCASE_ROUTING` | `INSERT` | `TCASE_MASTER` |
| `p_mg_cmn_reg_reports` | `TCMN_REG_REPORTS` | `INSERT` | `SBL_SUBMISSIONLEVEL`, `TCASE_PRODUCT`, `TCASE_MASTER`, `TLM_REPORT_TYPE`, `TLM_LIC_PRODUCTS`, `TLM_LICENSE`, `TCASE_EVENT`, `TLM_REGULATORY_CONTACT` |
| `p_mg_cmn_reg_reports` | `TCASE_REG_REPORTS` | `INSERT` | Driven by `SBL_SUBMISSIONLEVEL`; populated alongside `TCMN_REG_REPORTS` using the same loop and derived values |
| `p_mg_Audit_log` | `TCASE_NOTES_ATTACH` | `INSERT` | `MG_AUDIT_LOG_TMP`, `TLM_CLASSIFICATION`; also reads `TCASE_NOTES_ATTACH` to compute next `SORT_ID` |
| `p_mg_cfg_audit_log_pending` | `TCFG_AUDIT_LOG_PENDING` | `INSERT` | `DUAL` only; inserts a default audit-pending row |

## Defined but Not Invoked in `p_mg_execution`

| Procedure | Target Table | DML | Source Tables / Driving Query |
| --- | --- | --- | --- |
| `p_mg_case_followup` | `TCASE_FOLLOWUP` | `INSERT` | `SBL_SAFETYREPORT` |
| `p_mg_case_classifications` | `TCASE_CLASSIFICATIONS` | `INSERT` | `DUAL` only |
| `p_mg_case_parent_info` | `TCASE_PARENT_INFO` | `INSERT` | `DUAL` only |
| `p_mg_case_pat_race` | `TCASE_PAT_RACE` | `INSERT` | `DUAL` only |
| `p_mg_case_pregnancy` | `TCASE_PREGNANCY` | `INSERT` | `DUAL` only |
| `p_mg_case_neonates` | `TCASE_NEONATES` | `INSERT` | `DUAL` only |
| `p_mg_case_hosp` | `TCASE_HOSP` | `INSERT` | `DUAL` only |
| `p_mg_case_death` | `TCASE_DEATH` | `INSERT` | `DUAL` only |
| `p_mg_case_death_details` | `TCASE_DEATH_DETAILS` | `INSERT` | `DUAL` only |
| `p_mg_case_event_detail` | `TCASE_EVENT_DETAIL` | `INSERT` | `SBL_PRODUCTEVENTLEVEL` |
| `p_mg_case_lock_info` | `TCASE_LOCK_INFO` | `INSERT` | `DUAL` only |
| `p_mg_case_justifications` | `TCASE_JUSTIFICATIONS` | `INSERT` | `DUAL` only |
| `p_mg_case_local_eva_comment` | `TCASE_LOCAL_EVA_COMMENT` | `INSERT` | `DUAL` only |
| `p_mg_case_medwatch_data` | `TCASE_MEDWATCH_DATA` | `INSERT` | `DUAL` only |
| `p_mg_case_actions` | `TCASE_ACTIONS` | `INSERT` | `DUAL` only |

## Update Operations

| Procedure | Target Table | DML | Source / Basis |
| --- | --- | --- | --- |
| `p_mg_case_event` | `TCASE_MASTER` | `UPDATE` | Derived from inserted `TCASE_EVENT` rows by recalculating case seriousness |
| `p_mg_case_product` | `TCASE_PRODUCT` | `UPDATE` | Self-update to assign `STUDY_PRODUCT_NUM = ROWNUM` for study drugs |
| `p_mg_case_product` | `TCASE_STUDY` | `UPDATE` | Derived from `TCASE_PRODUCT` count of rows where `CO_DRUG_CODE = 'Study Drug'` |
| `p_mg_case_event_assess` | `SBL_PRODUCTEVENTLEVEL` | `UPDATE` | Updates `LIC_MAP_CMNT` during source-license to target-license mapping |
| `p_mg_execution` | `MG_CASE_LIST` | `UPDATE` | Updates migration status using counts from `MG_CASE_ERROR_LOG` |

## Procedures with No Insert/Update Logic

These procedures are present but currently do not write any table:

- `p_mg_case_contact_log`
- `p_mg_case_worklist`
- `p_mg_case_null_flavor`
- `p_mg_case_local_lock`

## Quick Summary by Source Area

- Case header: `SBL_SAFETYREPORT`, `SBL_CASELEVEL` -> `TCASE_MASTER`
- Study, literature, reporters: `SBL_PRIMARYSOURCE`, `SBL_REPORTERLEVEL`, `SBL_DRUG` -> `TCASE_STUDY`, `TCASE_LITERATURE`, `TCASE_REPORTERS`
- Patient area: `SBL_PATIENT`, `SBL_PATIENTPASTDRUGTHERAPY`, `SBL_MEDICALHISTORYEPISODE`, `SBL_TEST` -> `TCASE_PAT_INFO`, `TCASE_PAT_HIST`, `TCASE_PAT_TESTS`, `TCASE_LAB_DATA`
- Events and products: `SBL_REACTIONS`, `SBL_CASEEVENTLEVEL`, `SBL_DRUG`, `SBL_CASEPRODUCTLEVEL`, `SBL_PRODUCTEVENTLEVEL`, `SBL_ACTIVESUBSTANCE` -> `TCASE_EVENT`, `TCASE_PRODUCT`, `TCASE_PROD_DRUGS`, `TCASE_DOSE_REGIMENS`, `TCASE_PROD_INGREDIENT`, `TCASE_PROD_INDICATIONS`, `TCASE_EVENT_ASSESS`
- Comments and attachments: `SBL_SUMMARY`, `MG_CASE_ADDN_ATTACHMENTS`, `MG_AUDIT_LOG_TMP` -> `TCASE_COMMENTS`, `TCASE_COMPANY_CMTS`, `TCASE_NARRATIVE`, `TCASE_NOTES_ATTACH`
- Regulatory reporting: `SBL_SUBMISSIONLEVEL` plus derived target lookups -> `TCMN_REG_REPORTS`, `TCASE_REG_REPORTS`

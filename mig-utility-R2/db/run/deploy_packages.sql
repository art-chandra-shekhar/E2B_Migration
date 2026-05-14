-- =============================================================================
-- Deploy migration utility packages: specification then body for each unit.
--
-- Order (dependency / rollout sequence):
--   1) CLEANUP  — PKG_CLEANUP_ARGUS
--   2) UTIL     — PKG_MG_UTIL
--   3) BUSS     — PKG_MG_BUSS_RULES
--   4) MIGRATION — PKG_MG_MIGRATION
--
-- Run as the package owner schema, from db/run (or pass full path to this file):
--   sqlplus owner/password@connect @deploy_packages.sql
--
-- @@ paths are relative to this script's directory.
--
-- Spool: db/logs/sql/deploy_packages.LOG (relative to SQL*Plus cwd; run from db/run).
-- =============================================================================

SET ECHO ON
SET FEEDBACK ON
SET VERIFY ON
SET SERVEROUTPUT ON SIZE UNLIMITED
WHENEVER SQLERROR EXIT SQL.SQLCODE

SPOOL ../logs/sql/deploy_packages.LOG

PROMPT ========== 1) CLEANUP — PKG_CLEANUP_ARGUS (spec) ==========
@@../packages/05_PKG_CLEANUP_ARGUS_SPECIFICATION.SQL

PROMPT ========== 1) CLEANUP — PKG_CLEANUP_ARGUS (body) ==========
@@../packages/06_PKG_CLEANUP_ARGUS_BODY.SQL

PROMPT ========== 2) UTIL — PKG_MG_UTIL (spec) ==========
@@../packages/01_PKG_MG_UTIL_SPECIFICATION.SQL

PROMPT ========== 2) UTIL — PKG_MG_UTIL (body) ==========
@@../packages/02_PKG_MG_UTIL_Body.SQL

PROMPT ========== 3) BUSS — PKG_MG_BUSS_RULES (spec) ==========
@@../packages/03_PKG_MG_BUSS_RULES_SPECIFICATION.SQL

PROMPT ========== 3) BUSS — PKG_MG_BUSS_RULES (body) ==========
@@../packages/04_PKG_MG_BUSS_RULES_BODY.SQL

PROMPT ========== 4) MIGRATION — PKG_MG_MIGRATION (spec) ==========
@@../packages/07_PKG_MG_MIGRATION_SPECIFICATION.SQL

PROMPT ========== 4) MIGRATION — PKG_MG_MIGRATION (body) ==========
@@../packages/08_PKG_MG_MIGRATION_BODY.SQL

PROMPT ========== Package deploy finished ==========
SPOOL OFF

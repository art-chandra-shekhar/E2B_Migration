-- =============================================================================
-- Create staging user (name + password from substitution variables &1, &2).
--
-- These should match TARGET_DB_USER and TARGET_DB_PASSWORD in env/.env (same
-- credentials the migration loader uses for the staging schema).
--
-- Run as SYS (or a user with CREATE USER and rights to grant on ARGUS_APP /
-- ESM_OWNER objects).
--
-- Invocation (after: set -a && source ../../env/.env && set +a):
--   sqlplus / as sysdba @create_staging_schema.sql ${TARGET_DB_USER} ${TARGET_DB_PASSWORD}
-- Or run create_staging_schema.sh from this directory, which sources env/.env.
--
-- Spool: db/logs/sql/create_staging_schema.LOG (relative to SQL*Plus cwd; run from db/run).
-- =============================================================================

SET DEFINE ON

SET ECHO ON;
SET TIMING ON;
SET TIME ON;

col START_TIME HEADING "START_TIME"
col START_TIME format A20
col END_TIME HEADING "END_TIME"
col END_TIME format A20

DEFINE STG_USER = &1
DEFINE STG_PASS = &2

SPOOL ../logs/sql/create_staging_schema.LOG

SELECT TO_CHAR( SYSDATE, 'DD-MON-YYYY HH24:MI:SS' ) START_TIME FROM DUAL;


CREATE USER &&STG_USER IDENTIFIED BY &&STG_PASS
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    QUOTA UNLIMITED ON USERS;

-- CONNECT includes CREATE SESSION; RESOURCE is legacy (includes some object privs).
GRANT CONNECT TO &&STG_USER;
GRANT RESOURCE TO &&STG_USER;

-- Object privileges in own schema.
GRANT CREATE TABLE TO &&STG_USER;
-- In Oracle, CREATE PROCEDURE covers procedures, functions, and packages in your schema.
GRANT CREATE PROCEDURE TO &&STG_USER;

-- =============================================================================
-- Read-only: SELECT on tables, views, and materialized views in ARGUS_APP and
-- ESM_OWNER. Re-run this block after new objects are added if grants are not
-- automated.
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

DECLARE
    v_user VARCHAR2(128) := UPPER('&&STG_USER');
    v_sql  VARCHAR2(4000);
    CURSOR c_objs IS
        SELECT o.owner,
               o.object_name,
               o.object_type
        FROM   all_objects o
        WHERE  o.owner IN ('ARGUS_APP', 'ESM_OWNER', 'MEDDRA_ARGUS_15_1')
        AND    o.object_type IN ('TABLE', 'VIEW', 'MATERIALIZED VIEW')
        AND    o.secondary = 'N';
BEGIN
    FOR r IN c_objs LOOP
        BEGIN
            v_sql := 'GRANT SELECT ON "' || r.owner || '"."' || r.object_name || '" TO ' || v_user;
            EXECUTE IMMEDIATE v_sql;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Skip/fail: ' || r.owner || '.' || r.object_name || ' - ' || SQLERRM);
        END;
    END LOOP;
END;
/

-- Sequences: SELECT allows CURRVAL/NEXTVAL for read-oriented jobs.
DECLARE
    v_user VARCHAR2(128) := UPPER('&&STG_USER');
    v_sql  VARCHAR2(4000);
    CURSOR c_seq IS
        SELECT s.sequence_owner, s.sequence_name
        FROM   all_sequences s
        WHERE  s.sequence_owner IN ('ARGUS_APP', 'ESM_OWNER');
BEGIN
    FOR r IN c_seq LOOP
        BEGIN
            v_sql := 'GRANT SELECT ON "' || r.sequence_owner || '"."' || r.sequence_name || '" TO ' || v_user;
            EXECUTE IMMEDIATE v_sql;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    END LOOP;
END;
/

-- =============================================================================
-- EXECUTE on common SYS-owned DBMS_* packages (extend as needed).
-- =============================================================================

GRANT EXECUTE ON SYS.DBMS_RANDOM             TO &&STG_USER;

-- =============================================================================
-- Notes
-- -----------------------------------------------------------------------------
-- 1) RESOURCE is deprecated; prefer explicit quotas + least privilege long-term.
-- 2) CREATE PROCEDURE is the Oracle privilege for procedures, functions, and
--    packages; there is no separate CREATE PACKAGE / CREATE FUNCTION system grant.
-- 3) Read-only here = SELECT on tables/views/MVs (and sequences). It does not
--    grant EXECUTE on application packages in ARGUS_APP / ESM_OWNER. Staging
--    TCASE_* DDL does not create FKs to ARGUS_APP (avoids REFERENCES privilege).
-- 4) Object grants require the run-as user to be able to grant on each object
--    (typically SYS, or schema owners, or GRANT ANY OBJECT PRIVILEGE).
-- =============================================================================


-- =============================================================================
-- DML privileges on ARGUS_APP and ESM_OWNER.
-- =============================================================================
GRANT DELETE, INSERT, SELECT, UPDATE ON ARGUS_APP.CASE_E2BATTACHMENT_STATUS TO &&STG_USER;
GRANT DELETE, INSERT, SELECT, UPDATE ON ARGUS_APP.USER_CASE_ASSIGNMENT TO &&STG_USER;
GRANT DELETE, INSERT, SELECT, UPDATE ON ARGUS_APP.CMN_AUDIT_LOG TO &&STG_USER;
GRANT DELETE, INSERT, SELECT, UPDATE ON ARGUS_APP.CASE_NULL_FLAVOR TO &&STG_USER;
GRANT DELETE, INSERT, SELECT, UPDATE ON ARGUS_APP.USER_CASE_PROCESSING_TIME TO &&STG_USER;

-- =============================================================================
-- EXECUTE on ARGUS packages (extend as needed).
-- =============================================================================
GRANT EXECUTE ON VPD_ADMIN.PKG_RLS TO &&STG_USER;


SELECT TO_CHAR( SYSDATE, 'DD-MON-YYYY HH24:MI:SS' ) END_TIME FROM DUAL;

SET ECHO OFF;
SPOOL OFF;

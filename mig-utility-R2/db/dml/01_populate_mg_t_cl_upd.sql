-- Populate MG_T_CL_UPD from source.
-- Spool: db/logs/sql/01_populate_mg_t_cl_upd.LOG (path is relative to SQL*Plus cwd;
--         run from db/dml or db/run, or override: DEFINE spool_log_dir = '/your/path' before @)

SET ECHO ON;
SET TIMING ON;
SET TIME ON;

col START_TIME HEADING "START_TIME"
col START_TIME format A20
col END_TIME HEADING "END_TIME"
col END_TIME format A20

-- Define Spool Log Directory
DEFINE spool_log_dir = '../logs/sql'

-- Spool Log File
SPOOL &spool_log_dir./01_populate_mg_t_cl_upd.LOG

-- Log Start Time
SELECT TO_CHAR( SYSDATE, 'DD-MON-YYYY HH24:MI:SS' ) START_TIME FROM DUAL;


-- Table Population Logic Starts Here
INSERT INTO MG_T_CL_UPD SELECT * FROM xxxx;

COMMIT;
-- Table Population Logic Ends Here

-- Log End Time
SELECT TO_CHAR( SYSDATE, 'DD-MON-YYYY HH24:MI:SS' ) END_TIME FROM DUAL;

-- Echo Off
SET ECHO OFF;

-- Spool Off
SPOOL OFF;

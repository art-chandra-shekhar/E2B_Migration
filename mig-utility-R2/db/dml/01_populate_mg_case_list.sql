-- Populate MG_CASE_LIST from source.
-- Spool: db/logs/sql/01_populate_mg_case_list.LOG (path is relative to SQL*Plus cwd;
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
SPOOL &spool_log_dir./01_populate_mg_case_list.LOG

-- Log Start Time
SELECT TO_CHAR( SYSDATE, 'DD-MON-YYYY HH24:MI:SS' ) START_TIME FROM DUAL;


-- Table Population Logic Starts Here
INSERT INTO MG_CASE_LIST (SCASENUM)
SELECT SAFETYREPORTID FROM S_SAFETYREPORT;


-- Add TCASENUM, TCASEID, STATUS, ERRORS, WARNINGS, EXEC_THREAD_ID
DECLARE
    v_tcaseid NUMBER;
    v_tcasenum VARCHAR2(2000);

    /* Update below values as per Project Requirements */
    v_status NUMBER := 0;
    v_errors NUMBER := 0;
    v_warnings NUMBER := 0;
    v_exec_thread_id NUMBER := 1;
    /* End of Project Requirements */
    
    CURSOR c_case_master IS
        SELECT SAFETYREPORTID FROM S_SAFETYREPORT;
BEGIN
    FOR rec IN c_case_master LOOP
        -- Get next case id
        --SELECT ARGUS_APP.S_CASE_MASTE_CASE_ID.NEXTVAL INTO v_tcaseid FROM DUAL;
        
        -- Get next case number
        --SELECT ARGUS_APP.S_CASE_MASTE_CASE_NUM.NEXTVAL INTO v_tcasenum FROM DUAL;

        UPDATE MG_CASE_LIST
           SET TCASENUM = v_tcasenum,
               TCASEID = v_tcaseid, 
               STATUS = v_status, 
               ERRORS = v_errors, 
               WARNINGS = v_warnings, 
               EXEC_THREAD_ID = v_exec_thread_id 
         WHERE SCASENUM = rec.SAFETYREPORTID;
    END LOOP;
END;

COMMIT;
-- Table Population Logic Ends Here

-- Log End Time
SELECT TO_CHAR( SYSDATE, 'DD-MON-YYYY HH24:MI:SS' ) END_TIME FROM DUAL;

-- Echo Off
SET ECHO OFF;

-- Spool Off
SPOOL OFF;

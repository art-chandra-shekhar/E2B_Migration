-- Populate MG_CODELIST_MAP from source.
-- Spool: db/logs/sql/01_populate_mg_codelist_map.LOG (path is relative to SQL*Plus cwd;
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
SPOOL &spool_log_dir./01_populate_mg_codelist_map.LOG

-- Log Start Time
SELECT TO_CHAR( SYSDATE, 'DD-MON-YYYY HH24:MI:SS' ) START_TIME FROM DUAL;


-- Table Population Logic Starts Here

/*TRANSFER SCRIPT FROM MG_CL_MASTER TO S_MG_CL_INFO AND T_MG_CL_INFO*/
SET SERVEROUTPUT ON;
DECLARE
    CURSOR cur IS
        SELECT
        CL_NAME,
        S_CL_TABLE,
        S_CL_CODE_COL,
        S_CL_DECODE_COL,
        S_WHERE_COND,
        T_CL_TABLE,
        T_CL_CODE_COL,
        T_CL_DECODE_COL,
        T_WHERE_COND,
        ACTIVE,
        STATUS,
        S_CL_DISPLAY_COL,
        T_CL_DISPLAY_COL,
        T_CL_E2B_CODE_COL
    FROM
        mg_cl_master
    WHERE S_CL_CODE_COL IS NOT NULL
      AND T_CL_CODE_COL IS NOT NULL;

    v_sql    VARCHAR2(4000);
    v_code   VARCHAR2(4000);
    v_decode VARCHAR2(4000);
    r2       SYS_REFCURSOR;
    v_disp_s VARCHAR2(100) := NULL;
    v_disp_t VARCHAR2(100) := NULL;
    vdisp    NUMBER := NULL;
    V_E2B_CODE  NUMBER;
    V_A2_CODE   VARCHAR2(2000);
BEGIN
    DELETE FROM MG_S_CL_INFO;
    DELETE FROM MG_T_CL_INFO;

    FOR r1 IN cur LOOP
        if r1.T_CL_DISPLAY_COL is null THEN 
            V_DISP_t:= '1 display'; 
        ELSE 
            V_DISP_T:='DISPLAY'; 
        END IF;
    
        /*source_table*/
        v_sql := 'SELECT DISTINCT ' || r1.S_CL_CODE_COL || --','||v_disp_s||
                 ' FROM ' || r1.S_CL_TABLE || 
                 ' WHERE ' || r1.S_CL_DECODE_COL || ' IS NOT NULL';
                

        -- Append S_WHERE_COND if present
        IF r1.S_WHERE_COND IS NOT NULL THEN
            v_sql := v_sql || ' AND ' || r1.S_WHERE_COND;
        END IF;
        
        --dbms_output.put_line('Source SQL');
        --dbms_output.put_line(v_sql);

        OPEN r2 FOR v_sql;
        LOOP
            FETCH r2 INTO v_code; --, vdisp;
            EXIT WHEN r2%NOTFOUND;
            
            --  If Source Code contains Non-Numeric, load in S_CL_DECODE column
            IF REGEXP_LIKE(v_code, '[[:alpha:]]') THEN
                INSERT INTO MG_S_CL_INFO(CL_NAME, S_CL_DECODE, S_CL_DISPLAY, CODELIST_TYPE)
                VALUES (r1.CL_NAME, v_code, vdisp, 'E2B');
            ELSE
            --  If Source Code contains Numbers, load in S_CL_CODE column
                INSERT INTO MG_S_CL_INFO(CL_NAME, S_CL_CODE, S_CL_DISPLAY, CODELIST_TYPE)
                VALUES (r1.CL_NAME, v_code, vdisp, 'E2B');
            END IF;
            
        END LOOP;
        CLOSE r2;

        /*target_table*/
        v_sql := 'SELECT DISTINCT ' || r1.T_CL_CODE_COL || ', ' || r1.T_CL_DECODE_COL || ',' || v_disp_t ||
                 CASE WHEN R1.T_CL_E2B_CODE_COL IS NOT NULL THEN ','|| R1.T_CL_E2B_CODE_COL ELSE ', NULL E2B_CODE' END ||
                 CASE WHEN r1.T_CL_TABLE = 'LM_COUNTRIES' THEN ', A2' ELSE ', NULL A2' END ||
                 ' FROM ARGUS_APP.' || r1.T_CL_TABLE || 
                 ' WHERE ' || r1.T_CL_DECODE_COL || ' IS NOT NULL';

        -- Append T_WHERE_COND if present
        IF r1.t_where_cond IS NOT NULL THEN
            v_sql := v_sql
                     || ' AND '
                     || REPLACE(UPPER(r1.t_where_cond),'WHERE');
        END IF;
        
        --dbms_output.put_line('Target SQL');
        --dbms_output.put_line(v_sql);
        
        OPEN r2 FOR v_sql;
    
        LOOP
            FETCH r2 INTO
                v_decode,
                v_code,
                vdisp, 
                V_E2B_CODE,
                V_A2_CODE;
                
            EXIT WHEN r2%notfound;
            
            INSERT INTO mg_t_cl_info (
                cl_name,
                t_cl_code,
                t_cl_decode,
                t_cl_display,
                t_cl_e2b_code,
                t_a2_decode
            ) VALUES ( r1.cl_name,
                       v_code,
                       v_decode,
                       vdisp, 
                       V_E2B_CODE,
                       V_A2_CODE);
    
        END LOOP;
    
        CLOSE r2;
    
        /*updating active and status*/
        UPDATE mg_cl_master
        SET
            active = 1,
            status = 1
        WHERE
            cl_name = r1.cl_name;

    END LOOP;
END;
/


TRUNCATE TABLE MG_CODELIST_MAP;
INSERT INTO MG_CODELIST_MAP (CODELIST_TYPE, CL_NAME, S_CL_E2B_CODE,S_CL_E2B_DECODE, S_CL_CODE,S_CL_DECODE, MAPPING_TYPE, T_CL_CODE, T_CL_DECODE, T_CL_E2B_CODE, T_A2_DECODE, COMMENTS) 
WITH SRC1 AS (
    SELECT distinct CODELIST_TYPE, CL_NAME, S_CL_CODE, S_CL_DECODE FROM MG_S_CL_INFO  WHERE CODELIST_TYPE = 'E2B' AND CL_NAME<>'Formulation' and cl_name <> 'Dose Units'
),
SRC2 AS (
    SELECT distinct CODELIST_TYPE, CL_NAME, S_CL_CODE, S_CL_DECODE FROM MG_S_CL_INFO  WHERE CODELIST_TYPE = 'Non_E2B' and cl_name <> 'Dose Units'
    UNION
    SELECT distinct CODELIST_TYPE, CL_NAME, S_CL_CODE, S_CL_DECODE FROM MG_S_CL_INFO WHERE CODELIST_TYPE = 'E2B' AND CL_NAME='Formulation' and cl_name <> 'Dose Units')
SELECT 'E2B',NVL(SRC.CL_NAME,TGT.CL_NAME),SRC.S_CL_CODE,SRC.S_CL_DECODE,NULL,NULL,
    CASE 
        WHEN SRC.CL_NAME IS NOT NULL AND TGT.CL_NAME IS NOT NULL THEN 'Exact Match'
        WHEN SRC.CL_NAME IS NOT NULL THEN 'Only in Source'
        ELSE 'Only in Target'
    END AS MAPPING_TYPE,TGT.T_CL_CODE,TGT.T_CL_DECODE,TGT.T_CL_E2B_CODE,TGT.T_A2_DECODE,
    CASE 
        WHEN SRC.S_CL_CODE IS NOT NULL THEN 'E2B Codelist Mapping using Tgt E2B Code'
       ELSE  'E2B Codelist Mapping using Tgt E2B decode' END
FROM SRC1 SRC
FULL OUTER JOIN (select * from MG_T_CL_INFO where cl_name <> 'Dose Units' ) TGT
ON (
    UPPER(TRIM(SRC.CL_NAME)) = UPPER(TRIM(TGT.CL_NAME))
    AND (
        (SRC.S_CL_CODE IS NOT NULL 
            AND UPPER(LTRIM(TRIM(SRC.S_CL_CODE),'0')) = UPPER(LTRIM(TRIM(TGT.T_CL_E2B_CODE),'0')))
        OR
        (SRC.S_CL_CODE IS NULL 
            AND UPPER(TRIM(SRC.S_CL_DECODE)) = UPPER(TRIM(TGT.T_A2_DECODE)))
    )
)
/*
UNION
SELECT
Case when nvl(src.cl_name,tgt.cl_name) = 'Formulation' then  'E2B' else 'Non_E2B'  end,
NVL(SRC.CL_NAME,TGT.CL_NAME),NULL,NULL,SRC.S_CL_CODE,SRC.S_CL_DECODE,
    CASE 
        WHEN SRC.CL_NAME IS NOT NULL AND TGT.CL_NAME IS NOT NULL THEN 'Exact Match'
        WHEN SRC.CL_NAME IS NOT NULL THEN 'Only in Source'
        ELSE 'Only in Target'
    END AS MAPPING_TYPE,TGT.T_CL_CODE,TGT.T_CL_DECODE,TGT.T_CL_E2B_CODE,TGT.T_A2_DECODE,
    CASE 
        WHEN SRC.S_CL_CODE IS NOT NULL THEN 'Non_E2B Codelist Mapping using Tgt Code'
        when NVL(SRC.CL_NAME,TGT.CL_NAME )='Formulation' THEN 'E2B Mapping of formulation using only s_cl_decode and Tgt Decode'
       ELSE  'Non_E2B Codelist Mapping using Tgt decode' END
FROM SRC2 SRC
FULL OUTER JOIN  (select * from MG_T_CL_INFO where cl_name <> 'Dose Units' )  TGT
ON (
    UPPER(TRIM(SRC.CL_NAME)) = UPPER(TRIM(TGT.CL_NAME))
    AND (
        (SRC.S_CL_CODE IS NOT NULL 
            AND UPPER(LTRIM(TRIM(SRC.S_CL_CODE),'0')) = UPPER(LTRIM(TRIM(TGT.T_CL_E2B_CODE),'0')))
        OR
        (SRC.S_CL_CODE IS NULL 
            AND UPPER(TRIM(SRC.S_CL_DECODE)) = UPPER(TRIM(TGT.T_CL_DECODE)))
    ))*/
;

COMMIT;
-- Table Population Logic Ends Here

-- Log End Time
SELECT TO_CHAR( SYSDATE, 'DD-MON-YYYY HH24:MI:SS' ) END_TIME FROM DUAL;

-- Echo Off
SET ECHO OFF;

-- Spool Off
SPOOL OFF;

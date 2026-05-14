create or replace PACKAGE BODY pkg_mg_util AS

    PROCEDURE p_mg_log_message (
        pi_scase_num    IN VARCHAR2,
        pi_tcase_id     IN NUMBER,
        pi_message_type IN VARCHAR2,
        pi_message      IN CLOB,
        pi_thread_id    IN NUMBER DEFAULT NULL,
        pi_date_time    IN TIMESTAMP
    ) IS
    BEGIN
        INSERT INTO mg_case_error_log (
            scase_num,
            tcase_id,
            message_type,
            message,
            thread_id,
            date_and_time
        ) VALUES ( pi_scase_num,
                   pi_tcase_id,
                   pi_message_type,
                   pi_message,
                   pi_thread_id,
                   pi_date_time );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
       -- rollback;
           dbms_output.put_line('Failed to log error in P_MG_LOG_MESSAGE: ' || sqlerrm);
    END p_mg_log_message;

    FUNCTION f_mg_codelist_code (
        pi_cl_type         IN VARCHAR2,
        pi_cl_name         IN VARCHAR2,
        pi_scodelist_value IN VARCHAR2
    ) RETURN NUMBER IS
        v_is_numeric BOOLEAN;
        t_code       NUMBER;
    BEGIN
        IF pi_scodelist_value IS NULL THEN
            RETURN NULL;
        END IF;
        v_is_numeric := regexp_like(
            trim(pi_scodelist_value),
            '^\d+$'
        );
        IF
            pi_cl_type = 'E2B'
            AND v_is_numeric
        THEN
            SELECT
                t_cl_code
            INTO t_code
            FROM
                mg_codelist_map
            WHERE
                    s_cl_e2b_code = pi_scodelist_value
                AND cl_name = pi_cl_name;

        ELSIF
            pi_cl_type = 'E2B'
            AND NOT v_is_numeric
        THEN
            SELECT
                t_cl_code
            INTO t_code
            FROM
                mg_codelist_map
            WHERE
                    s_cl_e2b_decode = pi_scodelist_value
                AND cl_name = pi_cl_name;

        ELSIF v_is_numeric THEN
            SELECT
                t_cl_code
            INTO t_code
            FROM
                mg_codelist_map
            WHERE
                    s_cl_code = pi_scodelist_value
                AND cl_name = pi_cl_name;

        ELSE
            SELECT
                t_cl_code
            INTO t_code
            FROM
                mg_codelist_map
            WHERE
                    s_cl_decode = pi_scodelist_value
                AND cl_name = pi_cl_name;

        END IF;

        IF t_code IS NULL THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => g_scase_num,
                pi_tcase_id     => g_tcase_id,
                pi_message_type => 'WARNING',
                pi_message      => 'Target code for source value'
                              || pi_scodelist_value
                              || ' of codelist name->'
                              || pi_cl_name
                              || ' not mapped in codelist map table',
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
        END IF;

        RETURN t_code;
    EXCEPTION
        WHEN no_data_found THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => g_scase_num,
                pi_tcase_id     => g_tcase_id,
                pi_message_type => 'WARNING',
                pi_message      => 'Source Codelist Value '
                              || pi_scodelist_value
                              || ' of codelist name->'
                              || pi_cl_name
                              || ' not found in codelist map table',
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            RETURN t_code;
        WHEN too_many_rows THEN
            t_code := NULL;
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => g_scase_num,
                pi_tcase_id     => g_tcase_id,
                pi_message_type => 'WARNING',
                pi_message      => 'Source Codelist Value '
                              || pi_scodelist_value
                              || ' of codelist name->'
                              || pi_cl_name
                              || ' found multiple times in codelist map table',
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            RETURN t_code;
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => g_scase_num,
                pi_tcase_id     => g_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'Error: IN F_MG_CODELIST_CODE: ' || sqlerrm,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            RAISE;
    END f_mg_codelist_code;

    FUNCTION f_mg_seq_num (
        pi_tab_name IN VARCHAR2,
        pi_col_name IN VARCHAR2
    ) RETURN NUMBER IS
        v_seq_name tcmn_table_col_seq_relations.sequence_name%TYPE;
        v_sql      CLOB;
        v_seq_num  NUMBER := NULL;
    BEGIN
        EXECUTE IMMEDIATE 'SELECT SEQUENCE_NAME 
         FROM TCMN_TABLE_COL_SEQ_RELATIONS 
         WHERE TABLE_NAME = '''
                          || pi_tab_name
                          || ''' 
           AND COLUMN_NAME = '''
                          || pi_col_name
                          || ''''
        INTO v_seq_name;
        v_sql := 'SELECT ARGUS_APP.'
                 || v_seq_name
                 || '.NEXTVAL FROM dual';
        EXECUTE IMMEDIATE v_sql
        INTO v_seq_num;
        RETURN v_seq_num;
    EXCEPTION
        WHEN no_data_found THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => g_scase_num,
                pi_tcase_id     => g_tcase_id,
                pi_message_type => 'WARNING',
                pi_message      => 'NO SEQUENCE NAME FOUND FOR THE REQUIRED SEQUENCE IN TCMN_TABLE_COL_SEQ_RELATIONS TABLE ' || sqlerrm
                ,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            RETURN v_seq_num;
        WHEN too_many_rows THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => g_scase_num,
                pi_tcase_id     => g_tcase_id,
                pi_message_type => 'WARNING',
                pi_message      => 'MULTIPLE NMAES FOUND FOR A REQUIRED SEQUENCE IN TCMN_TABLE_COL_SEQ_RELATIONS TABLE' || sqlerrm,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            RETURN v_seq_num;
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => g_scase_num,
                pi_tcase_id     => g_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'Error: IN F_MG_SEQ_NUM: ' || sqlerrm,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
    END f_mg_seq_num;

    PROCEDURE p_mg_update_key_val IS

        CURSOR cur IS
        SELECT
            key,
            sql_query
        FROM
            mg_case_const_val;

        v_sql   mg_case_const_val.sql_query%TYPE;
        v_value mg_case_const_val.value%TYPE;
    BEGIN
        FOR rec IN cur LOOP
        begin
            v_sql := rec.sql_query;
            EXECUTE IMMEDIATE v_sql
            INTO v_value;
            EXECUTE IMMEDIATE 'UPDATE MG_CASE_CONST_VAL 
   SET VALUE = '''
                              || v_value
                              || ''' 
   WHERE KEY = '''
                              || rec.key
                              || '''';
      EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => g_scase_num,
                pi_tcase_id     => g_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'Error: IN P_MG_UPDATE_KEY_VAL ' ||rec.key||', '|| sqlerrm,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
            end;

        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => g_scase_num,
                pi_tcase_id     => g_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'Error: IN P_MG_UPDATE_KEY_VAL ' || sqlerrm,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
    END p_mg_update_key_val;

    FUNCTION f_mg_key_val (
        pi_key IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_value mg_case_const_val.value%TYPE := NULL;
    BEGIN
        SELECT
            value
        INTO v_value
        FROM
            mg_case_const_val
        WHERE
            key = pi_key;

        RETURN v_value;
    EXCEPTION
        WHEN no_data_found THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => g_scase_num,
                pi_tcase_id     => g_tcase_id,
                pi_message_type => 'WARNING',
                pi_message      => 'NO DATA FOUND CORRESSPONDING TO GIVEN KEY '
                              || pi_key
                              || '; '
                              || sqlerrm,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            RETURN v_value;
        WHEN too_many_rows THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => g_scase_num,
                pi_tcase_id     => g_tcase_id,
                pi_message_type => 'WARNING',
                pi_message      => 'MULTIPLE VALUES FOUND FOR SINGLE KEY' || sqlerrm,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            RETURN v_value;
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => g_scase_num,
                pi_tcase_id     => g_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'Error: IN F_MG_KEY_VAL: ' || sqlerrm,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
    END f_mg_key_val;

    PROCEDURE p_insert_seq_mapping (
        pi_stable_name IN VARCHAR2,
        pi_ttable_name IN VARCHAR2,
        pi_scol_name   IN VARCHAR2,
        pi_tcol_name   IN VARCHAR2,
        pi_sseq_num    IN NUMBER,
        pi_tseq_num    IN NUMBER
    ) IS
    BEGIN
        INSERT INTO mg_st_sequence_map VALUES ( pkg_mg_util.g_scase_num,
                                                pkg_mg_util.g_tcase_id,
                                                pi_stable_name,
                                                pi_ttable_name,
                                                pi_scol_name,
                                                pi_tcol_name,
                                                pi_sseq_num,
                                                pi_tseq_num );

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => g_scase_num,
                pi_tcase_id     => g_tcase_id,
                pi_message_type => 'WARNING',
                pi_message      => 'Failed to Insert in Sequence Mapping for Case Id: '
                              || pkg_mg_util.g_tcase_id
                              || ' and Table: '
                              || pi_ttable_name
                              || '; Error: '
                              || sqlerrm,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
    END p_insert_seq_mapping;

    FUNCTION f_fetch_seq_map_val (
        pi_stable_name IN VARCHAR2,
        pi_ttable_name IN VARCHAR2,
        pi_scol_name   IN VARCHAR2,
        pi_tcol_name   IN VARCHAR2,
        pi_seq_num     IN NUMBER,
        pi_seq_type    IN VARCHAR2
    ) RETURN NUMBER IS
        v_seq NUMBER := 0;
    BEGIN
        IF pi_seq_num IS NULL THEN
            RETURN NULL;
        END IF;
        v_seq := NULL;
        IF pi_seq_type = 'S' THEN
            SELECT
                sseq
            INTO v_seq
            FROM
                mg_st_sequence_map m
            WHERE
                    m.scase_num = pkg_mg_util.g_scase_num
                AND m.tcaseid = pkg_mg_util.g_tcase_id
                AND m.stablename = pi_stable_name
                AND m.ttablename = pi_ttable_name
                AND m.scolname = pi_scol_name
                AND m.tcolname = pi_tcol_name
                AND m.tseq = pi_seq_num;

        ELSIF pi_seq_type = 'T' THEN
            SELECT
                tseq
            INTO v_seq
            FROM
                mg_st_sequence_map m
            WHERE
                    m.scase_num = pkg_mg_util.g_scase_num
                AND m.tcaseid = pkg_mg_util.g_tcase_id
                AND m.stablename = pi_stable_name
                AND m.ttablename = pi_ttable_name
                AND m.scolname = pi_scol_name
                AND m.tcolname = pi_tcol_name
                AND m.sseq = pi_seq_num;

        END IF;

        RETURN v_seq;
    EXCEPTION
        WHEN no_data_found THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => g_scase_num,
                pi_tcase_id     => g_tcase_id,
                pi_message_type => 'WARNING',
                pi_message      => 'Sequence Mapping Not Found: '
                              || pkg_mg_util.g_tcase_id
                              || ' and Table: '
                              || pi_ttable_name
                              || '; Value: '
                              || pi_seq_num,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            RETURN NULL;
        WHEN too_many_rows THEN
              pkg_mg_util.p_mg_log_message(
                pi_scase_num    => g_scase_num,
                pi_tcase_id     => g_tcase_id,
                pi_message_type => 'WARNING',
                pi_message      => 'Multiple Sequence Mapping Found: '
                              || pkg_mg_util.g_tcase_id
                              || ' and Table: '
                              || pi_ttable_name
                              || '; Value: '
                              || pi_seq_num,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
          return null;
            WHEN others THEN
             pkg_mg_util.p_mg_log_message(
                pi_scase_num    => g_scase_num,
                pi_tcase_id     => g_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'ERROR OCCURED IN f_fetch_seq_map_val For case_id: '
                              || pkg_mg_util.g_tcase_id
                              || ' and Table: '
                              || pi_ttable_name
                              || '; Value: '
                              || pi_seq_num,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
    END f_fetch_seq_map_val;

    FUNCTION f_get_tgt_lic_id (
        pi_s_trade_name  IN VARCHAR2,
        pi_s_lic_num     IN VARCHAR2,
        pi_s_lic_country IN VARCHAR2,
        pi_prod_seq      NUMBER,
        pi_event_seq     NUMBER,
        pi_license_id    NUMBER
    ) RETURN NUMBER IS

        t_lic_id    NUMBER := NULL;
        v_s_country NUMBER := pkg_mg_util.f_mg_codelist_code('Non_E2B', 'Countries', pi_s_lic_country);
    BEGIN
        IF pi_s_trade_name IS NULL THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => g_scase_num,
                pi_tcase_id     => g_tcase_id,
                pi_message_type => 'WARNING',
                pi_message      => 'Trade is not present in Source for s_prod_seq:'
                              || pi_prod_seq
                              || ' and s_event_seq_num'
                              || pi_event_seq,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            RETURN t_lic_id;
        END IF;

        BEGIN
            SELECT
                license_id
            INTO t_lic_id
            FROM
                tlm_license tlc
            WHERE
                    upper(trim(tlc.trade_name)) = upper(trim(pi_s_trade_name))
               -- AND upper(trim(tlc.lic_number)) = upper(trim(pi_s_lic_num))--has to be configured.
            --    AND tlc.country_id = v_s_country
                and tlc.license_id=pi_license_id;

            IF t_lic_id IS NULL THEN--confirm this condition because either it will be configured or not->will be matched or data not found
                pkg_mg_util.p_mg_log_message(
                    pi_scase_num    => g_scase_num,
                    pi_tcase_id     => g_tcase_id,
                    pi_message_type => 'WARNING',
                    pi_message      => 'License_id is null in config',
                    pi_thread_id    => NULL,
                    pi_date_time    => systimestamp
                );

            END IF;

            RETURN t_lic_id;
        EXCEPTION
            WHEN no_data_found THEN
            BEGIN
           SELECT PROD_LIC_ID
INTO t_lic_id
FROM MG_PRODUCT_MAPPING MPM
WHERE UPPER(TRIM(NVL(MPM.SUSPECT_DRUG_NAME, MPM.MEDICINAL_PRODUCT))) 
      = UPPER(TRIM(pi_s_trade_name)) and mpm.PROD_LIC_ID is not null and rownum<=1;

            EXCEPTION
          WHEN no_data_found THEN
                pkg_mg_util.p_mg_log_message(
                    pi_scase_num    => g_scase_num,
                    pi_tcase_id     => g_tcase_id,
                    pi_message_type => 'WARNING',
                    pi_message      => 'License Not configured for this trade_name:'
                                  || pi_s_trade_name
                                  || ' having License Number:'
                                  || pi_s_lic_num
                                  || ' and Country->'
                                  || v_s_country||' and pi_license_id->'||pi_license_id,
                    pi_thread_id    => NULL,
                    pi_date_time    => systimestamp
                );
                RETURN t_lic_id;
               WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => g_scase_num,
                pi_tcase_id     => g_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'Error: IN F_GET_TGT_LIC_ID: ' || sqlerrm,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
                return t_lic_id;

  END;

                RETURN t_lic_id;
            WHEN too_many_rows THEN
                pkg_mg_util.p_mg_log_message(
                    pi_scase_num    => g_scase_num,
                    pi_tcase_id     => g_tcase_id,
                    pi_message_type => 'WARNING',
                    pi_message      => 'Multipel Licenses configured for this trade_name:'
                                  || pi_s_trade_name
                                  || ' having License Number:'
                                  || pi_s_lic_num
                                  || ' and Country->'
                                  || v_s_country,
                    pi_thread_id    => NULL,
                    pi_date_time    => systimestamp
                );
        --what to return from here.
        END;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => g_scase_num,
                pi_tcase_id     => g_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'Error: IN F_GET_TGT_LIC_ID: ' || sqlerrm,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
    END f_get_tgt_lic_id;

      FUNCTION f_var_to_date (
        pi_table_name     IN VARCHAR2,
        pi_date_format    IN NUMBER,
        pi_date_in_number IN VARCHAR2
    )RETURN DATE IS
     v_value VARCHAR2(50);
    po_date DATE := NULL;
    BEGIN
        IF pi_date_in_number IS NULL THEN
            po_date := NULL;
            RETURN po_date;
        END IF;

IF VALIDATE_CONVERSION((PI_DATE_IN_NUMBER) AS DATE,'DD-MM-RR') = 1 THEN--exception partial date mapping

   po_date := TO_DATE ( PI_DATE_IN_NUMBER, 'DD-MM-RR' );
   RETURN po_date;
END IF;
   v_value         := TRIM(TO_CHAR(PI_DATE_IN_NUMBER));
    /*first use format if present*/
        IF pi_date_format IS NOT NULL THEN
            IF pi_date_format = 602 THEN
                po_date := TO_DATE ( v_value, 'YYYY' );
            ELSIF pi_date_format = 610 THEN
                po_date := TO_DATE ( v_value, 'YYYYMM' );
            ELSIF pi_date_format = 102 THEN
                po_date := TO_DATE ( v_value, 'YYYYMMDD' );
            ELSIF pi_date_format = 203 THEN
                po_date := TO_DATE ( v_value, 'YYYYMMDDHH24MI' );
            ELSE
                po_date := NULL;
            END IF;

 /*use length if format not present*/
        ELSE
            IF length(v_value) = 4 THEN
                po_date := TO_DATE ( v_value, 'YYYY' );
            ELSIF length(v_value) = 6 THEN
                po_date := TO_DATE ( v_value, 'YYYYMM' );

            ELSIF length(v_value) = 8 THEN
                po_date := TO_DATE ( v_value, 'YYYYMMDD' );
            ELSIF length(v_value) = 12 THEN
                po_date := TO_DATE ( v_value, 'YYYYMMDDHH24MI' );
            ELSE
                po_date := NULL;
            END IF;
        END IF;

    RETURN PO_DATE;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => pkg_mg_util.g_scase_num,
                pi_tcase_id     => pkg_mg_util.g_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'Error: IN f_var_to_date Called from table'
                              || pi_table_name
                              || ':'
                              || sqlerrm,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
    END f_var_to_date;

    FUNCTION f_get_firsr_sus_product (
        pi_tcase_id            IN NUMBER,
        pi_case_num            IN VARCHAR2,
        pi_prod_name           IN VARCHAR2,
        pi_drug_name           IN VARCHAR2,
        pi_argus_display_order IN NUMBER
    ) RETURN NUMBER IS

        v_sus_flag       NUMBER := 0;
        v_mIN_drug_id    NUMBER := 0;
        v_prod_cnt       NUMBER := 0;
        v_drug_cnt       NUMBER := 0;
        v_min_drug_check NUMBER := 0;
    BEGIN

        SELECT
            COUNT(1)
        INTO v_prod_cnt
        FROM
            s_caseproductlevel
        WHERE
                case_number = pi_case_num
            AND upper(trim(suspect_drug_name)) = upper(trim(pi_prod_name));

        SELECT
            COUNT(1)
        INTO v_drug_cnt
        FROM
            s_drug
        WHERE
                drugcharacterization = 1
            AND case_number = pi_case_num
            AND upper(trim(medicinalproduct)) = upper(trim(pi_drug_name));

        SELECT
            MIN(drug_seq)
        INTO v_mIN_drug_id
        FROM
            s_drug
        WHERE
            case_number = pi_case_num and drugcharacterization = 1;

        SELECT
            CASE
                WHEN EXISTS (
                    SELECT
                        1
                    FROM
                        s_drug
                    WHERE
                            case_number = pi_case_num
                        AND upper(trim(medicinalproduct)) = upper(trim(pi_drug_name))
                        AND drug_seq = v_MIN_drug_id
                ) THEN
                    1
                ELSE
                    0
            END
        INTO v_min_drug_check
        FROM
            dual;

        IF v_prod_cnt = 1 THEN
            v_sus_flag := 1;
        ELSIF
            v_prod_cnt > 1
            AND pi_argus_display_order = 1
        THEN
            v_sus_flag := 1;
        ELSIF v_drug_cnt = 1 THEN
            v_sus_flag := 1;
        ELSIF
            v_drug_cnt > 1
            AND v_min_drug_check = 1
        THEN
            v_sus_flag := 1;
        ELSE
            v_sus_flag := 0;
        END IF;

        RETURN v_sus_flag;


    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => g_scase_num,
                pi_tcase_id     => g_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'Error: IN F_GET_FIRSR_SUS_PRODUCT: ' || sqlerrm,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
    END f_get_firsr_sus_product;


FUNCTION F_GET_TGT_PROD_ID (PI_CASE_NUM IN varchar2,PI_S_prod_seq_num in number) return number is 
t_prod_id number:=null;
begin

--SELECT TGT_PROD_ID INTO t_prod_id FROM MG_CASE_PROD_MAPP MCPM 
--INNER JOIN MG_PRODUCT_MAPPING MPM ON MCPM.PM_ID=MPM.PM_ID WHERE
--MCPM.CASE_NUMBER=pi_case_num ;

RETURN t_prod_id;
EXCEPTION
        WHEN no_data_found THEN

            pkg_mg_util.p_mg_log_message(
                pi_scase_num     => pkg_mg_util.g_scase_num,
                pi_tcase_id     => pkg_mg_util.g_tcase_id,
                pi_message_type => 'WARNING',
                pi_message      => 'Product Mapping Not found',
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
            RETURN t_prod_id;
end;

FUNCTION F_GET_DRUG_ID (
    PI_drugcharacterization      IN VARCHAR2,
    PI_obtaindrugcountry         IN VARCHAR2,
    PI_drugadditional            IN VARCHAR2,
    PI_drugauthorizationnumb     IN VARCHAR2,
    PI_drugauthorizationholder   IN VARCHAR2,
    PI_actiondrug                IN VARCHAR2,
    PI_drugcumulativedosageunit  IN VARCHAR2,
    PI_drugauthorizationcountry  IN VARCHAR2,
    PI_drugcumulativedosagenum   IN VARCHAR2,
    PI_case_num                  IN VARCHAR2,
    PI_medicinalproduct          IN VARCHAR2,
    PI_drugstartperiod           IN VARCHAR2
) RETURN NUMBER
IS
V_DRUG_ID NUMBER:=NULL;
BEGIN

BEGIN
SELECT drug_seq
INTO v_drug_id
FROM s_drug sd
WHERE (sd.drugcharacterization = PI_drugcharacterization
       OR PI_drugcharacterization IS NULL)

  AND (UPPER(TRIM(sd.obtaindrugcountry)) =
       UPPER(TRIM(PI_obtaindrugcountry))
       OR PI_obtaindrugcountry IS NULL)

  AND (sd.drugadditional = PI_drugadditional
       OR PI_drugadditional IS NULL)

  AND (sd.drugauthorizationnumb = PI_drugauthorizationnumb
       OR PI_drugauthorizationnumb IS NULL)

  AND (UPPER(TRIM(sd.drugauthorizationholder)) =
       UPPER(TRIM(PI_drugauthorizationholder))
       OR PI_drugauthorizationholder IS NULL)

  AND (sd.actiondrug = PI_actiondrug
       OR PI_actiondrug IS NULL)

  AND (sd.drugcumulativedosageunit = PI_drugcumulativedosageunit
       OR PI_drugcumulativedosageunit IS NULL)

  AND (UPPER(TRIM(sd.drugauthorizationcountry)) =
       UPPER(TRIM(PI_drugauthorizationcountry))
       OR PI_drugauthorizationcountry IS NULL)

  AND (sd.drugcumulativedosagenumb = PI_drugcumulativedosagenum
       OR PI_drugcumulativedosagenum IS NULL)

  AND (UPPER(TRIM(sd.case_number)) =
       UPPER(TRIM(PI_case_num))
       OR PI_case_num IS NULL)

  AND (UPPER(TRIM(sd.medicinalproduct)) =
       UPPER(TRIM(PI_medicinalproduct))
       OR PI_medicinalproduct IS NULL)

  AND (sd.drugstartperiod = PI_drugstartperiod
       OR PI_drugstartperiod IS NULL);


    RETURN v_drug_id;
EXCEPTION 
 WHEN NO_DATA_FOUND THEN
 pkg_mg_util.p_mg_log_message(
                pi_scase_num     => pkg_mg_util.g_scase_num,
                pi_tcase_id     => pkg_mg_util.g_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'DRUG ID not found for case_num:'||pi_case_num||' and medicinal product:'||PI_medicinalproduct,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
            RETURN v_drug_id;
WHEN TOO_MANY_ROWS THEN
SELECT drug_seq
INTO v_drug_id
FROM s_drug sd
WHERE (sd.drugcharacterization = PI_drugcharacterization
       OR PI_drugcharacterization IS NULL)

  AND (UPPER(TRIM(sd.obtaindrugcountry)) =
       UPPER(TRIM(PI_obtaindrugcountry))
       OR PI_obtaindrugcountry IS NULL)

  AND (sd.drugadditional = PI_drugadditional
       OR PI_drugadditional IS NULL)

  AND (sd.drugauthorizationnumb = PI_drugauthorizationnumb
       OR PI_drugauthorizationnumb IS NULL)

  AND (UPPER(TRIM(sd.drugauthorizationholder)) =
       UPPER(TRIM(PI_drugauthorizationholder))
       OR PI_drugauthorizationholder IS NULL)

  AND (sd.actiondrug = PI_actiondrug
       OR PI_actiondrug IS NULL)

  AND (sd.drugcumulativedosageunit = PI_drugcumulativedosageunit
       OR PI_drugcumulativedosageunit IS NULL)

  AND (UPPER(TRIM(sd.drugauthorizationcountry)) =
       UPPER(TRIM(PI_drugauthorizationcountry))
       OR PI_drugauthorizationcountry IS NULL)

  AND (sd.drugcumulativedosagenumb = PI_drugcumulativedosagenum
       OR PI_drugcumulativedosagenum IS NULL)

  AND (UPPER(TRIM(sd.case_number)) =
       UPPER(TRIM(PI_case_num))
       OR PI_case_num IS NULL)

  AND (UPPER(TRIM(sd.medicinalproduct)) =
       UPPER(TRIM(PI_medicinalproduct))
       OR PI_medicinalproduct IS NULL)

  AND (sd.drugstartperiod = PI_drugstartperiod
       OR PI_drugstartperiod IS NULL)
 AND ROWNUM<=1 ORDER BY DRUG_SEQ ASC ;
      RETURN v_drug_id;
END;
EXCEPTION 
WHEN OTHERS THEN
 pkg_mg_util.p_mg_log_message(
                pi_scase_num     => pkg_mg_util.g_scase_num,
                pi_tcase_id     => pkg_mg_util.g_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'Error in function: F_GET_DRUG_ID'|| sqlerrm,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
            return null;
END F_GET_DRUG_ID;

FUNCTION f_convert_to_seconds (
    pi_duration        IN NUMBER,
    pi_duration_unit   IN NUMBER
) RETURN NUMBER
IS
    v_seconds NUMBER;
BEGIN
    v_seconds :=
        CASE pi_duration_unit
            WHEN 807 THEN pi_duration                                   -- Seconds
            WHEN 806 THEN pi_duration * 60                              -- Minutes
            WHEN 805 THEN pi_duration * 60 * 60                         -- Hours
            WHEN 804 THEN pi_duration * 60 * 60 * 24                    -- Days
            WHEN 803 THEN pi_duration * 60 * 60 * 24 * 7                -- Weeks
            WHEN 802 THEN pi_duration * 60 * 60 * 24 * 30               -- Months (30 days approx)
            WHEN 801 THEN pi_duration * 60 * 60 * 24 * 365              -- Years (approx)
            ELSE NULL
        END;

    RETURN v_seconds;
END f_convert_to_seconds;

    FUNCTION f_mg_VIEWS_AVAILABLE (
        pi_product_id IN NUMBER
    ) RETURN NUMBER IS
        v_VIEWS_AVAILABLE NUMBER := 7;
        v_lic_type  VARCHAR(1000) := NULL;
    BEGIN
        IF pi_product_id IS NULL THEN--non company product
            RETURN v_VIEWS_AVAILABLE;
        END IF;
        SELECT
            LISTAGG(DISTINCT upper(tlt.license_type),
                             ',')
        INTO v_lic_type
        FROM
                 tlm_lic_products tllp
            INNER JOIN tlm_license       tll ON tllp.license_id = tll.license_id
            INNER JOIN tlm_license_types tlt ON tll.license_type_id = tlt.license_type_id where tllp.product_id=pi_product_id;
IF    instr(v_lic_type, 'DRUG')    > 0
  AND instr(v_lic_type, 'DEVICE')  > 0
  AND instr(v_lic_type, 'VACCINE') > 0
THEN
    v_VIEWS_AVAILABLE := 7;

ELSIF instr(v_lic_type, 'DEVICE')  > 0
  AND instr(v_lic_type, 'VACCINE') > 0
THEN
    v_VIEWS_AVAILABLE := 6;

ELSIF instr(v_lic_type, 'DRUG')    > 0
  AND instr(v_lic_type, 'VACCINE') > 0
THEN
    v_VIEWS_AVAILABLE := 5;

ELSIF instr(v_lic_type, 'DRUG')    > 0
  AND instr(v_lic_type, 'DEVICE')  > 0
THEN
    v_VIEWS_AVAILABLE := 4;

ELSIF instr(v_lic_type, 'VACCINE') > 0 THEN
    v_VIEWS_AVAILABLE := 3;

ELSIF instr(v_lic_type, 'DEVICE') > 0 THEN
    v_VIEWS_AVAILABLE := 2;

ELSIF instr(v_lic_type, 'DRUG') > 0 THEN
    v_VIEWS_AVAILABLE := 1;

END IF;

        RETURN v_VIEWS_AVAILABLE;
    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => pkg_mg_util.g_scase_num,
                pi_tcase_id     => pkg_mg_util.g_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'Error in function: F_MG_VIEWS_AVAILABLE' || sqlerrm,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            RETURN v_VIEWS_AVAILABLE;
    END f_mg_VIEWS_AVAILABLE;

END pkg_mg_util;

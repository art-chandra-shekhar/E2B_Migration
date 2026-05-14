create or replace PACKAGE pkg_mg_util IS

g_scase_num VARCHAR2(150);
g_tcase_id NUMBER; 
g_study_key VARCHAR2(150);
FUNCTION f_mg_codelist_code (
    pi_cl_type         IN VARCHAR2,
    pi_cl_name         IN VARCHAR2,
    pi_scodelist_value IN VARCHAR2
) RETURN NUMBER;
    PROCEDURE p_mg_log_message (
        pi_scase_num    IN VARCHAR2,
        pi_tcase_id     IN NUMBER,
        pi_message_type IN VARCHAR2,
        pi_message      IN CLOB,
        pi_thread_id    IN NUMBER DEFAULT NULL,
        pi_date_time    IN TIMESTAMP
    );

    FUNCTION f_mg_seq_num (
        pi_tab_name IN VARCHAR2,
        pi_col_name IN VARCHAR2
    ) RETURN NUMBER;

    PROCEDURE p_mg_update_key_val;

    FUNCTION f_mg_key_val (
        pi_key IN VARCHAR2
    ) RETURN VARCHAR2;


    PROCEDURE p_insert_seq_mapping (
        pi_stable_name IN VARCHAR2,
        pi_ttable_name IN VARCHAR2,
        pi_scol_name   IN VARCHAR2,
        pi_tcol_name   IN VARCHAR2,
        pi_sseq_num    IN NUMBER,
        pi_tseq_num    IN NUMBER
    );
    
   

    FUNCTION f_fetch_seq_map_val (
        pi_stable_name IN VARCHAR2,
        pi_ttable_name IN VARCHAR2,
        pi_scol_name   IN VARCHAR2,
        pi_tcol_name   IN VARCHAR2,
        pi_seq_num     IN NUMBER,
        pi_seq_type    IN VARCHAR2
    ) RETURN NUMBER;
    
    FUNCTION f_get_tgt_lic_id (
        pi_s_trade_name  IN VARCHAR2,
        pi_s_lic_num     IN VARCHAR2,
        pi_s_lic_country IN VARCHAR2
        ,
        pi_prod_seq number,
        pi_event_seq number,
        pi_license_id number
    ) RETURN NUMBER;
      FUNCTION f_var_to_date (
        pi_table_name     IN VARCHAR2,
        pi_date_format    IN NUMBER,
        pi_date_in_number IN VARCHAR2
    )RETURN DATE;
        
         FUNCTION f_get_firsr_sus_product (
    pi_tcase_id            IN NUMBER,
    pi_case_num            IN VARCHAR2,
    pi_prod_name           IN VARCHAR2,
    pi_drug_name           IN VARCHAR2,
    pi_argus_display_order IN NUMBER
) RETURN NUMBER;

FUNCTION F_GET_TGT_PROD_ID (PI_CASE_NUM IN varchar2,PI_S_prod_seq_num in number) return number;
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
) RETURN NUMBER;

FUNCTION f_convert_to_seconds (
    pi_duration        IN NUMBER,
    pi_duration_unit   IN NUMBER
) RETURN NUMBER;
FUNCTION f_mg_VIEWS_AVAILABLE (
        pi_product_id IN NUMBER
    ) RETURN NUMBER ;
    

END pkg_mg_util;
/
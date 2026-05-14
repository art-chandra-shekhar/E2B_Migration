create or replace PACKAGE pkg_mg_buss_rules IS

 PROCEDURE p_meddra_map_br001 (
        pi_source        IN VARCHAR2,
        pi_llt_name      IN VARCHAR2,
        pi_pref_term     IN VARCHAR2,
        pi_reported_term IN VARCHAR2,
        po_llt_code      OUT NUMBER,
        po_llt_name      OUT VARCHAR2,
        po_pt_code       OUT NUMBER,
        po_pt_name       OUT VARCHAR2,
        po_hlt_code      OUT NUMBER,
        po_hlt_name      OUT VARCHAR2,
        po_hlgt_code     OUT NUMBER,
        po_hlgt_name     OUT VARCHAR2,
        po_soc_code      OUT NUMBER,
        po_soc_name      OUT VARCHAR2,
        po_code_status   OUT NUMBER,
        po_dict_id       OUT NUMBER
    );

PROCEDURE P_GET_PARTIAL_DATE(pi_table_name IN VARCHAR2,
 pI_DATE_FORMAT  IN NUMBER,
    pi_date_IN_NUMBER   IN VARCHAR2,
    po_date out Date,
    Po_date_res OUT NUMBER,
    PO_DATE_PARTIAL OUT VARCHAR2);
     procedure p_GET_TGT_PROD_ID (PI_suspect_drug_name IN VARCHAR2,
        PI_medicinalproduct IN VARCHAR2,
         PI_drugdosageform IN VARCHAR2,
          PI_drugauthorizationcountry IN VARCHAR2,
           PI_drugauthorizationnumb IN VARCHAR2,
            PI_suspect_product_generic_name IN VARCHAR2,
        po_tgt_prod_id     OUT NUMBER,
        po_tgt_prod_lic_id OUT NUMBER) ;
     
     
       PROCEDURE P_MG_FIRST_LAST_DOSE_CALC(
PI_FIRST_DOSE IN DATE,
PI_LAST_DOSE IN DATE,
PI_START_DATE IN DATE,
PI_START_DATE_RES IN NUMBER,
PI_START_DATE_PARTIAL IN VARCHAR2,
PI_STOP_DATE IN DATE,
PI_STOP_DATE_RES IN NUMBER,
PI_STOP_DATE_PARTIAL IN VARCHAR2,
PO_FIRST_DOSE OUT DATE,
PO_FIRST_DOSE_RES OUT NUMBER,
PO_FIRST_DOSE_PARTIAL OUT VARCHAR2,
PO_LAST_DOSE OUT DATE,
PO_LAST_DOSE_RES OUT NUMBER,
PO_LAST_DOSE_PARTIAL OUT VARCHAR2
);

procedure p_GET_TGT_STUDY_PROD_ID(
pi_drug_seq_num NUMBER,
pi_study_key NUMBER,
pi_cohort_id NUMBER,
pi_medicinalproduct IN VARCHAR2,
pi_drugdosageform IN VARCHAR2,
pi_drugauthorizationNUMB IN VARCHAR2,
pi_drugauthorizationcountry IN VARCHAR2,
PI_SUSPECT_DRUG_NAME IN VARCHAR2,
PI_GENeRIC_NAME IN VARCHAR2,
po_TGT_PROD_ID out number,
po_TGT_PROD_LIC_ID out number
);
PROCEDURE P_MG_STUDY_MAPPING(pi_studyname IN VARCHAR2,
pi_sponsorstudynumb IN VARCHAR2,
                  pi_observestudytype IN VARCHAR2,
 po_cohort_id         OUT NUMBER,
    po_study_key         OUT NUMBER,
    po_blind_name        OUT VARCHAR2,
    po_blind_name_j      OUT VARCHAR2,
    po_study_type        OUT NUMBER,
    po_study_num         OUT VARCHAR2,
    po_study_num_j   OUT VARCHAR2,
    po_protocol_num      OUT VARCHAR2,
    po_classification_id OUT NUMBER,
    po_protocol_id       OUT NUMBER,
    po_study_desc        OUT CLOB,
    po_study_desc_j      OUT CLOB,
    po_dev_phase_id      OUT NUMBER
);

 PROCEDURE p_tgt_ingredient_id(
         pi_ingredient_NAME IN varchar2,
        po_ingredient_id OUT NUMBER
    ) ;
     
         PROCEDURE p_get_body_sys_event (
        po_body_sys  OUT VARCHAR2,
        po_pri_event OUT VARCHAR2
    );
end pkg_mg_buss_rules;
/
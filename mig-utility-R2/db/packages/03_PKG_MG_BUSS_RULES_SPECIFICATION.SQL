CREATE OR REPLACE PACKAGE pkg_mg_buss_rules IS
    PROCEDURE p_meddra_map_code (
        pi_source        IN VARCHAR2,
        pi_llt_code      IN NUMBER,
        pi_pt_code       IN NUMBER,
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

    PROCEDURE p_get_partial_date (
        pi_table_name     IN VARCHAR2,
        pi_date_format    IN NUMBER,
        pi_date_in_number IN VARCHAR2,
        po_date           OUT DATE,
        po_date_res       OUT NUMBER,
        po_date_partial   OUT VARCHAR2
    );

    PROCEDURE p_get_tgt_prod_id (
        pi_suspect_drug_name            IN VARCHAR2,
        pi_medicinalproduct             IN VARCHAR2,
        pi_drugdosageform               IN VARCHAR2,
        pi_drugauthorizationcountry     IN VARCHAR2,
        pi_drugauthorizationnumb        IN VARCHAR2,
        pi_suspect_product_generic_name IN VARCHAR2,
        po_tgt_prod_id                  OUT NUMBER,
        po_tgt_prod_lic_id              OUT NUMBER
    );

    PROCEDURE p_mg_first_last_dose_calc (
        pi_first_dose         IN DATE,
        pi_last_dose          IN DATE,
        pi_start_date         IN DATE,
        pi_start_date_res     IN NUMBER,
        pi_start_date_partial IN VARCHAR2,
        pi_stop_date          IN DATE,
        pi_stop_date_res      IN NUMBER,
        pi_stop_date_partial  IN VARCHAR2,
        po_first_dose         OUT DATE,
        po_first_dose_res     OUT NUMBER,
        po_first_dose_partial OUT VARCHAR2,
        po_last_dose          OUT DATE,
        po_last_dose_res      OUT NUMBER,
        po_last_dose_partial  OUT VARCHAR2
    );

    PROCEDURE p_get_tgt_study_prod_id (
        pi_drug_seq_num             NUMBER,
        pi_study_key                NUMBER,
        pi_cohort_id                NUMBER,
        pi_medicinalproduct         IN VARCHAR2,
        pi_drugdosageform           IN VARCHAR2,
        pi_drugauthorizationnumb    IN VARCHAR2,
        pi_drugauthorizationcountry IN VARCHAR2,
        pi_suspect_drug_name        IN VARCHAR2,
        pi_generic_name             IN VARCHAR2,
        po_tgt_prod_id              OUT NUMBER,
        po_tgt_prod_lic_id          OUT NUMBER
    );

    PROCEDURE p_mg_study_mapping (
        pi_studyname         IN VARCHAR2,
        pi_sponsorstudynumb  IN VARCHAR2,
        pi_observestudytype  IN VARCHAR2,
        po_cohort_id         OUT NUMBER,
        po_study_key         OUT NUMBER,
        po_blind_name        OUT VARCHAR2,
        po_blind_name_j      OUT VARCHAR2,
        po_study_type        OUT NUMBER,
        po_study_num         OUT VARCHAR2,
        po_study_num_j       OUT VARCHAR2,
        po_protocol_num      OUT VARCHAR2,
        po_classification_id OUT NUMBER,
        po_protocol_id       OUT NUMBER,
        po_study_desc        OUT CLOB,
        po_study_desc_j      OUT CLOB,
        po_dev_phase_id      OUT NUMBER
    );

    PROCEDURE p_tgt_ingredient_id (
        pi_ingredient_name IN VARCHAR2,
        po_ingredient_id   OUT NUMBER
    );

    PROCEDURE p_get_body_sys_event (
        po_body_sys  OUT VARCHAR2,
        po_pri_event OUT VARCHAR2
    );

END pkg_mg_buss_rules;
/
create or replace PACKAGE BODY pkg_mg_buss_rules IS

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
    ) AS
    BEGIN
        BEGIN
            SELECT
                mmh.soc_code,
                mmh.soc_name,
                mmh.hlgt_code,
                mmh.hlgt_name,
                mmh.hlt_code,
                mmh.hlt_name,
                mmh.pt_code,
                mmh.pt_name,
                mptl.llt_code,
                mptl.llt_name_english
            INTO
                po_soc_code,
                po_soc_name,
                po_hlgt_code,
                po_hlgt_name,
                po_hlt_code,
                po_hlt_name,
                po_pt_code,
                po_pt_name,
                po_llt_code,
                po_llt_name
            FROM
                tmeddra_md_hierarchy  mmh,
                tmeddra_pref_term_llt mptl
            WHERE
                    mmh.pt_code = mptl.pt_code
                AND mptl.llt_code = pi_llt_code
                AND mmh.pt_code = pi_pt_code
                AND mmh.primary_soc_fg = 'Y'
                AND mptl.llt_currency = 'Y';
 
            po_dict_id := pkg_mg_util.f_mg_key_val('MedDRA Dict Id');
            po_code_status := 1;
        EXCEPTION
            WHEN no_data_found OR too_many_rows THEN
                po_code_status := 0;
                po_dict_id := NULL;
        END;
 
        IF po_code_status = 0 THEN
            BEGIN
                SELECT
                    mmh.soc_code,
                    mmh.soc_name,
                    mmh.hlgt_code,
                    mmh.hlgt_name,
                    mmh.hlt_code,
                    mmh.hlt_name,
                    mmh.pt_code,
                    mmh.pt_name,
                    mptl.llt_code,
                    mptl.llt_name_english
                INTO
                    po_soc_code,
                    po_soc_name,
                    po_hlgt_code,
                    po_hlgt_name,
                    po_hlt_code,
                    po_hlt_name,
                    po_pt_code,
                    po_pt_name,
                    po_llt_code,
                    po_llt_name
                FROM
                    tmeddra_md_hierarchy  mmh,
                    tmeddra_pref_term_llt mptl
                WHERE
                        mmh.pt_code = mptl.pt_code
                    AND mptl.llt_code = pi_llt_code
                  --AND mmh.pt_code  = pi_pt_code
                    AND mmh.primary_soc_fg = 'Y'
                    AND mptl.llt_currency = 'Y';
 
                po_dict_id := pkg_mg_util.f_mg_key_val('MedDRA Dict Id');
                po_code_status := 1;
            EXCEPTION
                WHEN no_data_found OR too_many_rows THEN
                    po_code_status := 0;
                    po_dict_id := NULL;
            END;
 
        END IF;
 
        IF
            po_code_status = 0
            AND pi_llt_name IS NOT NULL
        THEN
            BEGIN
                SELECT
                    mmh.soc_code,
                    mmh.soc_name,
                    mmh.hlgt_code,
                    mmh.hlgt_name,
                    mmh.hlt_code,
                    mmh.hlt_name,
                    mmh.pt_code,
                    mmh.pt_name,
                    mptl.llt_code,
                    mptl.llt_name_english
                INTO
                    po_soc_code,
                    po_soc_name,
                    po_hlgt_code,
                    po_hlgt_name,
                    po_hlt_code,
                    po_hlt_name,
                    po_pt_code,
                    po_pt_name,
                    po_llt_code,
                    po_llt_name
                FROM
                    tmeddra_md_hierarchy  mmh,
                    tmeddra_pref_term_llt mptl
                WHERE
                        mmh.pt_code = mptl.pt_code
                    AND upper(trim(mptl.llt_name_english)) = upper(trim(pi_llt_name))
--                  AND mmh.pt_code  = pi_pt_code
                    AND mmh.primary_soc_fg = 'Y'
                    AND mptl.llt_currency = 'Y';
 
                po_dict_id := pkg_mg_util.f_mg_key_val('MedDRA Dict Id');
                po_code_status := 1;
            EXCEPTION
                WHEN no_data_found OR too_many_rows THEN
                    po_code_status := 0;
                    po_dict_id := NULL;
            END;
        END IF;
 
        IF
            po_code_status = 0
            AND pi_pref_term IS NOT NULL
        THEN
            BEGIN
                SELECT
                    mmh.soc_code,
                    mmh.soc_name,
                    mmh.hlgt_code,
                    mmh.hlgt_name,
                    mmh.hlt_code,
                    mmh.hlt_name,
                    mmh.pt_code,
                    mmh.pt_name,
                    mptl.llt_code,
                    mptl.llt_name_english
                INTO
                    po_soc_code,
                    po_soc_name,
                    po_hlgt_code,
                    po_hlgt_name,
                    po_hlt_code,
                    po_hlt_name,
                    po_pt_code,
                    po_pt_name,
                    po_llt_code,
                    po_llt_name
                FROM
                    tmeddra_md_hierarchy  mmh,
                    tmeddra_pref_term_llt mptl
                WHERE
                        mmh.pt_code = mptl.pt_code
                    AND upper(trim(mmh.pt_name)) = upper(trim(pi_pref_term))
--                  AND mmh.pt_code  = pi_pt_code
                    AND mmh.primary_soc_fg = 'Y'
                    AND mptl.llt_currency = 'Y';
 
                po_dict_id := pkg_mg_util.f_mg_key_val('MedDRA Dict Id');
                po_code_status := 1;
            EXCEPTION
                WHEN no_data_found OR too_many_rows THEN
                    po_code_status := 0;
                    po_dict_id := NULL;
            END;
        END IF;
 
    EXCEPTION
        WHEN no_data_found THEN
            po_code_status := 0;
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => pkg_mg_util.g_scase_num,
                pi_tcase_id     => pkg_mg_util.g_tcase_id,
                pi_message_type => 'WARNING',
                pi_message      => 'MedDRA Mapping Not Found - LLT Code For Source->'
                              || pi_source
                              || ' in'
                              || pi_llt_name
                              || ', PT Code'
                              || pi_pref_term,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
 
 
        WHEN OTHERS THEN
            raise_application_error(-20003, NULL);
    END p_meddra_map_code;
    
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
    ) AS
    BEGIN
        BEGIN
            SELECT
                mmh.soc_code,
                mmh.soc_name,
                mmh.hlgt_code,
                mmh.hlgt_name,
                mmh.hlt_code,
                mmh.hlt_name,
                mmh.pt_code,
                mmh.pt_name,
                mptl.llt_code,
                mptl.llt_name_english
            INTO
                po_soc_code,
                po_soc_name,
                po_hlgt_code,
                po_hlgt_name,
                po_hlt_code,
                po_hlt_name,
                po_pt_code,
                po_pt_name,
                po_llt_code,
                po_llt_name
            FROM
                tmeddra_md_hierarchy  mmh,
                tmeddra_pref_term_llt mptl
            WHERE
                    mmh.pt_code = mptl.pt_code
                AND upper(trim(mptl.llt_name_english)) = upper(trim(pi_llt_name))
                AND upper(trim(mmh.pt_name)) = upper(trim(pi_pref_term))
                AND mmh.primary_soc_fg = 'Y'
                AND mptl.llt_currency = 'Y';

            po_dict_id := pkg_mg_util.f_mg_key_val('MedDRA Dict Id');
            po_code_status := 1;
        EXCEPTION
            WHEN no_data_found OR too_many_rows THEN
                po_code_status := 0;
                po_dict_id := NULL;
        END;

        IF po_code_status = 0 THEN
            BEGIN
                SELECT
                    mmh.soc_code,
                    mmh.soc_name,
                    mmh.hlgt_code,
                    mmh.hlgt_name,
                    mmh.hlt_code,
                    mmh.hlt_name,
                    mmh.pt_code,
                    mmh.pt_name,
                    mptl.llt_code,
                    mptl.llt_name_english
                INTO
                    po_soc_code,
                    po_soc_name,
                    po_hlgt_code,
                    po_hlgt_name,
                    po_hlt_code,
                    po_hlt_name,
                    po_pt_code,
                    po_pt_name,
                    po_llt_code,
                    po_llt_name
                FROM
                    tmeddra_md_hierarchy  mmh,
                    tmeddra_pref_term_llt mptl
                WHERE
                        mmh.pt_code = mptl.pt_code
                    AND upper(trim(mptl.llt_name_english)) = upper(trim(pi_llt_name))
                    AND mmh.primary_soc_fg = 'Y'
                    AND mptl.llt_currency = 'Y';

              po_dict_id := pkg_mg_util.f_mg_key_val('MedDRA Dict Id');
                po_code_status := 1;
            EXCEPTION
                WHEN no_data_found OR too_many_rows THEN
                    po_code_status := 0;
                    po_dict_id := NULL;
            END;

        END IF;

        IF
            po_code_status = 0
            AND pi_llt_name IS NOT NULL
        THEN
            BEGIN
                SELECT
                    mmh.soc_code,
                    mmh.soc_name,
                    mmh.hlgt_code,
                    mmh.hlgt_name,
                    mmh.hlt_code,
                    mmh.hlt_name,
                    mmh.pt_code,
                    mmh.pt_name,
                    mptl.llt_code,
                    mptl.llt_name_english
                INTO
                    po_soc_code,
                    po_soc_name,
                    po_hlgt_code,
                    po_hlgt_name,
                    po_hlt_code,
                    po_hlt_name,
                    po_pt_code,
                    po_pt_name,
                    po_llt_code,
                    po_llt_name
                FROM
                    tmeddra_md_hierarchy  mmh,
                    tmeddra_pref_term_llt mptl
                WHERE
                        mmh.pt_code = mptl.pt_code
                    AND upper(trim(mmh.pt_name)) = upper(trim(pi_pref_term))
                    AND mmh.primary_soc_fg = 'Y'
                    AND mptl.llt_currency = 'Y';

       po_dict_id := pkg_mg_util.f_mg_key_val('MedDRA Dict Id');
                po_code_status := 1;
            EXCEPTION
                WHEN no_data_found OR too_many_rows THEN
                    po_code_status := 0;
                    po_dict_id := NULL;
            END;
        END IF;
        IF
            po_code_status = 0
            AND pi_pref_term IS NOT NULL
        THEN
            BEGIN
                SELECT
                    mmh.soc_code,
                    mmh.soc_name,
                    mmh.hlgt_code,
                    mmh.hlgt_name,
                    mmh.hlt_code,
                    mmh.hlt_name,
                    mmh.pt_code,
                    mmh.pt_name,
                    mptl.llt_code,
                    mptl.llt_name_english
                INTO
                    po_soc_code,
                    po_soc_name,
                    po_hlgt_code,
                    po_hlgt_name,
                    po_hlt_code,
                    po_hlt_name,
                    po_pt_code,
                    po_pt_name,
                    po_llt_code,
                    po_llt_name
                FROM
                    tmeddra_md_hierarchy  mmh,
                    tmeddra_pref_term_llt mptl
                WHERE
                        mmh.pt_code = mptl.pt_code
                    AND upper(trim(mptl.llt_name_english)) = upper(trim(pi_reported_term))
--                  AND mmh.pt_code  = pi_pt_code
                    AND mmh.primary_soc_fg = 'Y'
                    AND mptl.llt_currency = 'Y';

              po_dict_id := pkg_mg_util.f_mg_key_val('MedDRA Dict Id');
                po_code_status := 1;
            EXCEPTION
                WHEN no_data_found OR too_many_rows THEN
                    po_code_status := 0;
                    po_dict_id := NULL;
            END;
        END IF;

    EXCEPTION
        WHEN no_data_found THEN
            po_code_status := 0;
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => pkg_mg_util.g_scase_num,
                pi_tcase_id     => pkg_mg_util.g_tcase_id,
                pi_message_type => 'WARNING',
                pi_message      => 'MedDRA Mapping Not Found - LLT Code For Source->'
                              || pi_source
                              || ' in'
                              || pi_llt_name
                              || ', PT Code'
                              || pi_pref_term,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

        WHEN OTHERS THEN
            raise_application_error(-20003, NULL);
    END p_meddra_map_br001;

    PROCEDURE p_get_partial_date (
        pi_table_name     IN VARCHAR2,
        pi_date_format    IN NUMBER,
        pi_date_in_number IN VARCHAR2,
        po_date           OUT DATE,
        po_date_res       OUT NUMBER,
        po_date_partial   OUT VARCHAR2
    ) AS
        v_value VARCHAR2(50);
    BEGIN
        IF pi_date_in_number IS NULL THEN
            po_date := NULL;
            po_date_res := 0;
            po_date_partial := NULL;
            RETURN;
        END IF;

IF VALIDATE_CONVERSION((PI_DATE_IN_NUMBER) AS DATE,'DD-MM-RR') = 1 THEN--exception partial date mapping

   po_date := TO_DATE ( PI_DATE_IN_NUMBER, 'DD-MM-RR' );
   po_date_res     := 5;
   po_date_partial := PI_DATE_IN_NUMBER;
   RETURN;
END IF;
   v_value         := TRIM(TO_CHAR(PI_DATE_IN_NUMBER));
    /*first use format if present*/
        IF pi_date_format IS NOT NULL THEN
            IF pi_date_format = 602 THEN
                po_date := TO_DATE ( v_value, 'YYYY' );
                po_date_res := 5;
                po_date_partial := to_char(po_date, 'YYYY');
            ELSIF pi_date_format = 610 THEN
                po_date := TO_DATE ( v_value, 'YYYYMM' );
                po_date_res := 7;
                po_date_partial := to_char(po_date, 'MM-YYYY');
            ELSIF pi_date_format = 102 THEN
                po_date := TO_DATE ( v_value, 'YYYYMMDD' );
                po_date_res := 8;
                po_date_partial := to_char(po_date, 'DD-MM-YYYY');
            ELSIF pi_date_format = 203 THEN
                po_date := TO_DATE ( v_value, 'YYYYMMDDHH24MI' );
                po_date_res := 8;
            ELSE
                po_date := NULL;
                po_date_res := 0;
                po_date_partial := NULL;
            END IF;

 /*use length if format not present*/
        ELSE
            IF length(v_value) = 4 THEN
                po_date := TO_DATE ( v_value, 'YYYY' );
                po_date_res := 5;
            ELSIF length(v_value) = 6 THEN
                po_date := TO_DATE ( v_value, 'YYYYMM' );
                po_date_res := 7;
            ELSIF length(v_value) = 8 THEN
                po_date := TO_DATE ( v_value, 'YYYYMMDD' );
                po_date_res := 8;
            ELSIF length(v_value) = 12 THEN
                po_date := TO_DATE ( v_value, 'YYYYMMDDHH24MI' );
                po_date_res := 8;
            ELSE
                po_date := NULL;
                po_date_res := 0;
                po_date_partial := NULL;
            END IF;
        END IF;

        IF po_date IS NOT NULL THEN
            po_date_partial := to_char(po_date, 'DD-MM-YYYY');
        ELSE
            po_date_partial := NULL;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => pkg_mg_util.g_scase_num,
                pi_tcase_id     => pkg_mg_util.g_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'Error: IN P_GET_PARTIAL_DATE Called from table'
                              || pi_table_name
                              || ':'
                              || sqlerrm,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
    END p_get_partial_date;

    PROCEDURE p_get_tgt_prod_id (
       PI_suspect_drug_name IN VARCHAR2,
        PI_medicinalproduct IN VARCHAR2,
         PI_drugdosageform IN VARCHAR2,
          PI_drugauthorizationcountry IN VARCHAR2,
           PI_drugauthorizationnumb IN VARCHAR2,
            PI_suspect_product_generic_name IN VARCHAR2,
        po_tgt_prod_id     OUT NUMBER,
        po_tgt_prod_lic_id OUT NUMBER
    ) IS
    V_CNT NUMBER:=0;
    v_drug_cnt NUMBER:=0;
    BEGIN
       po_tgt_prod_id := NULL;
        po_tgt_prod_lic_id := NULL;      



  SELECT
   TGT_PROD_ID,PROD_LIC_ID
    INTO 
    po_tgt_prod_id,
    po_tgt_prod_lic_id
FROM
    mg_product_mapping
WHERE
    upper(trim(suspect_drug_name))
    || upper(trim(medicinal_product))
    || upper(trim(dosage_form))
    || upper(trim(drug_auth_country))
    || upper(trim(drug_auth_number))
    || upper(trim(generic_name)) = upper(trim(PI_suspect_drug_name))
                                   || upper(trim(PI_medicinalproduct))
                                   || upper(trim(PI_drugdosageform))
                                   || upper(trim(PI_drugauthorizationcountry))
                                   || upper(trim(PI_drugauthorizationnumb))
                                   || upper(trim(PI_suspect_product_generic_name));


    EXCEPTION
        WHEN no_data_found THEN  
        begin

  SELECT
   distinct TGT_PROD_ID,PROD_LIC_ID
    INTO 
    po_tgt_prod_id,
    po_tgt_prod_lic_id
FROM
    mg_product_mapping
WHERE
   upper(trim(medicinal_product))
    || upper(trim(dosage_form))
    || upper(trim(drug_auth_country))
    || upper(trim(drug_auth_number))
    || upper(trim(generic_name)) =  upper(trim(PI_medicinalproduct))
                                   || upper(trim(PI_drugdosageform))
                                   || upper(trim(PI_drugauthorizationcountry))
                                   || upper(trim(PI_drugauthorizationnumb))
                                   || upper(trim(PI_suspect_product_generic_name));

    EXCEPTION
        WHEN no_data_found THEN

        select count(1)
        into v_drug_cnt
        from s_drug where case_number =pkg_mg_util.g_scase_num
        and DRUGCHARACTERIZATION=1 and
        upper(trim(medicinalproduct))=upper(trim(PI_medicinalproduct));


         SELECT COUNT(DISTINCT SUSPECT_DRUG_NAME) INTO V_CNT
        FROM S_CASEPRODUCTLEVEL SCP WHERE 
        UPPER(TRIM(SUSPECT_DRUG_NAME))=UPPER(TRIM(NVL(PI_suspect_drug_name,PI_medicinalproduct)));


        if V_CNT>0 or v_drug_cnt>0 then
          pkg_mg_util.p_mg_log_message(
                pi_scase_num    => pkg_mg_util.g_scase_num,
                pi_tcase_id     => pkg_mg_util.g_tcase_id,
                pi_message_type => 'WARNING',
                pi_message      => 'Product Mapping Not found for product->'||nvl(PI_suspect_drug_name,PI_medicinalproduct),
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
            end if;
        end ;


            po_tgt_prod_id := NULL;
            po_tgt_prod_lic_id := NULL;
            WHEN too_many_rows THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => pkg_mg_util.g_scase_num,
                pi_tcase_id     => pkg_mg_util.g_tcase_id,
                pi_message_type => 'WARNING',
                pi_message      => 'multiple records found Product Mapping for product->'||nvl(PI_suspect_drug_name,PI_medicinalproduct),
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
            po_tgt_prod_id := NULL;
            po_tgt_prod_lic_id := NULL;
             WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => pkg_mg_util.g_scase_num,
                pi_tcase_id     => pkg_mg_util.g_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'ERROR IN PROCEDURE:p_get_tgt_prod_id :'||SQLERRM,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
    END p_get_tgt_prod_id;


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
)
AS
BEGIN

/*FOR CALCULATING THE FIRST DOSE*/
IF PI_FIRST_DOSE>PI_START_DATE THEN
PO_FIRST_DOSE:=PI_START_DATE;
PO_FIRST_DOSE_RES:=PI_START_DATE_RES;
PO_FIRST_DOSE_PARTIAL:=PI_START_DATE_PARTIAL;
END IF;


/*FOR CALCULATING THE LAST DOSE*/
IF PI_LAST_DOSE<PI_STOP_DATE THEN
PO_LAST_DOSE:=PI_STOP_DATE;
PO_LAST_DOSE_RES:=PI_STOP_DATE_RES;
PO_LAST_DOSE_PARTIAL:=PI_STOP_DATE_PARTIAL;
END IF;


EXCEPTION WHEN OTHERS THEN
 pkg_mg_util.p_mg_log_message(
                pi_scase_num    => pkg_mg_util.g_scase_num,
                pi_tcase_id     => pkg_mg_util.g_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'ERROR IN PROCEDURE:P_MG_FIRST_LAST_DOSE_CALC :'||SQLERRM,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
END P_MG_FIRST_LAST_DOSE_CALC;

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
)
IS
l_tgt_ormulation_id NUMBER;
V_MAPPING_TYPE VARCHAR(150);

BEGIN
po_TGT_PROD_ID:=NULL;
po_TGT_PROD_LIC_ID:=NULL;

BEGIN

SELECT DISTINCT
   TGT_PRODUCT_ID,TGT_LICENSE_ID,MAPPING
    INTO 
    po_TGT_PROD_ID,
    po_TGT_PROD_LIC_ID,
    V_MAPPING_TYPE
FROM
    MG_STUDY_PRODUCT_MAPPING
WHERE tgt_study_key=pi_study_key
and tgt_cohort_id=pi_cohort_id AND
    upper(trim(suspect_drug_name))
    || upper(trim(medicinal_product))
    || upper(trim(dosage_form))
    || upper(trim(drug_auth_country))
    || upper(trim(drug_auth_number))
    || upper(trim(generic_name)) = upper(trim(PI_suspect_drug_name))
                                   || upper(trim(PI_medicinalproduct))
                                   || upper(trim(PI_drugdosageform))
                                   || upper(trim(PI_drugauthorizationcountry))
                                   || upper(trim(PI_drugauthorizationnumb))
                                   || upper(trim(PI_GENeRIC_NAME));



  EXCEPTION

        WHEN OTHERS  THEN

            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => pkg_mg_util.g_scase_num,
                pi_tcase_id     => pkg_mg_util.g_tcase_id,
                pi_message_type => 'WARNING',
                pi_message      =>upper(trim(PI_suspect_drug_name))
                                   || upper(trim(PI_medicinalproduct))
                                   || upper(trim(PI_drugdosageform))
                                   || upper(trim(PI_drugauthorizationcountry))
                                   || upper(trim(PI_drugauthorizationnumb))
                                   || upper(trim(PI_GENeRIC_NAME))||' '||SQLERRM,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
            V_MAPPING_TYPE:='Not Mapped';
            po_tgt_prod_id := NULL;
            po_tgt_prod_lic_id := NULL;

        END ;

           if po_tgt_prod_id IS NULL AND V_MAPPING_TYPE<>'Not Mapped' THEN
           pkg_mg_util.p_mg_log_message(
                pi_scase_num    => pkg_mg_util.g_scase_num,
                pi_tcase_id     => pkg_mg_util.g_tcase_id,
                pi_message_type => 'USER WARNING',
                pi_message      =>upper(trim(PI_suspect_drug_name))
                                   || upper(trim(PI_medicinalproduct))
                                   || upper(trim(PI_drugdosageform))
                                   || upper(trim(PI_drugauthorizationcountry))
                                   || upper(trim(PI_drugauthorizationnumb))
                                   || upper(trim(PI_GENeRIC_NAME))||' Mapping Present but target product Id is not mapped ',
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
            END IF;


END p_GET_TGT_STUDY_PROD_ID;

PROCEDURE P_MG_STUDY_MAPPING(
pi_studyname IN VARCHAR2,
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
)
IS
BEGIN


BEGIN


select DISTINCT tgt_study_key, tgt_cohort_id
INTO po_study_key,po_cohort_id
from MG_STUDY_PRODUCT_MAPPING rec
WHERE upper(trim(rec.STUDYNAME))||upper(trim(rec.SPONSORSTUDYNUMB))||rec.OBSERVESTUDYTYPE
=upper(trim(pi_studyname))||upper(trim(pi_sponsorstudynumb))||pi_observestudytype;

EXCEPTION
WHEN OTHERS THEN 
po_study_key:=NULL;
po_cohort_id:=NULL;
--ADD WARNING
END;




SELECT distinct
    TLSC.study_key,
    TLS.study_num,
    TLS.study_num_j,
    TLSC.cohort_id,
    TLSC.blind_name,
    TLSC.blind_name_j,
    TLSC.study_type_id,
    TLS.protocol_num,
    TLS.id_protocol,
    TLS.classification_id,
    TLS.study_desc,
    TLS.study_desc_j,
    TLS.dev_phase_id
INTO 
    po_study_key,
    po_study_num,
    po_study_num_j,
    po_cohort_id,
    po_blind_name,
    po_blind_name_j,
    po_study_type,
    po_protocol_num,
    po_protocol_id,
    po_classification_id,
    po_study_desc,
    po_study_desc_j,
    po_dev_phase_id
FROM tlm_studies tls
INNER JOIN tlm_study_cohorts tlsc 
       ON tls.study_key = tlsc.study_key
WHERE tls.deleted IS NULL
AND tlsc.deleted IS NULL
and tls.study_key=po_study_key
and tlsc.cohort_id=po_cohort_id
--AND UPPER(TRIM(tls.study_num)) = UPPER(TRIM(pi_study_num))
--and TLSC.study_key=NVL(po_study_key,TLSC.study_key)
--and TLSC.cohort_id=NVL(po_cohort_id,TLSC.cohort_id)
;

EXCEPTION
        WHEN no_data_found THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => pkg_mg_util.g_scase_num,
                pi_tcase_id     => pkg_mg_util.g_tcase_id,
                pi_message_type => 'WARNING',
                pi_message      => 'Study  Mapping Not found for study Num-> '||upper(trim(pi_studyname))||upper(trim(pi_sponsorstudynumb))||pi_observestudytype,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
po_study_key         := NULL;
po_study_num         := NULL;
po_study_num_j       := NULL;
po_cohort_id         := NULL;
po_blind_name        := NULL;
po_blind_name_j      := NULL;
po_study_type        := NULL;
po_protocol_num      := NULL;
po_protocol_id       := NULL;
po_classification_id := NULL;
po_study_desc        := NULL;
po_study_desc_j      := NULL;
po_dev_phase_id      := NULL;
            WHEN too_many_rows THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => pkg_mg_util.g_scase_num,
                pi_tcase_id     => pkg_mg_util.g_tcase_id,
                pi_message_type => 'WARNING',
                pi_message      => 'multiple records found in Study Mapping for Study Num->'||upper(trim(pi_studyname))||upper(trim(pi_sponsorstudynumb))||pi_observestudytype,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
             WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => pkg_mg_util.g_scase_num,
                pi_tcase_id     => pkg_mg_util.g_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'ERROR IN PROCEDURE:P_MG_STUDY_MAPPING :'||SQLERRM,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
            END P_MG_STUDY_MAPPING;
                 PROCEDURE p_tgt_ingredient_id(
        pi_ingredient_NAME IN varchar2,
        po_ingredient_id OUT NUMBER
    ) IS
        v_ing_name VARCHAR2(1000) := NULL;
    BEGIN
        v_ing_name := pi_ingredient_NAME;

        SELECT DISTINCT
            ingredient_id
        INTO po_ingredient_id
        FROM
            tlm_ingredients si
        WHERE
                upper(trim(si.ingredient)) = upper(trim(v_ing_name))
            AND si.deleted IS NULL;

    EXCEPTION
        WHEN OTHERS THEN
            po_ingredient_id := NULL;
            pkg_mg_util.p_mg_log_message(
             pi_scase_num    => pkg_mg_util.g_scase_num,
                pi_tcase_id     => pkg_mg_util.g_tcase_id,
                pi_message_type => 'WARNING',
                pi_message      => 'Ingredient '
                              || pi_ingredient_NAME
                              || ' Not Found',
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

    END p_tgt_ingredient_id;

         PROCEDURE p_get_body_sys_event (
        po_body_sys  OUT VARCHAR2,
        po_pri_event OUT VARCHAR2
    ) IS
    BEGIN
        SELECT
            desc_coded,
            body_sys
        INTO
            po_pri_event,
            po_body_sys
        FROM
            tcase_event ce
        WHERE
                ce.case_id = pkg_mg_util.g_tcase_id
            AND ce.sort_id = 1
            AND ce.deleted IS NULL;

    EXCEPTION
        WHEN no_data_found OR too_many_rows THEN
            pkg_mg_util.p_mg_log_message(
                 pi_scase_num    => pkg_mg_util.g_scase_num,
                pi_tcase_id     => pkg_mg_util.g_tcase_id,
                pi_message_type => 'WARNING',
                pi_message      => 'Primary Event Not Found for case',
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );
        WHEN OTHERS THEN
            raise_application_error(-20003, NULL);
    END p_get_body_sys_event;
END pkg_mg_buss_rules;

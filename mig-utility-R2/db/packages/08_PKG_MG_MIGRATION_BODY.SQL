create or replace PACKAGE BODY pkg_mg_migration IS

    PROCEDURE p_mg_case_master (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_master IS
        SELECT
            ssr.*,
            scl.report_type
        FROM
                 S_SAFETYREPORT ssr
            INNER JOIN s_caselevel scl ON ssr.case_number = scl.case_number
        WHERE
            ssr.case_number = src_case_num;

        v_index       PLS_INTEGER := 0;
        TYPE v_case_master_tab IS
            TABLE OF tcase_master%rowtype INDEX BY PLS_INTEGER;
        v_case_master v_case_master_tab;
    BEGIN
        FOR v_row IN c_case_master LOOP
            v_index := v_index + 1;
             v_case_master(v_index).rev:=0;
            v_case_master(v_index).case_id := pi_tcase_id;
            v_case_master(v_index).case_num := src_case_num;
            v_case_master(v_index).create_time := pkg_mg_util.f_mg_key_val('Migration Date');
            v_case_master(v_index).init_rept_date := pkg_mg_util.f_var_to_date('CASE_MASTER->INIT_REPT_DATE', v_row.receivedateformat
            , v_row.receivedate);

            v_case_master(v_index).user_id := pkg_mg_util.f_mg_key_val('Migration User Id');
            v_case_master(v_index).last_update_time := pkg_mg_util.f_mg_key_val('Migration Date');
            v_case_master(v_index).last_update_user_id := pkg_mg_util.f_mg_key_val('Migration User Id');
            v_case_master(v_index).followup_date := pkg_mg_util.f_var_to_date('CASE_MASTER->FOLLOWUP_DATE', v_row.receiptdateformat, v_row.receiptdate
            );

            v_case_master(v_index).owner_id := pkg_mg_util.f_mg_key_val('Migration User Id');
            v_case_master(v_index).country_id := pkg_mg_util.f_mg_codelist_code('E2B', 'Countries', v_row.occurcountry);

            v_case_master(v_index).seriousness :=
                CASE
                    WHEN v_row.serious = 1 THEN
                        1
                    ELSE 0
                END;

            v_case_master(v_index).requires_followup := 0;
            v_case_master(v_index).rpt_type_id := pkg_mg_util.f_mg_codelist_code('Non_E2B', 'Report Type', v_row.report_type);

            v_case_master(v_index).sid := pkg_mg_util.f_mg_key_val('Database SID');
            v_case_master(v_index).e2b_ww_number := v_row.safetyreportid;
            v_case_master(v_index).medically_confirm :=
                CASE
                    WHEN v_row.medicallyconfirm = 1 THEN
                        1
                    ELSE 0
                END;

            v_case_master(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
            v_case_master(v_index).workflow_seq_num := NULL;
            v_case_master(v_index).last_workflow_seq_num := NULL;
            v_case_master(v_index).state_id := 2;
            v_case_master(v_index).last_state_id := NULL;--dont have case processing state in target cfg_workdflow states
            v_case_master(v_index).close_date := pkg_mg_util.f_mg_key_val('Migration Date');
             v_case_master(v_index).close_user_id := pkg_mg_util.f_mg_key_val('Migration User Id');
            v_case_master(v_index).initial_justification := NULL;
            v_case_master(v_index).lam_assess_done := 0;
            v_case_master(v_index).lock_status_id := 3;
            v_case_master(v_index).site_id := pkg_mg_util.f_mg_key_val('Site Id');

               /*changes*/--27 Feb

            v_case_master(v_index).date_locked := pkg_mg_util.f_mg_key_val('Migration Date');
            v_case_master(v_index).seriousness :=
                CASE
                    WHEN v_row.serious = 1 THEN
                        1
                    ELSE 0
                END;

            v_case_master(v_index).close_notes := 'Migrated from Sebela'; --CNF IF IT HAS TO BE DEFAULT
            v_case_master(v_index).priority := 0;              ---default sn
            v_case_master(v_index).priority_assessment := 1;
            v_case_master(v_index).priority_date_assessed := pkg_mg_util.f_mg_key_val('Migration Date');
            v_case_master(v_index).priority_override := 1;
            v_case_master(v_index).report_scheduling := 0;
            v_case_master(v_index).susar := 0;
            v_case_master(v_index).assessment_needed := 0;
        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_master VALUES v_case_master ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_MASTER ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_master;

    PROCEDURE p_mg_case_study (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_study IS
        SELECT
            case_number,
            studyname,
            sponsorstudynumb,
            observestudytype
        FROM
            s_primarysource
        WHERE
            studyname
            || sponsorstudynumb
            || observestudytype IS NOT NULL
            AND case_number = src_case_num;

        v_index      PLS_INTEGER := 0;
        TYPE v_case_study_tab IS
            TABLE OF tcase_study%rowtype INDEX BY PLS_INTEGER;
        v_case_study v_case_study_tab;
        V_BLINDED_PROD_PRESENT NUMBER;
    BEGIN

SELECT COUNT(1)
INTO V_BLINDED_PROD_PRESENT
FROM S_DRUG
WHERE UPPER(MEDICINALPRODUCT) LIKE '%BLIND%' 
AND CASE_NUMber=SRC_CASE_NUM;

        FOR v_row IN c_case_study LOOP
            v_index := v_index + 1;
            --fetch study key and cohirt id from mg)_study prduct mapping
          --  if comPAny study then study key is not null then
          --cohort_id=msp.cohort_id.
           --     fetch these from  config
            v_case_study(v_index).case_id := pi_tcase_id;
            pkg_mg_buss_rules.p_mg_study_mapping(v_row.studyname,
                                                 v_row.sponsorstudynumb,
                                                 v_row.observestudytype,
                                                 v_case_study(v_index).cohort_id,
                                                 v_case_study(v_index).study_key,
                                                 v_case_study(v_index).blind_name,
                                                 v_case_study(v_index).blind_name_j,
                                                 v_case_study(v_index).study_type,
                                                 v_case_study(v_index).study_num,
                                                 v_case_study(v_index).study_num_j,
                                                 v_case_study(v_index).protocol_num,
                                                 v_case_study(v_index).classification_id,
                                                 v_case_study(v_index).protocol_id,
                                                 v_case_study(v_index).study_desc,
                                                 v_case_study(v_index).study_desc_j,
                                                 v_case_study(v_index).dev_phase_id);

                                           IF  v_case_study(v_index).study_key IS NULL THEN
                                             v_case_study(v_index).study_num:=V_ROW.studyname;
                                             v_case_study(v_index).study_desc:=V_ROW.sponsorstudynumb;
                                                      v_case_study(v_index).study_type:=V_ROW.observestudytype;
                                                      END IF;

            v_case_study(v_index).product_count := 0;--CONFIRM THIS--this will be reset in case_product 
        /*LEFT COLUMNS CANNOT BE PULLED FROM CONFIG*/
            v_case_study(v_index).center_id := NULL;
            v_case_study(v_index).center_name := NULL;
            v_case_study(v_index).other_id := NULL;


            IF v_case_study(v_index).study_type=3 THEN
            v_case_study(v_index).code_broken := 4;--open label study for now

            ELSIF v_case_study(v_index).study_type IN (1,2) THEN
           IF V_BLINDED_PROD_PRESENT>0 THEN 
           v_case_study(v_index).code_broken:=0;
           ELSE
           v_case_study(v_index).code_broken:=3;
           END IF;
            END IF;
            v_case_study(v_index).broken_by := NULL;--MIGRATION USER
            v_case_study(v_index).broken_date := NULL;
            v_case_study(v_index).reason := NULL;
            v_case_study(v_index).week := NULL;
            v_case_study(v_index).visit := NULL;
            v_case_study(v_index).center_name_j := NULL;
            v_case_study(v_index).clin_compound_num_j := NULL;
            v_case_study(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
        END LOOP;

        IF v_index = 0 THEN
            v_index := v_index + 1;
            v_case_study(v_index).case_id := pi_tcase_id;
            v_case_study(v_index).product_count := 0;
               v_case_study(v_index).code_broken:=-1;
               v_case_study(v_index).study_type:=-1;
            v_case_study(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
        END IF;

--        pkg_mg_util.g_study_key := v_case_study(v_index).study_key;
        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_study VALUES v_case_study ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_STUDY ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_study;

    PROCEDURE p_mg_case_followup (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_followup IS
        SELECT
            s.safetyreport_seq,
            s.safetyreportversion,
            s.safetyreportid,
            s.primarysourcecountry,
            s.occurcountry,
            s.transmissiondateformat,
            s.transmissiondate,
            s.reporttype,
            s.serious,
            s.seriousnessdeath,
            s.seriousnesslifethreatening,
            s.seriousnesshospitalization,
            s.seriousnessdisabling,
            s.seriousnesscongenitalanomali,
            s.seriousnessother,
            s.receivedateformat,
            s.receivedate,
            s.receiptdateformat,
            s.receiptdate,
            s.additionaldocument,
            s.fulfillexpeditecriteria,
            s.companynumb,
            s.duplicate,
            s.medicallyconfirm,
            s.documentlist
        FROM
            S_SAFETYREPORT s
        WHERE
            s.case_number = src_case_num;

        v_index         PLS_INTEGER := 0;
        TYPE v_case_followup_tab IS
            TABLE OF tcase_followup%rowtype INDEX BY PLS_INTEGER;
        v_case_followup v_case_followup_tab;
    BEGIN
        FOR v_row IN c_case_followup LOOP
            v_index := v_index + 1;
            v_case_followup(v_index).case_id := pi_tcase_id;
            v_case_followup(v_index).seq_num := pkg_mg_util.f_mg_seq_num('CASE_FOLLOWUP', 'SEQ_NUM');
--            v_case_followup(v_index).receipt_date := pkg_mg_util.f_var_to_date(v_row.receivedate);
--            v_case_followup(v_index).safety_date := pkg_mg_util.f_var_to_date(v_row.receivedate);
            v_case_followup(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
            pkg_mg_util.p_insert_seq_mapping('S_SAFETYREPORT',
                                             'CASE_FOLLOWUP',
                                             'SAFETYREPORT_SEQ',
                                             'SEQ_NUM',
                                             v_row.safetyreport_seq,
                                             v_case_followup(v_index).seq_num);

        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_followup VALUES v_case_followup ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_FOLLOWUP ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_followup;

    PROCEDURE p_mg_case_literature (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_literature IS
        SELECT
            ps.primarysource_seq,
            ps.safetyreport_seq,
            ps.reportergivename,
            ps.reporterfamilyname,
            ps.reportermiddlename,
            ps.reportercountry,
            ps.qualification,
            ps.reportertitle,
            ps.reporterstreet,
            ps.reportercity,
            ps.reporterstate,
            ps.reporterpostcode,
            ps.reporterorganization,
            ps.reporterdepartment,
            ps.studyname,
            ps.sponsorstudynumb,
            ps.observestudytype,
            ps.literaturereference
        FROM
            s_primarysource ps
        WHERE
            ps.case_number = src_case_num;

        v_index           PLS_INTEGER := 0;
        TYPE v_case_literature_tab IS
            TABLE OF tcase_literature%rowtype INDEX BY PLS_INTEGER;
        v_case_literature v_case_literature_tab;
    BEGIN
        FOR v_row IN c_case_literature LOOP
            v_index := v_index + 1;
            v_case_literature(v_index).case_id := pi_tcase_id;
            v_case_literature(v_index).seq_num := pkg_mg_util.f_mg_seq_num('CASE_LITERATURE', 'SEQ_NUM');
            v_case_literature(v_index).journal := NULL;
            v_case_literature(v_index).author := v_row.literaturereference;
            v_case_literature(v_index).title := NULL;
            v_case_literature(v_index).vol := NULL;
            v_case_literature(v_index).year := NULL;
            v_case_literature(v_index).pgs := NULL;
            v_case_literature(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_literature VALUES v_case_literature ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_LITERATURE ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_literature;

    PROCEDURE p_mg_case_classifications (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_classifications IS
        SELECT
            *
        FROM
            dual;

        v_index                PLS_INTEGER := 0;
        TYPE v_case_classifications_tab IS
            TABLE OF tcase_classifications%rowtype INDEX BY PLS_INTEGER;
        v_case_classifications v_case_classifications_tab;
    BEGIN
        FOR v_row IN c_case_classifications LOOP
            v_index := v_index + 1;
            v_case_classifications(v_index).case_id := NULL;
            v_case_classifications(v_index).seq_num := NULL;
            v_case_classifications(v_index).classification_id := NULL;
            v_case_classifications(v_index).deleted := NULL;
            v_case_classifications(v_index).enterprise_id := NULL;
        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_classifications VALUES v_case_classifications ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_CLASSIFICATIONS ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_classifications;

    PROCEDURE p_mg_case_pat_info (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_patient IS
        SELECT
            p.patient_seq,
            p.patientagegroup,
            p.patientonsetageunit,
            p.patientsex,
            p.patientmedicalhistorytext,
            p.patientonsetage,
            p.patientbirthdate,
            p.patientbirthdateformat,
            p.patientheight,
            p.patientinvestigationnumb,
            p.patientinitial,
            p.patientweight
        FROM
            s_patient p
        WHERE
            p.case_number = src_case_num;

        TYPE t_case_pat_info_tab IS
            TABLE OF tcase_pat_info%rowtype INDEX BY PLS_INTEGER;
        v_case_pat_info t_case_pat_info_tab;
        v_index         PLS_INTEGER := 0;
    BEGIN
        FOR v_row IN c_patient LOOP
            v_index := v_index + 1;
            v_case_pat_info(v_index).case_id := pi_tcase_id;
            v_case_pat_info(v_index).case_id := pi_tcase_id;
            v_case_pat_info(v_index).age_group_id := pkg_mg_util.f_mg_codelist_code('E2B', 'Age Groups', v_row.patientagegroup);

            v_case_pat_info(v_index).age_unit_id := pkg_mg_util.f_mg_codelist_code('E2B', 'Age Units', v_row.patientonsetageunit);

            v_case_pat_info(v_index).gender_id := pkg_mg_util.f_mg_codelist_code('E2B', 'Gender', v_row.patientsex);

            v_case_pat_info(v_index).notes := v_row.patientmedicalhistorytext;
            v_case_pat_info(v_index).pat_age := v_row.patientonsetage;
            v_case_pat_info(v_index).pat_id := v_row.patientinvestigationnumb;
            v_case_pat_info(v_index).pat_initials := v_row.patientinitial;
            v_case_pat_info(v_index).pat_height_cm := v_row.patientheight;
            v_case_pat_info(v_index).pat_weight_kg := v_row.patientweight;
            v_case_pat_info(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
            v_case_pat_info(v_index).PAT_SUBJ_NUM:=v_row.PATIENTINVESTIGATIONNUMB;
            pkg_mg_buss_rules.p_get_partial_date('CASE_PAT_INFO',
                                                 v_row.patientbirthdateformat,
                                                 v_row.patientbirthdate,
                                                 v_case_pat_info(v_index).pat_dob,
                                                 v_case_pat_info(v_index).pat_dob_res,
                                                 v_case_pat_info(v_index).pat_dob_partial);

            v_case_pat_info(v_index).pat_height_in :=
                CASE
                    WHEN v_row.patientheight IS NOT NULL THEN
                        round(v_row.patientheight / 2.54, 2)
                    ELSE NULL
                END;

            v_case_pat_info(v_index).pat_weight_lbs :=
                CASE
                    WHEN v_row.patientweight IS NOT NULL THEN
                        round(v_row.patientweight * 2.20462, 2)
                    ELSE NULL
                END;

        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_pat_info VALUES v_case_pat_info ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_PAT_INFO ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_pat_info;

    PROCEDURE p_mg_case_pat_hist (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        v_index         NUMBER := 0;
        v_seq_num       NUMBER := 0;
        CURSOR c_past_drug IS
        SELECT
            pd.patientpastdrugtherapy_seq,
            pd.patient_seq,
            pd.safetyreport_seq,
            pd.patientdrugname,
            pd.patientindicationmeddraversion,
            pd.patientdrugindication,
            pd.patientdrgreactionmeddraversion,
            pd.patientdrugreaction,
            pd.patientdrugstartdateformat,
            pd.patientdrugstartdate,
            pd.patientdrugenddateformat,
            pd.patientdrugenddate
        FROM
            s_patientpastdrugtherapy pd
        WHERE
            pd.case_number = src_case_num;

        CURSOR c_med_hist IS
        SELECT
            mh.medicalhistoryepisode_seq,
            mh.patient_seq,
            mh.safetyreport_seq,
            mh.patientepisodenamemeddraversion,
            mh.patientepisodename,
            mh.patientmedicalcomment,
            mh.patientmedicalstartdateformat,
            mh.patientmedicalstartdate,
            mh.patientmedicalenddateformat,
            mh.patientmedicalenddate,
            mh.patientmedicalcontinue
        FROM
            s_medicalhistoryepisode mh
        WHERE
            mh.case_number = src_case_num;

        TYPE t_case_pat_hist_tab IS
            TABLE OF tcase_pat_hist%rowtype INDEX BY PLS_INTEGER;
        v_case_pat_hist t_case_pat_hist_tab;
    BEGIN
        FOR v_row IN c_past_drug LOOP
            v_index := v_index + 1;
            v_seq_num := v_seq_num + 1;
            v_case_pat_hist(v_index).case_id := pi_tcase_id;
            v_case_pat_hist(v_index).seq_num := pkg_mg_util.f_mg_seq_num('CASE_PAT_HIST', 'SEQ_NUM');
            v_case_pat_hist(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');

            v_case_pat_hist(v_index).indication := v_row.patientdrugindication;
            
            pkg_mg_buss_rules.p_meddra_map_code (
                pi_source        => 'INDICATION',
                pi_llt_code      => v_row.patientdrugindication,
                pi_pt_code       => v_row.patientdrugindication,
                pi_llt_name      => v_row.patientdrugindication,
                pi_pref_term     => v_row.patientdrugindication,
                pi_reported_term => v_row.patientdrugindication,
                po_llt_code      => v_case_pat_hist(v_index).ind_llt_code,
                po_llt_name      => v_case_pat_hist(v_index).ind_llt,
                po_pt_code       => v_case_pat_hist(v_index).ind_pt_code, 
                po_pt_name       => v_case_pat_hist(v_index).ind_coded,
                po_hlt_code      => v_case_pat_hist(v_index).ind_hlt_code,
                po_hlt_name      => v_case_pat_hist(v_index).ind_hlt,
                po_hlgt_code     => v_case_pat_hist(v_index).ind_hlgt_code,
                po_hlgt_name     => v_case_pat_hist(v_index).ind_hlgt,
                po_soc_code      => v_case_pat_hist(v_index).ind_soc_code,
                po_soc_name      => v_case_pat_hist(v_index).ind_soc,
                po_code_status   => v_case_pat_hist(v_index).ind_code_status,
                po_dict_id       => v_case_pat_hist(v_index).ind_dict_id
            );
               

            v_case_pat_hist(v_index).reaction := v_row.patientdrugreaction;

            pkg_mg_buss_rules.p_meddra_map_code (
                pi_source        => 'REACTION',
                pi_llt_code      => v_row.patientdrugreaction,
                pi_pt_code       => v_row.patientdrugreaction,
                pi_llt_name      => v_row.patientdrugreaction,
                pi_pref_term     => v_row.patientdrugreaction,
                pi_reported_term => v_row.patientdrugreaction,
                po_llt_code      => v_case_pat_hist(v_index).react_llt_code,
                po_llt_name      => v_case_pat_hist(v_index).react_llt,
                po_pt_code       => v_case_pat_hist(v_index).react_pt_code, 
                po_pt_name       => v_case_pat_hist(v_index).react_coded,
                po_hlt_code      => v_case_pat_hist(v_index).react_hlt_code,
                po_hlt_name      => v_case_pat_hist(v_index).react_hlt,
                po_hlgt_code     => v_case_pat_hist(v_index).react_hlgt_code,
                po_hlgt_name     => v_case_pat_hist(v_index).react_hlgt,
                po_soc_code      => v_case_pat_hist(v_index).react_soc_code,
                po_soc_name      => v_case_pat_hist(v_index).react_soc,
                po_code_status   => v_case_pat_hist(v_index).react_code_status,
                po_dict_id       => v_case_pat_hist(v_index).react_dict_id
            );
               
            pkg_mg_buss_rules.p_get_partial_date('PATIENTPASTDRUGTHERAPY',
                                                 v_row.patientdrugstartdateformat,
                                                 v_row.patientdrugstartdate,
                                                 v_case_pat_hist(v_index).start_date,
                                                 v_case_pat_hist(v_index).start_date_res,
                                                 v_case_pat_hist(v_index).start_date_partial);

            pkg_mg_buss_rules.p_get_partial_date('PATIENTPASTDRUGTHERAPY',
                                                 v_row.patientdrugenddateformat,
                                                 v_row.patientdrugenddate,
                                                 v_case_pat_hist(v_index).stop_date,
                                                 v_case_pat_hist(v_index).stop_date_res,
                                                 v_case_pat_hist(v_index).stop_date_partial);

            pkg_mg_util.p_insert_seq_mapping('S_PATIENTPASTDRUGTHERAPY',
                                             'TCASE_PAT_HIST',
                                             'PATIENTPASTDRUGTHERAPY_SEQ',
                                             'SEQ_NUM',
                                             v_row.patientpastdrugtherapy_seq,
                                             v_case_pat_hist(v_index).seq_num);

/*changes*/
            v_case_pat_hist(v_index).sort_id := v_index;
            pkg_mg_util.p_insert_seq_mapping('S_PATIENTPASTDRUGTHERAPY',
                                             'CASE_PAT_HIST',
                                             'PATIENTPASTDRUGTHERAPY_SEQ',
                                             'SEQ_NUM',
                                             v_row.patientpastdrugtherapy_seq,
                                             v_case_pat_hist(v_index).seq_num);

        END LOOP;

        FOR v_row IN c_med_hist LOOP
            v_index := v_index + 1;
            v_seq_num := v_seq_num + 1;
            v_case_pat_hist(v_index).case_id := pi_tcase_id;
            v_case_pat_hist(v_index).seq_num := pkg_mg_util.f_mg_seq_num('CASE_PAT_HIST', 'SEQ_NUM');
            v_case_pat_hist(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
            v_case_pat_hist(v_index).condition := v_row.patientepisodename;
            v_case_pat_hist(v_index).note := v_row.patientmedicalcomment;
            v_case_pat_hist(v_index).continue :=
            CASE
                WHEN v_row.patientmedicalcontinue = 1 THEN
                    1
                ELSE 0
            END;

            pkg_mg_buss_rules.p_meddra_map_code (
                pi_source        => 'Medical History Item',
                pi_llt_code      => v_row.patientepisodename,
                pi_pt_code       => v_row.patientepisodename,
                pi_llt_name      => v_row.patientepisodename,
                pi_pref_term     => v_row.patientepisodename,
                pi_reported_term => v_row.patientepisodename,
                po_llt_code      => v_case_pat_hist(v_index).item_llt_code,
                po_llt_name      => v_case_pat_hist(v_index).item_llt,
                po_pt_code       => v_case_pat_hist(v_index).item_code, 
                po_pt_name       => v_case_pat_hist(v_index).item_coded,
                po_hlt_code      => v_case_pat_hist(v_index).item_hlt_code,
                po_hlt_name      => v_case_pat_hist(v_index).item_hlt,
                po_hlgt_code     => v_case_pat_hist(v_index).item_hlgt_code,
                po_hlgt_name     => v_case_pat_hist(v_index).item_hlgt,
                po_soc_code      => v_case_pat_hist(v_index).item_soc_code,
                po_soc_name      => v_case_pat_hist(v_index).item_soc,
                po_code_status   => v_case_pat_hist(v_index).item_code_status,
                po_dict_id       => v_case_pat_hist(v_index).item_dict
            );

            pkg_mg_buss_rules.p_get_partial_date('MEDICALHISTORYEPISODE-Start_Date',
                                                 v_row.patientmedicalstartdateformat,
                                                 v_row.patientmedicalstartdate,
                                                 v_case_pat_hist(v_index).start_date,
                                                 v_case_pat_hist(v_index).start_date_res,
                                                 v_case_pat_hist(v_index).start_date_partial);

            pkg_mg_buss_rules.p_get_partial_date('MEDICALHISTORYEPISODE-Stop_Date',
                                                 v_row.patientmedicalenddateformat,
                                                 v_row.patientmedicalenddate,
                                                 v_case_pat_hist(v_index).stop_date,
                                                 v_case_pat_hist(v_index).stop_date_res,
                                                 v_case_pat_hist(v_index).stop_date_partial);

            pkg_mg_util.p_insert_seq_mapping('S_MEDICALHISTORYEPISODE',
                                             'TCASE_PAT_HIST',
                                             'MEDICALHISTORYEPISODE_SEQ',
                                             'SEQ_NUM',
                                             v_row.medicalhistoryepisode_seq,
                                             v_case_pat_hist(v_index).seq_num);

/*changes*/
            v_case_pat_hist(v_index).sort_id := v_index;
            pkg_mg_util.p_insert_seq_mapping('S_MEDICALHISTORYEPISODE',
                                             'CASE_PAT_HIST',
                                             'MEDICALHISTORYEPISODE_SEQ',
                                             'SEQ_NUM',
                                             v_row.medicalhistoryepisode_seq,
                                             v_case_pat_hist(v_index).seq_num);

        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_pat_hist VALUES v_case_pat_hist ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_PAT_HIST ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_pat_hist;

    PROCEDURE p_mg_case_lab_data (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_lab_data IS
        SELECT
            t.test_seq,
            t.patient_seq,
            t.safetyreport_seq,
            t.case_number,
            t.testname,
            t.hightestrange,
            t.lowtestrange,
            t.testresult,
            t.testdate,
            t.testdateformat,
            t.testunit,
            t.moreinformation
        FROM
            s_test t
        WHERE
            t.case_number = src_case_num;

        v_index         PLS_INTEGER := 0;
        TYPE v_case_lab_data_tab IS
            TABLE OF tcase_lab_data%rowtype INDEX BY PLS_INTEGER;
        v_case_lab_data v_case_lab_data_tab;
    BEGIN
        FOR v_row IN c_case_lab_data LOOP
            v_index := v_index + 1;
            v_case_lab_data(v_index).case_id := pi_tcase_id;
            v_case_lab_data(v_index).seq_num := pkg_mg_util.f_mg_seq_num('CASE_LAB_DATA', 'SEQ_NUM');
            v_case_lab_data(v_index).lab_test_id := NULL;
            v_case_lab_data(v_index).sort_id := v_index;
            v_case_lab_data(v_index).assessment := NULL;
            v_case_lab_data(v_index).test_date_res := v_row.testdateformat;
            v_case_lab_data(v_index).result := NULL;
            v_case_lab_data(v_index).norm_high := v_row.hightestrange;
            v_case_lab_data(v_index).norm_low := v_row.lowtestrange;
            v_case_lab_data(v_index).results := v_row.testresult;
            v_case_lab_data(v_index).unit := v_row.testunit;
            v_case_lab_data(v_index).lab_test_name := v_row.testname;
            v_case_lab_data(v_index).deleted := NULL;
            v_case_lab_data(v_index).notes := NULL;
            v_case_lab_data(v_index).syn_code := NULL;
            v_case_lab_data(v_index).test_reptd := v_row.testname;
            v_case_lab_data(v_index).unit_id := pkg_mg_util.f_mg_codelist_code('E2B', 'Dose Units', v_row.testunit);

            v_case_lab_data(v_index).comments := NULL;
            v_case_lab_data(v_index).info_available := v_row.moreinformation;
            v_case_lab_data(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
            v_case_lab_data(v_index).multi_event_exists := NULL;

            pkg_mg_buss_rules.p_meddra_map_code (
                pi_source        => 'Lab Data',
                pi_llt_code      => v_row.testname,
                pi_pt_code       => v_row.testname,
                pi_llt_name      => v_row.testname,
                pi_pref_term     => v_row.testname,
                pi_reported_term => v_row.testname,
                po_llt_code      => v_case_lab_data(v_index).llt_code,
                po_llt_name      => v_case_lab_data(v_index).llt,
                po_pt_code       => v_case_lab_data(v_index).pt_code, 
                po_pt_name       => v_case_lab_data(v_index).lab_test_name,
                po_hlt_code      => v_case_lab_data(v_index).hlt_code,
                po_hlt_name      => v_case_lab_data(v_index).hlt,
                po_hlgt_code     => v_case_lab_data(v_index).hlgt_code,
                po_hlgt_name     => v_case_lab_data(v_index).hlgt,
                po_soc_code      => v_case_lab_data(v_index).soc_code,
                po_soc_name      => v_case_lab_data(v_index).soc,
                po_code_status   => v_case_lab_data(v_index).code_status,
                po_dict_id       => v_case_lab_data(v_index).dict_id
            );

            pkg_mg_buss_rules.p_get_partial_date('Lab Data',             --changed sn
                                                 v_row.testdateformat,
                                                 v_row.testdate,
                                                 v_case_lab_data(v_index).test_date,
                                                 v_case_lab_data(v_index).test_date_res,
                                                 v_case_lab_data(v_index).test_date_partial);


                                           pkg_mg_util.p_insert_seq_mapping('S_TEST',
                                             'Case_Lab_Data',
                                             'TEST_SEQ',
                                             'SEQ_NUM',
                                             V_ROW.TEST_SEQ,
                                                          v_case_lab_data(v_index).seq_num);       

        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_lab_data VALUES v_case_lab_data ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_LAB_DATA ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_lab_data;

    PROCEDURE p_mg_case_pat_tests (--confirm this procedure .
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_rel_tests IS
        SELECT
            sr.resultstestsprocedures
        FROM
            s_patient sr
        WHERE
            sr.case_number = src_case_num;

        v_index          PLS_INTEGER := 0;
        TYPE v_case_pat_tests_tab IS
            TABLE OF tcase_pat_tests%rowtype INDEX BY PLS_INTEGER;
        v_case_pat_tests v_case_pat_tests_tab;
    BEGIN
        FOR v_row IN c_rel_tests LOOP
            v_index := v_index + 1;
            v_case_pat_tests(v_index).rel_test_id := pi_tcase_id;
            v_case_pat_tests(v_index).rel_tests := v_row.resultstestsprocedures;
            v_case_pat_tests(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_pat_tests VALUES v_case_pat_tests ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_PAT_TESTS ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_pat_tests;

    PROCEDURE p_mg_case_parent_info (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_parent_info IS
        SELECT
            *
        FROM
            dual;

        v_index            PLS_INTEGER := 0;
        TYPE v_case_parent_info_tab IS
            TABLE OF tcase_parent_info%rowtype INDEX BY PLS_INTEGER;
        v_case_parent_info v_case_parent_info_tab;
    BEGIN
        FOR v_row IN c_case_parent_info LOOP
            v_index := v_index + 1;
            v_case_parent_info(v_index).case_id := pi_tcase_id;
            v_case_parent_info(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_parent_info VALUES v_case_parent_info ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_PARENT_INFO ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_parent_info;

    PROCEDURE p_mg_case_pat_race (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_pat_race IS
        SELECT
            *
        FROM
            dual;

        v_index         PLS_INTEGER := 0;
        TYPE v_case_pat_race_tab IS
            TABLE OF tcase_pat_race%rowtype INDEX BY PLS_INTEGER;
        v_case_pat_race v_case_pat_race_tab;
    BEGIN
        FOR v_row IN c_case_pat_race LOOP
            v_index := v_index + 1;
            v_case_pat_race(v_index).case_id := NULL;
            v_case_pat_race(v_index).seq_num := NULL;
            v_case_pat_race(v_index).parent := NULL;
            v_case_pat_race(v_index).ethnicity_id := NULL;
            v_case_pat_race(v_index).deleted := NULL;
            v_case_pat_race(v_index).enterprise_id := NULL;
        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_pat_race VALUES v_case_pat_race ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_PAT_RACE ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_pat_race;

    PROCEDURE p_mg_case_pregnancy (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_pregnancy IS
        SELECT
            *
        FROM
            dual;

        v_index          PLS_INTEGER := 0;
        TYPE v_case_pregnancy_tab IS
            TABLE OF tcase_pregnancy%rowtype INDEX BY PLS_INTEGER;
        v_case_pregnancy v_case_pregnancy_tab;
    BEGIN
        FOR v_row IN c_case_pregnancy LOOP
            v_index := v_index + 1;
            v_case_pregnancy(v_index).case_id := pi_tcase_id;
            v_case_pregnancy(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_pregnancy VALUES v_case_pregnancy ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_PREGNANCY ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_pregnancy;

    PROCEDURE p_mg_case_neonates (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_neonates IS
        SELECT
            *
        FROM
            dual;

        v_index         PLS_INTEGER := 0;
        TYPE v_case_neonates_tab IS
            TABLE OF tcase_neonates%rowtype INDEX BY PLS_INTEGER;
        v_case_neonates v_case_neonates_tab;
    BEGIN
        FOR v_row IN c_case_neonates LOOP
            v_index := v_index + 1;
            v_case_neonates(v_index).case_id := pi_tcase_id;
            v_case_neonates(v_index).seq_num := pkg_mg_util.f_mg_seq_num('case_neonates', 'SEQ_NUM');
--       
--            v_case_neonates(v_index).notes := NULL;
            v_case_neonates(v_index).sort_id := v_index;
--          
--            v_case_neonates(v_index).notes_j := NULL;
            v_case_neonates(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_neonates VALUES v_case_neonates ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_NEONATES ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_neonates;

    PROCEDURE p_mg_case_event (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_event IS
        SELECT
            sr.*,
            cel.preferred_term,
            cel.reported_term,
            cel.event_outcome,
            cel.event_seriousness,
            cel.death,
            cel.hospitalization,
            cel.congenital_anomaly,
            cel.life_threatening,
            cel.disabling,
            cel.other,
            cel.medically_significant,
            cel.event_seq_num
        FROM
            s_reaction      sr
            LEFT JOIN s_caseeventlevel cel ON cel.case_number = sr.case_number
                                                AND cel.event_seq_num = sr.evt_seq_num
        WHERE
            sr.case_number = src_case_num
            order by cel.event_seq_num;

        TYPE t_case_event_tab IS
            TABLE OF tcase_event%rowtype INDEX BY PLS_INTEGER;
        v_case_event t_case_event_tab;
        v_index      PLS_INTEGER := 0;
        v_cnt_seriousness number:=null;
    BEGIN
        FOR v_row IN c_case_event LOOP
            v_index := v_index + 1;

            v_case_event(v_index).case_id := pi_tcase_id;
            v_case_event(v_index).sort_id := v_index;
            v_case_event(v_index).seq_num := pkg_mg_util.f_mg_seq_num('CASE_EVENT', 'SEQ_NUM');
            v_case_event(v_index).desc_reptd := v_row.primarysourcereaction; 
        -- Direct : REACTIONS.
            v_case_event(v_index).desc_coded := v_row.reactionmeddrapt;
            v_case_event(v_index).duration := v_row.reactionduration;
            v_case_event(v_index).duration_unit_e2b := v_row.reactiondurationunit;
            v_case_event(v_index).duration_seconds := pkg_mg_util.f_convert_to_seconds(v_row.reactionduration, v_row.reactiondurationunit
            );

            v_case_event(v_index).onset_delay := v_row.reactionfirsttime;
            v_case_event(v_index).onset_delay_unit_e2b := v_row.reactionfirsttimeunit;
            v_case_event(v_index).onset_latency := v_row.reactionlasttime;
            IF v_row.event_outcome IS NOT NULL THEN
                v_case_event(v_index).evt_outcome_id := pkg_mg_util.f_mg_codelist_code('Non_E2B', 'Event Outcome', v_row.event_outcome
                );
            ELSE
                v_case_event(v_index).evt_outcome_id := pkg_mg_util.f_mg_codelist_code('E2B', 'Event Outcome', v_row.reactionoutcome)
                ;
            END IF;

         --   v_case_event(v_index).rpt_serious := pkg_mg_util.f_mg_codelist_code('E2B', 'TERMHIGHLIGHTED', v_row.termhighlighted);--confirm mapping

            v_case_event(v_index).sc_death :=
                CASE
                    WHEN v_row.death = 'Yes' THEN
                        1
                    ELSE 0
                END;

            v_case_event(v_index).sc_hosp :=
                CASE
                    WHEN v_row.hospitalization = 'Yes' THEN
                        1
                    ELSE 0
                END;

            v_case_event(v_index).sc_cong_anom :=
                CASE
                    WHEN v_row.congenital_anomaly = 'Yes' THEN
                        1
                    ELSE 0
                END;

            v_case_event(v_index).sc_threat :=
                CASE
                    WHEN v_row.life_threatening = 'Yes' THEN
                        1
                    ELSE 0
                END;

            v_case_event(v_index).sc_disable :=
                CASE
                    WHEN v_row.disabling = 'Yes' THEN
                        1
                    ELSE 0
                END;

            v_case_event(v_index).sc_other :=
                CASE
                    WHEN v_row.other = 'Yes' THEN
                        1
                    ELSE 0
                END;

            v_case_event(v_index).sc_death :=
                CASE
                    WHEN v_row.death = 'Yes' THEN
                        1
                    ELSE 0
                END;

            v_case_event(v_index).seriousness :=
                CASE
                    WHEN v_row.event_seriousness = 'Yes' THEN
                        1
                    ELSE 0
                END;

            v_case_event(v_index).med_serious :=
                CASE
                    WHEN v_row.death = 'Yes' THEN
                        1
                    ELSE 0
                END;

            v_case_event(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');

            pkg_mg_buss_rules.p_meddra_map_code (
                pi_source        => 'Event',
                pi_llt_code      => v_row.reactionmeddrallt,
                pi_pt_code       => v_row.preferred_term,
                pi_llt_name      => v_row.reactionmeddrallt,
                pi_pref_term     => v_row.preferred_term,
                pi_reported_term => v_row.reported_term,
                po_llt_code      => v_case_event(v_index).inc_code,
                po_llt_name      => v_case_event(v_index).inc_term,
                po_pt_code       => v_case_event(v_index).art_code, 
                po_pt_name       => v_case_event(v_index).pref_term,
                po_hlt_code      => v_case_event(v_index).hlt_code,
                po_hlt_name      => v_case_event(v_index).hlt,
                po_hlgt_code     => v_case_event(v_index).hlgt_code,
                po_hlgt_name     => v_case_event(v_index).hlgt,
                po_soc_code      => v_case_event(v_index).soc_code,
                po_soc_name      => v_case_event(v_index).body_sys,
                po_code_status   => v_case_event(v_index).code_status,
                po_dict_id       => v_case_event(v_index).dict_id
            );

            pkg_mg_buss_rules.p_get_partial_date('CASE_EVENT',
                                                 v_row.reactionstartdateformat,
                                                 v_row.reactionstartdate,
                                                 v_case_event(v_index).onset,
                                                 v_case_event(v_index).onset_res,
                                                 v_case_event(v_index).onset_date_partial);

            pkg_mg_buss_rules.p_get_partial_date('CASE_EVENT',
                                                 v_row.reactionenddateformat,
                                                 v_row.reactionenddate,
                                                 v_case_event(v_index).stop_date,
                                                 v_case_event(v_index).stop_date_res,
                                                 v_case_event(v_index).stop_date_partial);

            pkg_mg_util.p_insert_seq_mapping('S_REACTIONS',
                                             'CASE_EVENT',
                                             'REACTION_ID',
                                             'SEQ_NUM',
                                             v_row.reaction_seq,
                                             v_case_event(v_index).seq_num);

            pkg_mg_util.p_insert_seq_mapping('S_CASEEVENTLEVEL',
                                             'CASE_EVENT',
                                             'EVENT_SEQ_NUM',
                                             'SEQ_NUM',
                                             v_row.event_seq_num,
                                             v_case_event(v_index).seq_num);
/*changes*/
            v_case_event(v_index).study_dropped := -1;
            v_case_event(v_index).study_related := -1;
            v_case_event(v_index).diagnosis := 1;
            v_case_event(v_index).delay_minutes := pkg_mg_util.f_convert_to_seconds(v_row.reactionfirsttime, v_row.reactionfirsttimeunit
            );

            v_case_event(v_index).onset_delay_seconds := pkg_mg_util.f_convert_to_seconds(v_row.reactionfirsttime, v_row.reactionfirsttimeunit
            );

            v_case_event(v_index).onset_latency_seconds := pkg_mg_util.f_convert_to_seconds(v_row.reactionlasttime, v_row.reactionlasttimeunit
            );

            v_case_event(v_index).onset_latency_unit_e2b := pkg_mg_util.f_convert_to_seconds(v_row.reactionlasttime, v_row.reactionlasttimeunit
            );

            v_case_event(v_index).onset_minutes := pkg_mg_util.f_convert_to_seconds(v_row.reactionlasttime, v_row.reactionlasttimeunit
            );

        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_event VALUES v_case_event ( i );

        END LOOP;

select count(1) 
into v_cnt_seriousness
from tcase_event 
where case_id=pi_tcase_id 
and deleted is null 
and (SERIOUSNESS=1 or SC_DEATH = 1 
OR SC_HOSP = 1 
OR SC_CONG_ANOM = 1 
OR SC_THREAT = 1 
OR SC_DISABLE = 1 
OR SC_INT_REQ = 1 
OR SC_OTHER = 1);

UPDATE tcase_master tcm
SET tcm.SERIOUSNESS = 
    CASE 
        WHEN v_cnt_seriousness > 0 THEN 1
        ELSE 0
    END
WHERE case_id = pi_tcase_id;
    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_EVENT' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_event;

    PROCEDURE p_mg_case_hosp (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_hosp IS
        SELECT
            *
        FROM
            dual;

        v_index     PLS_INTEGER := 0;
        TYPE v_case_hosp_tab IS
            TABLE OF tcase_hosp%rowtype INDEX BY PLS_INTEGER;
        v_case_hosp v_case_hosp_tab;
    BEGIN
        FOR v_row IN c_case_hosp LOOP
            v_index := v_index + 1;
            v_case_hosp(v_index).case_id := pi_tcase_id;
            v_case_hosp(v_index).seq_num := pkg_mg_util.f_mg_seq_num('case_hosp', 'SEQ_NUM');
--           
            v_case_hosp(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_hosp VALUES v_case_hosp ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_HOSP ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_hosp;

--functiion f_get_product_id(pI_med_prod_name)

    PROCEDURE p_mg_case_product (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_product IS
        SELECT DISTINCT
            sd.drugcharacterization,
            sd.obtaindrugcountry,
            sd.drugadditional,
            sd.drugauthorizationnumb,
            sd.drugauthorizationholder,
            sd.actiondrug,
            sd.drugcumulativedosageunit,
            sd.drugauthorizationcountry,
            sd.drugcumulativedosagenumb,
            sd.case_number,
            sd.medicinalproduct,
            sd.drugstartperiod,
            sd.drugdosageform,
            sd.drug_seq_num,
            sclp.prod_seq_num,
            sclp.argus_display_order,
            sclp.suspect_drug_name,
            sclp.action_taken,
            sclp.dechallenge,
            sclp.rechallenge
        FROM
            s_drug             sd
            LEFT OUTER JOIN s_caseproductlevel sclp ON ( sd.case_number = sclp.case_number
                                                           AND upper(trim(sd.medicinalproduct)) = upper(trim(sclp.suspect_drug_name))
                                                           )
        WHERE
                sd.case_number = src_case_num
            AND sd.drug_seq_num = sd.drug_seq_num
        ORDER BY
            sclp.argus_display_order,
            sd.drugcharacterization ASC;

        v_index              PLS_INTEGER := 0;
        TYPE v_case_product_tab IS
            TABLE OF tcase_product%rowtype INDEX BY PLS_INTEGER;
        v_case_product       v_case_product_tab;

    /*CASE_PROD_DRUGS*/

        TYPE v_case_prod_drugs_tab IS
            TABLE OF tcase_prod_drugs%rowtype INDEX BY PLS_INTEGER;
        v_case_prod_drugs    v_case_prod_drugs_tab;

    /*case_dose_regimens*/

        CURSOR c_case_dose_regimens (
            ci_drug_seq_num IN NUMBER
        ) IS
        SELECT
            *
        FROM
            s_drug sd2
        WHERE
                sd2.case_number = src_case_num
            AND upper(trim(sd2.drug_seq_num)) = upper(trim(ci_drug_seq_num));

        v_index1             PLS_INTEGER := 0;
        TYPE v_case_dose_regimens_tab IS
            TABLE OF tcase_dose_regimens%rowtype INDEX BY PLS_INTEGER;
        v_case_dose_regimens v_case_dose_regimens_tab;
        v_generic_name       s_producteventlevel.suspect_product_generic_name%TYPE;
        l_product_id         NUMBER;
        s_drug_id            NUMBER := NULL;
        v_trade_name         tlm_license.trade_name%TYPE;
        v_trade_name_j       tlm_license.trade_name_j%TYPE;
        v_sus_check          NUMBER := 0;
        v_study_type         NUMBER := NULL;
        v_code_broken        NUMBER := NULL;
        l_study_key          NUMBER;
        l_cohort_id          NUMBER;
    BEGIN
        SELECT
            study_key,
            cohort_id,
            code_broken
        INTO
            l_study_key,
            l_cohort_id,
            v_code_broken
        FROM
            tcase_study
        WHERE
            case_id = pi_tcase_id;

        FOR v_row IN c_case_product LOOP
            v_index := v_index + 1;
            l_product_id := NULL;
            v_generic_name := NULL;
            s_drug_id := pkg_mg_util.f_get_drug_id(v_row.drugcharacterization, v_row.obtaindrugcountry, v_row.drugadditional, v_row.drugauthorizationnumb
            , v_row.drugauthorizationholder,
                                                   v_row.actiondrug, v_row.drugcumulativedosageunit, v_row.drugauthorizationcountry, v_row.drugcumulativedosagenumb
                                                   , v_row.case_number,
                                                   v_row.medicinalproduct, v_row.drugstartperiod);

            v_case_product(v_index).case_id := pi_tcase_id;
            v_case_product(v_index).seq_num := pkg_mg_util.f_mg_seq_num('CASE_PRODUCT', 'SEQ_NUM');
            v_case_product(v_index).drug_type := v_row.drugcharacterization;
            v_case_product(v_index).first_sus_prod :=
                CASE
                    WHEN v_sus_check = 0 THEN
                        pkg_mg_util.f_get_firsr_sus_product(pi_tcase_id, src_case_num, v_row.suspect_drug_name, v_row.medicinalproduct
                        , v_row.argus_display_order)
                    ELSE 0
                END;

            IF v_case_product(v_index).first_sus_prod = 1 THEN
                v_sus_check := 1;
            END IF;
            v_case_product(v_index).sort_id := v_index;
            v_case_product(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
            BEGIN
                SELECT DISTINCT
                    ( suspect_product_generic_name )
                INTO v_generic_name
                FROM
                    s_producteventlevel spe
                WHERE
                        spe.prod_seq_num = v_row.prod_seq_num
                    AND spe.case_number = v_row.case_number
                    AND suspect_product_generic_name IS NOT NULL;

            EXCEPTION
                WHEN no_data_found THEN
                    v_generic_name := NULL;
            END;



--checking if a product is study product or not LOGIC START FROM HERE.
            IF l_study_key IS NOT NULL THEN
                pkg_mg_buss_rules.p_get_tgt_study_prod_id(v_row.drug_seq_num,
                                                          l_study_key,
                                                          l_cohort_id,
                                                          v_row.medicinalproduct,
                                                          v_row.drugdosageform,
                                                          V_ROW.drugauthorizationNUMB,
                                                          V_ROW.drugauthorizationcountry,
                                                          v_row.suspect_drug_name,
                                                          v_generic_name,
                                                          l_product_id,
                                                          v_case_product(v_index).prod_lic_id);
            END IF;

 --Product is a study Drug           
            IF l_product_id IS NOT NULL THEN
                v_case_product(v_index).co_drug_code := 'Study Drug';
            ELSE
                v_case_product(v_index).co_drug_code := '';
                pkg_mg_buss_rules.p_get_tgt_prod_id(v_row.suspect_drug_name,
                                                    v_row.medicinalproduct,
                                                    v_row.drugdosageform,
                                                    v_row.drugauthorizationcountry,
                                                    v_row.drugauthorizationnumb,
                                                    v_generic_name,
                                                    l_product_id,
                                                    v_case_product(v_index).prod_lic_id);

            END IF;

            IF l_product_id IS NOT NULL THEN
                v_case_product(v_index).selected_view := 1;
                SELECT
                    formulation_id,
                    concentration,
                    conc_unit_id,
                    family_id
                INTO
                    v_case_prod_drugs(v_index).formulation_id,
                    v_case_prod_drugs(v_index).concentration,
                    v_case_prod_drugs(v_index).conc_units_id,
                    v_case_product(v_index).family_id
                FROM
                    tlm_product
                WHERE
                        product_id = l_product_id
                    AND enterprise_id = pkg_mg_util.f_mg_key_val('Enterprise Id');

            END IF;

            dbms_output.put_line('N4>' || l_product_id);
            IF l_product_id IS NOT NULL THEN
                IF v_case_product(v_index).co_drug_code = 'Study Drug' THEN
                    IF v_code_broken = 0 AND UPPER(v_row.medicinalproduct)  LIKE '%BLINDED%' THEN ---Blinded STUDY

                        v_case_product(v_index).product_id := l_product_id;
                        v_case_product(v_index).pat_exposure := 0;
                        v_case_product(v_index).prod_reptd := nvl(v_row.suspect_drug_name, v_row.medicinalproduct);

                        SELECT
                            nvl(blind_name, study_num),
                            nvl(blind_name_j, study_num_j),
                            nvl(blind_name, study_num),
                            nvl(blind_name_j, study_num_j),
                            nvl(blind_name, study_num),
                            nvl(blind_name_j, study_num_j)
                        INTO
                            v_case_product(v_index).product_name,
                            v_case_product(v_index).product_name_j,
                            v_case_product(v_index).generic_name,
                            v_case_product(v_index).generic_name_j,
                            v_case_product(v_index).prod_coded,
                            v_case_product(v_index).prod_coded_j
                        FROM
                            tcase_study
                        WHERE
                            case_id = pi_tcase_id;

                    ELSIF v_code_broken IN ( 1, 2, 3 ) THEN--blind broken

                        v_case_product(v_index).product_id := NULL;
                        v_case_product(v_index).pat_exposure := l_product_id;
                        v_case_product(v_index).prod_reptd := nvl(v_row.suspect_drug_name, v_row.medicinalproduct);

                        SELECT
                            nvl(blind_name, study_num),
                            nvl(blind_name_j, study_num_j),
                            nvl(blind_name, study_num),
                            nvl(blind_name_j, study_num_j),
                            nvl(blind_name, study_num),
                            nvl(blind_name_j, study_num_j)
                        INTO
                            v_case_product(v_index).product_name,
                            v_case_product(v_index).product_name_j,
                            v_case_product(v_index).generic_name,
                            v_case_product(v_index).generic_name_j,
                            v_case_product(v_index).prod_coded,
                            v_case_product(v_index).prod_coded_j
                        FROM
                            tcase_study
                        WHERE
                            case_id = pi_tcase_id;

                    ELSIF v_code_broken = 4 THEN--OPEN LABEL study case

                        v_case_product(v_index).product_id := NULL;
                        v_case_product(v_index).pat_exposure := l_product_id;
                        v_case_product(v_index).prod_reptd := nvl(v_row.suspect_drug_name, v_row.medicinalproduct);

                        SELECT
                            prod_name,
                            prod_name_j,
                            prod_generic_name,
                            prod_generic_name_j,
                            prod_name,
                            prod_name_j,
                            family_id,
                            manufacturer_id,
                            prod_generic_name
                        INTO
                            v_case_product(v_index).product_name,
                            v_case_product(v_index).product_name_j,
                            v_case_product(v_index).generic_name,
                            v_case_product(v_index).generic_name_j,
                            v_case_product(v_index).prod_coded,
                            v_case_product(v_index).prod_coded_j,
                            v_case_product(v_index).family_id,
                            v_case_product(v_index).manufacturer_id,
                            v_case_product(v_index).generic_name
                        FROM
                            tlm_product
                        WHERE
                                product_id = l_product_id
                            AND enterprise_id = pkg_mg_util.f_mg_key_val('Enterprise Id');

                    END IF;

                ELSE --NON_STUDY_COMAPNY PRIDUCT

                    v_case_product(v_index).product_id := l_product_id;
                    v_case_product(v_index).pat_exposure := 0;
                    v_case_product(v_index).prod_reptd := nvl(v_row.medicinalproduct, v_row.medicinalproduct);

                    SELECT
                        prod_generic_name,
                        prod_generic_name_j,
                        prod_name,
                        prod_name_j,
                        family_id,
                        manufacturer_id,
                        prod_generic_name
                    INTO
                        v_case_product(v_index).generic_name,
                        v_case_product(v_index).generic_name_j,
                        v_case_product(v_index).prod_coded,
                        v_case_product(v_index).prod_coded_j,
                        v_case_product(v_index).family_id,
                        v_case_product(v_index).manufacturer_id,
                        v_case_product(v_index).generic_name
                    FROM
                        tlm_product
                    WHERE
                            product_id = l_product_id
                        AND enterprise_id = pkg_mg_util.f_mg_key_val('Enterprise Id');

                    /*PRODUCT LICENSE ID*/
                    IF v_case_product(v_index).prod_lic_id IS NOT NULL THEN
                        SELECT DISTINCT 
                            trade_name,
                            trade_name_j
                        INTO
                            v_trade_name,
                            v_trade_name_j
                        FROM
                                  tlm_license tll
                        WHERE
                            tll.license_id = v_case_product(v_index).prod_lic_id
                            and tll.deleted is null;

                    END IF;

                    v_case_product(v_index).product_name := nvl(
                        nvl(v_trade_name,
                            v_case_product(v_index).prod_coded),
                        v_case_product(v_index).prod_reptd
                    );

                    v_case_product(v_index).product_name_j := nvl(
                        nvl(v_trade_name_j,
                            v_case_product(v_index).prod_coded_j),
                        v_case_product(v_index).prod_reptd_j
                    );

                END IF;
            ELSE  --NON COMPANY & NON STUDY PRODUCT--
                v_case_product(v_index).selected_view := 7;
                v_case_product(v_index).product_id := NULL;
                v_case_product(v_index).pat_exposure := 0;
                v_case_product(v_index).product_name := nvl(v_row.suspect_drug_name, v_row.medicinalproduct);

                v_case_product(v_index).product_name_j := nvl(v_row.suspect_drug_name, v_row.medicinalproduct);

                v_case_product(v_index).generic_name := nvl(v_generic_name, v_row.medicinalproduct);
                v_case_product(v_index).generic_name_j := nvl(v_generic_name, v_row.medicinalproduct);
                v_case_product(v_index).prod_reptd := nvl(v_row.suspect_drug_name, v_row.medicinalproduct);

                v_case_product(v_index).prod_coded := nvl(v_row.suspect_drug_name, v_row.medicinalproduct);

                v_case_product(v_index).prod_coded_j := nvl(v_row.suspect_drug_name, v_row.medicinalproduct);

            END IF;

            v_case_product(v_index).country_id := pkg_mg_util.f_mg_codelist_code('E2B', 'Countries', v_row.obtaindrugcountry);

            v_case_product(v_index).vaers_block_id := 1;
            v_case_product(v_index).notes := v_row.drugadditional;
            v_case_product(v_index).primary_event := 1;--check with sir.
            v_case_product(v_index).auth_number := v_row.drugauthorizationnumb;
 v_case_product(v_index).mkt_auth_holder := case when v_row.drugauthorizationholder is null
                                         then null
                                         else pkg_mg_util.f_mg_key_val('MKT_AUTH_HOLDER') END;--main issue
            v_case_product(v_index).views_available := pkg_mg_util.f_mg_views_available(l_product_id);
            pkg_mg_util.p_insert_seq_mapping('S_DRUG',
                                             'CASE_PRODUCT',
                                             'DRUG_SEQ_NUM',
                                             'SEQ_NUM',
                                             v_row.drug_seq_num,
                                             v_case_product(v_index).seq_num);

            pkg_mg_util.p_insert_seq_mapping('S_CASEPRODUCTLEVEL',
                                             'CASE_PRODUCT',
                                             'PROD_SEQ_NUM',
                                             'SEQ_NUM',
                                             v_row.prod_seq_num,
                                             v_case_product(v_index).seq_num);

    /*CASE_PROD_DRUGS*/
            v_case_prod_drugs(v_index).case_id := pi_tcase_id;
            v_case_prod_drugs(v_index).seq_num := v_case_product(v_index).seq_num;
            v_case_prod_drugs(v_index).act_taken_id := pkg_mg_util.f_mg_codelist_code('E2B', 'Action Taken', v_row.actiondrug);

            v_case_prod_drugs(v_index).cumulative_dose := v_row.drugcumulativedosagenumb;
            v_case_prod_drugs(v_index).cumulative_dose_unit := pkg_mg_util.f_mg_codelist_code('E2B', 'Dose Units', v_row.drugcumulativedosageunit
            );

            v_case_prod_drugs(v_index).obtain_drug_country_id := pkg_mg_util.f_mg_codelist_code('E2B', 'Countries', v_row.drugauthorizationcountry
            );

            v_case_prod_drugs(v_index).drug_auth_country_id := pkg_mg_util.f_mg_codelist_code('E2B', 'Countries', v_row.obtaindrugcountry
            );

            v_case_prod_drugs(v_index).act_taken_id := pkg_mg_util.f_mg_codelist_code('E2B', 'Action Taken', v_row.actiondrug);

            v_case_prod_drugs(v_index).delay_seconds := NULL;--bl
            v_case_prod_drugs(v_index).latency_seconds := NULL;--BL
            v_case_prod_drugs(v_index).latency_seconds := v_row.drugstartperiod;
            v_case_prod_drugs(v_index).dechallenge := pkg_mg_util.f_mg_codelist_code('Non_E2B', 'Dechallenge', v_row.dechallenge);

            v_case_prod_drugs(v_index).rechallenge := pkg_mg_util.f_mg_codelist_code('Non_E2B', 'Rechallenge', v_row.rechallenge);

            v_case_prod_drugs(v_index).delay := NULL;--BL
            v_case_prod_drugs(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
            v_case_prod_drugs(v_index).interaction :=
                CASE
                    WHEN v_row.drugcharacterization = 3 THEN
                        1
                    ELSE -1
                END;
IF v_case_prod_drugs(v_index).FORMULATION_ID IS NULL THEN
v_case_prod_drugs(v_index).FORMULATION_ID:=pkg_mg_util.f_mg_codelist_code('E2B', 'Formulation', v_row.drugdosageform);
END IF;
            v_case_prod_drugs(v_index).first_dose := NULL;--INITIALIZING THEM NULL AT STARTING
            v_case_prod_drugs(v_index).last_dose := NULL;--INITIALIZING THEM NULL AT STARTING
/*CASE DOSE REGIMENS*/
            FOR v_row1 IN c_case_dose_regimens(v_row.drug_seq_num) LOOP
                v_index1 := v_index1 + 1;
                v_case_dose_regimens(v_index1).case_id := pi_tcase_id;
                v_case_dose_regimens(v_index1).seq_num := v_case_product(v_index).seq_num;
                v_case_dose_regimens(v_index1).log_no := pkg_mg_util.f_mg_seq_num('CASE_DOSE_REGIMENS', 'LOG_NO');
                pkg_mg_buss_rules.p_get_partial_date('CASE_DOSE_REGIMENS',
                                                     v_row1.drugstartdateformat,
                                                     v_row1.drugstartdate,
                                                     v_case_dose_regimens(v_index1).start_datetime,
                                                     v_case_dose_regimens(v_index1).start_datetime_res,
                                                     v_case_dose_regimens(v_index1).start_date_partial);

                pkg_mg_buss_rules.p_get_partial_date('CASE_DOSE_REGIMENS',
                                                     v_row1.drugenddateformat,
                                                     v_row1.drugenddate,
                                                     v_case_dose_regimens(v_index1).stop_datetime,
                                                     v_case_dose_regimens(v_index1).stop_datetime_res,
                                                     v_case_dose_regimens(v_index1).stop_date_partial);

                IF v_case_dose_regimens(v_index1).stop_datetime IS NULL THEN
                    v_case_dose_regimens(v_index1).ongoing := 1;
                ELSE
                    v_case_dose_regimens(v_index1).ongoing := 0;
                END IF;

                pkg_mg_buss_rules.p_mg_first_last_dose_calc(v_case_prod_drugs(v_index).first_dose,
                                                            v_case_prod_drugs(v_index).last_dose,
                                                            v_case_dose_regimens(v_index1).start_datetime,
                                                            v_case_dose_regimens(v_index1).start_datetime_res,
                                                            v_case_dose_regimens(v_index1).start_date_partial,
                                                            v_case_dose_regimens(v_index1).stop_datetime,
                                                            v_case_dose_regimens(v_index1).stop_datetime_res,
                                                            v_case_dose_regimens(v_index1).stop_date_partial,
                                                            v_case_prod_drugs(v_index).first_dose,
                                                            v_case_prod_drugs(v_index).first_dose_res,
                                                            v_case_prod_drugs(v_index).first_dose_partial,
                                                            v_case_prod_drugs(v_index).last_dose,
                                                            v_case_prod_drugs(v_index).last_dose_res,
                                                            v_case_prod_drugs(v_index).last_dose_partial);

                v_case_dose_regimens(v_index1).off_label := NULL;
                v_case_dose_regimens(v_index1).dose := v_row1.drugstructuredosagenumb;
                v_case_dose_regimens(v_index1).dose_unit_id := pkg_mg_util.f_mg_codelist_code('E2B', 'Dose Units', v_row1.drugstructuredosageunit
                );--highly in doubt
                v_case_dose_regimens(v_index1).freq_id := NULL;
                v_case_dose_regimens(v_index1).admin_route_id := pkg_mg_util.f_mg_codelist_code('E2B', 'Admin Route', v_row1.drugadministrationroute
                );

                v_case_dose_regimens(v_index1).daily_dose := NULL;
                v_case_dose_regimens(v_index1).daily_dose_unit_id := NULL;
                v_case_dose_regimens(v_index1).exp_date := NULL;
                v_case_dose_regimens(v_index1).exp_date_res := NULL;
                v_case_dose_regimens(v_index1).total_reg_dose := NULL;
                v_case_dose_regimens(v_index1).tot_reg_dose_unit_id := NULL;
                v_case_dose_regimens(v_index1).sort_id := NULL;
                v_case_dose_regimens(v_index1).dose_no := v_row1.drugstructuredosagenumb;
                v_case_dose_regimens(v_index1).par_admin_route := pkg_mg_util.f_mg_codelist_code('E2B', 'Admin Route', v_row1.drugparadministration
                );

                v_case_dose_regimens(v_index1).exp_date_partial := NULL;
                v_case_dose_regimens(v_index1).lot_no := v_row1.drugbatchnumb;
                v_case_dose_regimens(v_index1).duration_seconds := NULL;--br015
                v_case_dose_regimens(v_index1).last_update_time := pkg_mg_util.f_mg_key_val('Migration Date');
                v_case_dose_regimens(v_index1).duration := v_row1.drugtreatmentduration;
                v_case_dose_regimens(v_index1).dose_description := v_row1.drugdosagetext;
                v_case_dose_regimens(v_index1).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
            END LOOP;

        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_product VALUES v_case_product ( i );

            INSERT INTO tcase_prod_drugs VALUES v_case_prod_drugs ( i );

        END LOOP;

        FOR i IN 1..v_index1 LOOP
            INSERT INTO tcase_dose_regimens VALUES v_case_dose_regimens ( i );

        END LOOP;

        UPDATE tcase_product
        SET
            study_product_num = ROWNUM
        WHERE
                case_id = pi_tcase_id
            AND co_drug_code = 'Study Drug';

        UPDATE tcase_study cs
        SET
            product_count = (
                SELECT
                    COUNT(1)
                FROM
                    tcase_product cp
                WHERE
                        cp.case_id = cs.case_id
                    AND co_drug_code = 'Study Drug'
            )
        WHERE
            case_id = pi_tcase_id;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_PRODUCT ' || dbms_utility.format_error_stack||'Bactrace->'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_product;

    PROCEDURE p_mg_case_prod_ingredient (--TBD
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_prod_ingredient_comp IS
        SELECT
            lpin.ingredient_id,
            lpro.conc_unit_id,
            lpro.concentration,
            cpro.product_id,
            cpro.pat_exposure,
            cpro.deleted,
            cpro.seq_num
        FROM
            tlm_product        lpro,
            tcase_product      cpro,
            tlm_pf_ingredients lpin
        WHERE
                lpro.product_id = nvl(cpro.product_id, cpro.pat_exposure)
            AND nvl(cpro.product_id, cpro.pat_exposure) > 0
            AND lpin.family_id = lpro.family_id
            AND cpro.case_id = pi_tcase_id;

        CURSOR c_case_prod_ingredient_noncomp IS
        SELECT
            sd.case_number,
            activesubstancename,
            sd.drug_seq_num
        FROM
                 s_drug sd
            INNER JOIN s_activesubstance sas ON sas.case_number = sd.case_number
                                                  AND sd.drug_seq_num = sas.drug_seq
        WHERE
                sd.drug_seq_num = sd.drug_seq_num
            AND sd.prod_seq_num IS NULL
            AND sd.case_number = src_case_num;

        v_index                PLS_INTEGER := 0;
        TYPE v_case_prod_ingredient_tab IS
            TABLE OF tcase_prod_ingredient%rowtype INDEX BY PLS_INTEGER;
        v_case_prod_ingredient v_case_prod_ingredient_tab;
    BEGIN
        FOR v_comp IN c_case_prod_ingredient_comp LOOP
            v_index := v_index + 1;
            v_case_prod_ingredient(v_index).case_id := pi_tcase_id;
            v_case_prod_ingredient(v_index).seq_num := v_comp.seq_num;
            v_case_prod_ingredient(v_index).item := pkg_mg_util.f_mg_seq_num('CASE_PROD_INGREDIENT', 'ITEM');--we do not have source item to map in mg_st_seq_map.not req as well?
            v_case_prod_ingredient(v_index).ingredient_id := v_comp.ingredient_id;
            v_case_prod_ingredient(v_index).conc_unit_id := v_comp.conc_unit_id;
            v_case_prod_ingredient(v_index).concentration := v_comp.concentration;
            v_case_prod_ingredient(v_index).deleted := NULL;
            v_case_prod_ingredient(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
        END LOOP;

        FOR v_non_comp IN c_case_prod_ingredient_noncomp LOOP
            v_index := v_index + 1;
            v_case_prod_ingredient(v_index).case_id := pi_tcase_id;
            v_case_prod_ingredient(v_index).seq_num := pkg_mg_util.f_fetch_seq_map_val('S_DRUG', 'CASE_PRODUCT', 'DRUG_SEQ_NUM', 'SEQ_NUM'
            , v_non_comp.drug_seq_num,
                                                                                       'T');

            v_case_prod_ingredient(v_index).item := pkg_mg_util.f_mg_seq_num('CASE_PROD_INGREDIENT', 'ITEM');
            pkg_mg_buss_rules.p_tgt_ingredient_id(v_non_comp.activesubstancename,
                                                  v_case_prod_ingredient(v_index).ingredient_id);
--            v_case_prod_ingredient(v_index).conc_unit_id := pkg_mg_util.f_mg_codelist_code('E2B', 'Dose Units', v_non_comp.conc_units_id
--            );

--            v_case_prod_ingredient(v_index).concentration := v_non_comp.concentration;
            v_case_prod_ingredient(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_prod_ingredient VALUES v_case_prod_ingredient ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_INGREDIENT:' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_prod_ingredient;

    PROCEDURE p_mg_case_prod_indications (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_prod_indications IS
        SELECT
            *
        FROM
            s_drug sd
            where sd.drug_seq_num=sd.drug_seq_num
            and sd.case_number=src_case_num;

        v_index                 PLS_INTEGER := 0;
        TYPE v_case_prod_indications_tab IS
            TABLE OF tcase_prod_indications%rowtype INDEX BY PLS_INTEGER;
        v_case_prod_indications v_case_prod_indications_tab;
    BEGIN
        FOR v_row IN c_case_prod_indications LOOP
            v_index := v_index + 1;
            v_case_prod_indications(v_index).case_id := pi_tcase_id;
            v_case_prod_indications(v_index).prod_seq_num := pkg_mg_util.f_fetch_seq_map_val('S_DRUG', 'CASE_PRODUCT', 'DRUG_SEQ_NUM', 'SEQ_NUM', V_ROW.DRUG_SEQ_NUM,
                                              'T');
            v_case_prod_indications(v_index).seq_num :=  pkg_mg_util.f_mg_seq_num('CASE_PROD_INDICATIONS', 'SEQ_NUM');
            v_case_prod_indications(v_index).IND_REPTD := V_ROW.DRUGINDICATION;
               v_case_prod_indications(v_index).IND_CODED := V_ROW.DRUGINDICATION;
            v_case_prod_indications(v_index).sort_id := V_INDEX;
            v_case_prod_indications(v_index).ind_code := V_ROW.DRUGINDICATION;
            v_case_prod_indications(v_index).ind_pref_term := V_ROW.DRUGINDICATION;
            v_case_prod_indications(v_index).enterprise_id :=  pkg_mg_util.f_mg_key_val('Enterprise Id');
            v_case_prod_indications(v_index).multi_event_exists := NULL;

            pkg_mg_buss_rules.p_meddra_map_code (
                pi_source        => 'Product Indication',
                pi_llt_code      => v_row.DRUGINDICATION,
                pi_pt_code       => v_row.DRUGINDICATION,
                pi_llt_name      => v_row.DRUGINDICATION,
                pi_pref_term     => v_row.DRUGINDICATION,
                pi_reported_term => v_row.DRUGINDICATION,
                po_llt_code      => v_case_prod_indications(v_index).ind_llt_code,
                po_llt_name      => v_case_prod_indications(v_index).ind_llt,
                po_pt_code       => v_case_prod_indications(v_index).ind_code, 
                po_pt_name       => v_case_prod_indications(v_index).ind_pref_term,
                po_hlt_code      => v_case_prod_indications(v_index).ind_hlt_code,
                po_hlt_name      => v_case_prod_indications(v_index).ind_hlt,
                po_hlgt_code     => v_case_prod_indications(v_index).ind_hlgt_code,
                po_hlgt_name     => v_case_prod_indications(v_index).ind_hlgt,
                po_soc_code      => v_case_prod_indications(v_index).ind_soc_code,
                po_soc_name      => v_case_prod_indications(v_index).ind_soc,
                po_code_status   => v_case_prod_indications(v_index).ind_code_status,
                po_dict_id       => v_case_prod_indications(v_index).ind_code_dict
            );

        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_prod_indications VALUES v_case_prod_indications ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_PROD_INDICATIONS ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_prod_indications;

    PROCEDURE p_mg_case_death (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_death IS
        SELECT
            *
        FROM
            dual;

        v_index      PLS_INTEGER := 0;
        TYPE v_case_death_tab IS
            TABLE OF tcase_death%rowtype INDEX BY PLS_INTEGER;
        v_case_death v_case_death_tab;
    BEGIN
        FOR v_row IN c_case_death LOOP
            v_index := v_index + 1;
            v_case_death(v_index).case_id := pi_tcase_id;
            v_case_death(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_death VALUES v_case_death ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_DEATH ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_death;

    PROCEDURE p_mg_case_death_details (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_death_details IS
        SELECT
            *
        FROM
            dual;

        v_index              PLS_INTEGER := 0;
        TYPE v_case_death_details_tab IS
            TABLE OF tcase_death_details%rowtype INDEX BY PLS_INTEGER;
        v_case_death_details v_case_death_details_tab;
    BEGIN
        FOR v_row IN c_case_death_details LOOP
            v_index := v_index + 1;
            v_case_death_details(v_index).case_id := pi_tcase_id;
            v_case_death_details(v_index).seq_num := pkg_mg_util.f_mg_seq_num('case_death_details', 'SEQ_NUM');
            v_case_death_details(v_index).sort_id := NULL; --what to do
--        
            v_case_death_details(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
--       
        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_death_details VALUES v_case_death_details ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_DEATH_DETAILS ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_death_details;

    PROCEDURE p_mg_case_event_detail (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_event_detail IS
        SELECT DISTINCT
            spe.event_seq_num,
            spe.prod_seq_num
        FROM
            s_producteventlevel spe
        WHERE
                spe.case_number = src_case_num
            AND spe.event_seq_num IS NOT NULL
            AND spe.prod_seq_num IS NOT NULL;

        v_index             PLS_INTEGER := 0;
        TYPE v_case_event_detail_tab IS
            TABLE OF tcase_event_detail%rowtype INDEX BY PLS_INTEGER;
        v_case_event_detail v_case_event_detail_tab;
    BEGIN
        FOR v_row IN c_case_event_detail LOOP
            v_index := v_index + 1;
            v_case_event_detail(v_index).case_id := pi_tcase_id;
            v_case_event_detail(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
            v_case_event_detail(v_index).event_seq_num := v_row.event_seq_num;
            v_case_event_detail(v_index).prod_seq_num := v_row.prod_seq_num;
            v_case_event_detail(v_index).seq_num := pkg_mg_util.f_mg_seq_num('case_event_detail', 'SEQ_NUM');
        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_event_detail VALUES v_case_event_detail ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_EVENT_DETAIL ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_event_detail;

    PROCEDURE p_mg_case_event_assess (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_event_assess_cau IS
        SELECT
            tcm.case_num,
            tcp.case_id,
            tcp.seq_num                prod_seq_num,
            tce.seq_num                event_seq_num,
            tcp.product_id,
            tcp.pat_exposure,
            ( pkg_mg_util.f_fetch_seq_map_val('S_CASEPRODUCTLEVEL', 'CASE_PRODUCT', 'PROD_SEQ_NUM', 'SEQ_NUM', tcp.seq_num,
                                              'S') ) AS s_prod_seq_num,
            ( pkg_mg_util.f_fetch_seq_map_val('S_CASEEVENTLEVEL', 'CASE_EVENT', 'EVENT_SEQ_NUM', 'SEQ_NUM', tce.seq_num,
                                              'S') ) AS s_event_seq_num
        FROM
            tcase_product tcp,
            tcase_event   tce,
            tcase_master  tcm
        WHERE
                tcp.case_id = tce.case_id
            AND tcp.case_id = tcm.case_id
            AND tce.case_id = tcm.case_id
            AND tcp.drug_type = 1
            AND nvl(tcp.product_id, tcp.pat_exposure) > 0
            AND tcm.case_num = src_case_num;

        v_index             PLS_INTEGER := 0;
        TYPE v_case_event_assess_tab IS
            TABLE OF tcase_event_assess%rowtype INDEX BY PLS_INTEGER;
        v_case_event_assess v_case_event_assess_tab;
        s_det_causality     s_producteventlevel.company_causality%TYPE;
        s_rpt_causality     s_producteventlevel.reported_causality%TYPE;
        s_listedness        s_producteventlevel.listedness%TYPE;
        l_tgt_lic_id        NUMBER;
    BEGIN
        FOR v_cau IN c_case_event_assess_cau LOOP
            v_index := v_index + 1;
            BEGIN
                SELECT
                    company_causality,
                    reported_causality
                INTO
                    s_det_causality,
                    s_rpt_causality
                FROM
                    s_producteventlevel
                WHERE
                        prod_seq_num = v_cau.s_prod_seq_num
                    AND event_seq_num = v_cau.s_event_seq_num
                    AND case_number = v_cau.case_num
                    AND listedness IS NULL
                    AND ( company_causality || reported_causality IS NOT NULL );

            EXCEPTION
                WHEN OTHERS THEN
                    s_det_causality := NULL;
                    s_rpt_causality := NULL;
                    s_listedness := NULL;
            END;

            v_case_event_assess(v_index).case_id := pi_tcase_id;
            v_case_event_assess(v_index).event_seq_num := v_cau.event_seq_num;
            v_case_event_assess(v_index).prod_seq_num := v_cau.prod_seq_num;
            v_case_event_assess(v_index).seq_num := pkg_mg_util.f_mg_seq_num('CASE_EVENT_ASSESS', 'SEQ_NUM');
            v_case_event_assess(v_index).updated := pkg_mg_util.f_mg_key_val('Migration Date');
            v_case_event_assess(v_index).rpt_causality_id := pkg_mg_util.f_mg_codelist_code('Non_E2B', 'Causality', s_rpt_causality);

            v_case_event_assess(v_index).det_causality_id := pkg_mg_util.f_mg_codelist_code('Non_E2B', 'Causality', s_det_causality);

            IF v_case_event_assess(v_index).rpt_causality_id IS NOT NULL THEN
                v_case_event_assess(v_index).rpt_source_id := pkg_mg_util.f_mg_key_val('Reported Source Causality');
                v_case_event_assess(v_index).rpt_method_id := pkg_mg_util.f_mg_key_val('Causality Method');
            END IF;

            IF v_case_event_assess(v_index).det_causality_id IS NOT NULL THEN
                v_case_event_assess(v_index).det_source_id := pkg_mg_util.f_mg_key_val('Determined Source Causality');
                v_case_event_assess(v_index).det_method_id := pkg_mg_util.f_mg_key_val('Causality Method');
            END IF;

            v_case_event_assess(v_index).prt_source_id := NULL;
            v_case_event_assess(v_index).prt_method_id := NULL;
            v_case_event_assess(v_index).listed_justify := NULL;
            v_case_event_assess(v_index).cause_justify := NULL;
            v_case_event_assess(v_index).lam_assessed := 0;
            v_case_event_assess(v_index).causality_assessment := NULL;
            v_case_event_assess(v_index).causality_score := NULL;
            v_case_event_assess(v_index).source_id := NULL;
            v_case_event_assess(v_index).prt_causality_id := NULL;
            v_case_event_assess(v_index).last_update_time := pkg_mg_util.f_mg_key_val('Migration Date');
            v_case_event_assess(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
            v_case_event_assess(v_index).revision := NULL;
            v_case_event_assess(v_index).datasheet_id := 0;--check cannot insert null into this
            v_case_event_assess(v_index).license_id := 0; --check cannot insert null into this

            --Listeddness Loop
            FOR v_lic IN (
                SELECT
                    tlc.license_id,
                    tlc.datasheet_id,
                    lc.country
                FROM
                    tlm_license      tlc,
                    tlm_lic_products tllp,
                    tlm_countries    lc
                WHERE
                        tllp.license_id = tlc.license_id
                    AND tllp.product_id = nvl(v_cau.product_id, v_cau.pat_exposure)
                    AND lc.country_id = tlc.country_id
            ) LOOP
                v_index := v_index + 1;
                UPDATE s_producteventlevel spe
                SET
                    lic_map_cmnt = NULL
                WHERE
                        spe.case_number = v_cau.case_num
                    AND spe.prod_seq_num = v_cau.s_prod_seq_num
                    AND spe.event_seq_num = v_cau.s_event_seq_num
                    AND spe.listedness IS NOT NULL;

                l_tgt_lic_id := NULL;
                FOR v_list IN (
                    SELECT DISTINCT
                        suspect_product_trade_name,
                        license_number,
                        license_country,
                        listedness
                    FROM
                        s_producteventlevel spe
                    WHERE
                            spe.case_number = v_cau.case_num
                        AND spe.prod_seq_num = v_cau.s_prod_seq_num
                        AND spe.event_seq_num = v_cau.s_event_seq_num
                        AND spe.listedness IS NOT NULL
                ) LOOP
                    l_tgt_lic_id := pkg_mg_util.f_get_tgt_lic_id(v_list.suspect_product_trade_name, v_list.license_number, v_list.license_country
                    , v_cau.s_prod_seq_num, v_cau.s_event_seq_num,
                                                                 v_lic.license_id);

                    IF l_tgt_lic_id = v_lic.license_id THEN
                        v_case_event_assess(v_index).det_listedness_id := pkg_mg_util.f_mg_codelist_code('Non_E2B', 'Listedness', v_list.listedness
                        );

                    END IF;

                    --EXIT WHEN v_case_event_assess(v_index).det_listedness_id > 0;

                    IF
                        l_tgt_lic_id IS NULL
                        AND v_list.license_country = v_lic.country
                    THEN
                        l_tgt_lic_id := v_lic.license_id;
                        v_case_event_assess(v_index).det_listedness_id := pkg_mg_util.f_mg_codelist_code('Non_E2B', 'Listedness', v_list.listedness
                        );

                    END IF;

                END LOOP;

                UPDATE s_producteventlevel spe
                SET
                    lic_map_cmnt = 'Mapped to ' || l_tgt_lic_id
                WHERE
                        spe.case_number = v_cau.case_num
                    AND spe.prod_seq_num = v_cau.s_prod_seq_num
                    AND spe.event_seq_num = v_cau.s_event_seq_num
                    AND spe.listedness IS NOT NULL;

                v_case_event_assess(v_index).case_id := pi_tcase_id;
                v_case_event_assess(v_index).event_seq_num := v_cau.event_seq_num;
                v_case_event_assess(v_index).prod_seq_num := v_cau.prod_seq_num;
                v_case_event_assess(v_index).seq_num := pkg_mg_util.f_mg_seq_num('CASE_EVENT_ASSESS', 'SEQ_NUM');
                v_case_event_assess(v_index).updated := pkg_mg_util.f_mg_key_val('Migration Date');
                v_case_event_assess(v_index).listed_justify := NULL;
                v_case_event_assess(v_index).last_update_time := pkg_mg_util.f_mg_key_val('Migration Date');
                v_case_event_assess(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
                v_case_event_assess(v_index).revision := NULL;
                v_case_event_assess(v_index).datasheet_id := nvl(v_lic.datasheet_id, 0);--check cannot insert null into this
                v_case_event_assess(v_index).license_id := nvl(v_lic.license_id, 0);--check cannot insert null into this
                v_case_event_assess(v_index).lam_assessed := 0;--check cannot insert null into this
            END LOOP;

        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_event_assess VALUES v_case_event_assess ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_EVENT_assess ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_event_assess;

    PROCEDURE p_mg_case_comments (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS


        v_index         PLS_INTEGER := 0;
        TYPE v_case_comments_tab IS
            TABLE OF tcase_comments%rowtype INDEX BY PLS_INTEGER;
        v_case_comments v_case_comments_tab;
    BEGIN

            v_index := v_index + 1;
            v_case_comments(v_index).case_id := pi_tcase_id;
            begin

            select reportercomment
            into  v_case_comments(v_index).comment_txt
            from   s_summary ss 
            where ss.case_number=src_case_num;

            exception 
            when others then
             v_case_comments(v_index).comment_txt:=NULL;
        end;

            v_case_comments(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');


        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_comments VALUES v_case_comments ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_COMMENTS ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_comments;

    PROCEDURE p_mg_case_company_cmts (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        v_index             PLS_INTEGER := 0;
        TYPE v_case_company_cmts_tab IS
            TABLE OF tcase_company_cmts%rowtype INDEX BY PLS_INTEGER;
        v_case_company_cmts v_case_company_cmts_tab;
    BEGIN

            v_index := v_index + 1;
v_case_company_cmts(v_index).case_id := pi_tcase_id;

BEGIN
    SELECT
        sendercomment
    INTO v_case_company_cmts(v_index).comment_txt
    FROM
        s_summary
    WHERE
        case_number = src_case_num;

EXCEPTION
    WHEN OTHERS THEN
        v_case_company_cmts(v_index).comment_txt := NULL;
END;

v_case_company_cmts(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_company_cmts VALUES v_case_company_cmts ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_COMPANY_CMTS ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_company_cmts;

    PROCEDURE p_mg_case_lock_info (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_lock_info IS
        SELECT
            *
        FROM
            dual;

        v_index          PLS_INTEGER := 0;
        TYPE v_case_lock_info_tab IS
            TABLE OF tcase_lock_info%rowtype INDEX BY PLS_INTEGER;
        v_case_lock_info v_case_lock_info_tab;
    BEGIN
        FOR v_row IN c_case_lock_info LOOP
            v_index := v_index + 1;
            v_case_lock_info(v_index).case_id := NULL;
            v_case_lock_info(v_index).user_id := NULL;
            v_case_lock_info(v_index).time_locked := NULL;
            v_case_lock_info(v_index).lock_status := NULL;
            v_case_lock_info(v_index).deleted := NULL;
            v_case_lock_info(v_index).enterprise_id := NULL;
        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_lock_info VALUES v_case_lock_info ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_LOCK_INFO ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_lock_info;

    PROCEDURE p_mg_case_justifications (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_justifications IS
        SELECT
            *
        FROM
            dual;

        v_index               PLS_INTEGER := 0;
        TYPE v_case_justifications_tab IS
            TABLE OF tcase_justifications%rowtype INDEX BY PLS_INTEGER;
        v_case_justifications v_case_justifications_tab;
    BEGIN
        FOR v_row IN c_case_justifications LOOP
            v_index := v_index + 1;
            v_case_justifications(v_index).case_id := pi_tcase_id;
            v_case_justifications(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_justifications VALUES v_case_justifications ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_JUSTIFICATIONS ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_justifications;

    PROCEDURE p_mg_case_local_eva_comment (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_local_eva_comment IS
        SELECT
            *
        FROM
            dual;

        v_index                  PLS_INTEGER := 0;
        TYPE v_case_local_eva_comment_tab IS
            TABLE OF tcase_local_eva_comment%rowtype INDEX BY PLS_INTEGER;
        v_case_local_eva_comment v_case_local_eva_comment_tab;
    BEGIN
        FOR v_row IN c_case_local_eva_comment LOOP
            v_index := v_index + 1;
            v_case_local_eva_comment(v_index).case_id := NULL;
            v_case_local_eva_comment(v_index).evaluator_type_id := NULL;
            v_case_local_eva_comment(v_index).local_comment := NULL;
            v_case_local_eva_comment(v_index).deleted := NULL;
            v_case_local_eva_comment(v_index).enterprise_id := NULL;
        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_local_eva_comment VALUES v_case_local_eva_comment ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_LOCAL_EVA_COMMENT ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_local_eva_comment;

    PROCEDURE p_mg_case_narrative (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_narrative IS
        SELECT
            *
        FROM
            s_summary ssm
        WHERE
            ssm.case_number = src_case_num;

        v_index          PLS_INTEGER := 0;
        TYPE v_case_narrative_tab IS
            TABLE OF tcase_narrative%rowtype INDEX BY PLS_INTEGER;
        v_case_narrative v_case_narrative_tab;
    BEGIN
        FOR v_row IN c_case_narrative LOOP
            v_index := v_index + 1;
            v_case_narrative(v_index).case_id := pi_tcase_id;
            v_case_narrative(v_index).abbrev_narrative := NULL;--checked in target case narrative..this field is not populated.
            v_case_narrative(v_index).deleted := NULL;
            v_case_narrative(v_index).narrative := v_row.narrativeincludeclinical;
            v_case_narrative(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_narrative VALUES v_case_narrative ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_NARRATIVE ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_narrative;

    PROCEDURE p_mg_case_notes_attach (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS
    BEGIN
        INSERT /*+APPEND*/ INTO tcase_notes_attach
            SELECT
                pi_tcase_id,
                pkg_mg_util.f_mg_seq_num('CASE_NOTES_ATTACH', 'SEQ_NUM'),
                1,
                (
                    SELECT
                        classification_id
                    FROM
                        tlm_classification tlc
                    WHERE
                            tlc.classification = 'Legacy Sebela Attachments'
                        AND deleted IS NULL
                )                                 classification,
                sysdate,
                1,
                NULL,
                dbms_lob.getlength(rsm.file_data) blobsize,
                (
                    SELECT
                        nvl(max(sort_id) + 1,
                            1)
                    FROM
                        tcase_notes_attach
                    WHERE
                        case_id = pi_tcase_id
                )                                 sort_id,
                rsm.file_name,
                NULL,
                NULL,
                NULL,
                NULL,
                rsm.file_data,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                'Legacy Sebela Attachments',
                NULL,
                5,
                NULL
            FROM
                mg_case_addn_attachments rsm
            WHERE
                upper(trim(rsm.case_num)) = upper(trim(src_case_num));

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_NOTES_ATTACH ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_notes_attach;

    PROCEDURE p_mg_case_medwatch_data (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_medwatch_data IS
        SELECT
            *
        FROM
            dual;

        v_index              PLS_INTEGER := 0;
        TYPE v_case_medwatch_data_tab IS
            TABLE OF tcase_medwatch_data%rowtype INDEX BY PLS_INTEGER;
        v_case_medwatch_data v_case_medwatch_data_tab;
    BEGIN
        FOR v_row IN c_case_medwatch_data LOOP
            v_index := v_index + 1;
            v_case_medwatch_data(v_index).case_id := NULL;
            v_case_medwatch_data(v_index).evaluation := NULL;
            v_case_medwatch_data(v_index).adverse_event := NULL;
            v_case_medwatch_data(v_index).product_problem := NULL;
            v_case_medwatch_data(v_index).loc_hosp := NULL;
            v_case_medwatch_data(v_index).loc_home := NULL;
            v_case_medwatch_data(v_index).loc_nh := NULL;
            v_case_medwatch_data(v_index).loc_otf := NULL;
            v_case_medwatch_data(v_index).loc_odf := NULL;
            v_case_medwatch_data(v_index).loc_asf := NULL;
            v_case_medwatch_data(v_index).loc_other := NULL;
            v_case_medwatch_data(v_index).loc_other_text := NULL;
            v_case_medwatch_data(v_index).followup_type := NULL;
            v_case_medwatch_data(v_index).single_use := NULL;
            v_case_medwatch_data(v_index).mfg_date := NULL;
            v_case_medwatch_data(v_index).return_date := NULL;
            v_case_medwatch_data(v_index).meth_cd1 := NULL;
            v_case_medwatch_data(v_index).meth_cd2 := NULL;
            v_case_medwatch_data(v_index).meth_cd3 := NULL;
            v_case_medwatch_data(v_index).meth_cd4 := NULL;
            v_case_medwatch_data(v_index).res_cd1 := NULL;
            v_case_medwatch_data(v_index).res_cd2 := NULL;
            v_case_medwatch_data(v_index).res_cd3 := NULL;
            v_case_medwatch_data(v_index).res_cd4 := NULL;
            v_case_medwatch_data(v_index).conc_cd1 := NULL;
            v_case_medwatch_data(v_index).conc_cd2 := NULL;
            v_case_medwatch_data(v_index).conc_cd3 := NULL;
            v_case_medwatch_data(v_index).conc_cd4 := NULL;
            v_case_medwatch_data(v_index).fda_pat_cd1 := NULL;
            v_case_medwatch_data(v_index).fda_pat_cd2 := NULL;
            v_case_medwatch_data(v_index).fda_pat_cd3 := NULL;
            v_case_medwatch_data(v_index).fda_dev_cd1 := NULL;
            v_case_medwatch_data(v_index).fda_dev_cd2 := NULL;
            v_case_medwatch_data(v_index).fda_dev_cd3 := NULL;
            v_case_medwatch_data(v_index).dev_usage := NULL;
            v_case_medwatch_data(v_index).dev_oper := NULL;
            v_case_medwatch_data(v_index).dev_oper_other_text := NULL;
            v_case_medwatch_data(v_index).ndc := NULL;
            v_case_medwatch_data(v_index).catalog := NULL;
            v_case_medwatch_data(v_index).other := NULL;
            v_case_medwatch_data(v_index).facility_distributor := NULL;
            v_case_medwatch_data(v_index).uf_dist_report := NULL;
            v_case_medwatch_data(v_index).name_address := NULL;
            v_case_medwatch_data(v_index).cont_name := NULL;
            v_case_medwatch_data(v_index).cont_phone := NULL;
            v_case_medwatch_data(v_index).aware_date := NULL;
            v_case_medwatch_data(v_index).sent_fda := NULL;
            v_case_medwatch_data(v_index).sent_fda_date := NULL;
            v_case_medwatch_data(v_index).sent_manufacturer := NULL;
            v_case_medwatch_data(v_index).sent_manu_date := NULL;
            v_case_medwatch_data(v_index).report_source := NULL;
            v_case_medwatch_data(v_index).rs_other_text := NULL;
            v_case_medwatch_data(v_index).pre1938 := NULL;
            v_case_medwatch_data(v_index).otc := NULL;
            v_case_medwatch_data(v_index).event_type := NULL;
            v_case_medwatch_data(v_index).event_other := NULL;
            v_case_medwatch_data(v_index).mfr_evaluation := NULL;
            v_case_medwatch_data(v_index).mfr_no_code := NULL;
            v_case_medwatch_data(v_index).remedial_action := NULL;
            v_case_medwatch_data(v_index).remedial_other := NULL;
            v_case_medwatch_data(v_index).usc := NULL;
            v_case_medwatch_data(v_index).manu_narrative := NULL;
            v_case_medwatch_data(v_index).manu_corrected := NULL;
            v_case_medwatch_data(v_index).pla := NULL;
            v_case_medwatch_data(v_index).deleted := NULL;
            v_case_medwatch_data(v_index).narrative_text := NULL;
            v_case_medwatch_data(v_index).data_from_id := NULL;
            v_case_medwatch_data(v_index).facility_address_1 := NULL;
            v_case_medwatch_data(v_index).facility_address_2 := NULL;
            v_case_medwatch_data(v_index).facility_city := NULL;
            v_case_medwatch_data(v_index).facility_state := NULL;
            v_case_medwatch_data(v_index).facility_country_id := NULL;
            v_case_medwatch_data(v_index).facility_postal_code := NULL;
            v_case_medwatch_data(v_index).facility_sal := NULL;
            v_case_medwatch_data(v_index).facility_first_name := NULL;
            v_case_medwatch_data(v_index).facility_middle_name := NULL;
            v_case_medwatch_data(v_index).event_location := NULL;
            v_case_medwatch_data(v_index).enterprise_id := NULL;
            v_case_medwatch_data(v_index).facility_email := NULL;
        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_medwatch_data VALUES v_case_medwatch_data ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_MEDWATCH_DATA ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_medwatch_data;

    PROCEDURE p_mg_case_actions (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_actions IS
        SELECT
            *
        FROM
            dual;

        v_index        PLS_INTEGER := 0;
        TYPE v_case_actions_tab IS
            TABLE OF tcase_actions%rowtype INDEX BY PLS_INTEGER;
        v_case_actions v_case_actions_tab;
    BEGIN
        FOR v_row IN c_case_actions LOOP
            v_index := v_index + 1;
            v_case_actions(v_index).case_id := NULL;
            v_case_actions(v_index).seq_num := NULL;
            v_case_actions(v_index).user_id := NULL;
            v_case_actions(v_index).date_open := NULL;
            v_case_actions(v_index).date_due := NULL;
            v_case_actions(v_index).date_done := NULL;
            v_case_actions(v_index).description := NULL;
            v_case_actions(v_index).sort_id := NULL;
            v_case_actions(v_index).code := NULL;
            v_case_actions(v_index).group_id := NULL;
            v_case_actions(v_index).deleted := NULL;
            v_case_actions(v_index).action_status := NULL;
            v_case_actions(v_index).description_j := NULL;
            v_case_actions(v_index).sent_in_ltr := NULL;
            v_case_actions(v_index).enterprise_id := NULL;
            v_case_actions(v_index).category_id := NULL;
        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_actions VALUES v_case_actions ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_ACTIONS ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_actions;

    PROCEDURE p_mg_case_assess (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_assess IS
        SELECT
            *
        FROM
            dual;

        v_index       PLS_INTEGER := 0;
        TYPE v_case_assess_tab IS
            TABLE OF tcase_assess%rowtype INDEX BY PLS_INTEGER;
        v_case_assess v_case_assess_tab;
    BEGIN
        v_index := v_index + 1;
        v_case_assess(v_index).case_id := pi_tcase_id;
        v_case_assess(v_index).updated := pkg_mg_util.f_mg_key_val('Migration Date');
        v_case_assess(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');

    /* Case Level Causality */
    DECLARE
        L_CASE_ID           NUMBER := pi_tcase_id;
        L_CAUSALITY         NUMBER := NULL;
        L_CAUSALITY_NOTES   VARCHAR2(2000) := NULL;
        L_CAUSALITY_NOTES_J VARCHAR2(2000) := NULL;
        V_RETURN            NUMBER;
    BEGIN
        V_RETURN := ARGUS_APP.SF_CASE_CAUSALITY(    PI_CASE_ID              => L_CASE_ID,
                                                    PO_CAUSALITY            => L_CAUSALITY,
                                                    PO_CAUSALITY_NOTES      => L_CAUSALITY_NOTES,
                                                    PO_CAUSALITY_NOTES_J    => L_CAUSALITY_NOTES_J
                                                );
        
        --  Reassign above out parameters to local variables
        v_case_assess(v_index).agent_suspect    := L_CAUSALITY;
        v_case_assess(v_index).agent_notes      := L_CAUSALITY_NOTES;
        v_case_assess(v_index).agent_notes_j    := L_CAUSALITY_NOTES_J;
    END;

    /* Case Level Listedness */
    DECLARE
        L_CASE_ID               NUMBER := pi_tcase_id;
        L_LISTEDNESS            NUMBER := NULL;
        L_LISTEDNESS_NOTES      VARCHAR2(2000) := NULL;
        L_LISTEDNESS_NOTES_J    VARCHAR2(2000) := NULL;
        V_RETURN                NUMBER;
    BEGIN
        V_RETURN := ARGUS_APP.SF_CASE_LISTEDNESS(   PI_CASE_ID             => L_CASE_ID,
                                                    PO_LISTEDNESS          => L_LISTEDNESS,
                                                    PO_LISTEDNESS_NOTES    => L_LISTEDNESS_NOTES,
                                                    PO_LISTEDNESS_NOTES_J  => L_LISTEDNESS_NOTES_J
                                                );
        
        --  Reassign above out parameters to local variables
        v_case_assess(v_index).listedness           := L_LISTEDNESS;
        v_case_assess(v_index).listedness_notes     := L_LISTEDNESS_NOTES;
        v_case_assess(v_index).listedness_notes_j   := L_LISTEDNESS_NOTES_J;
    END;

    /* Case Level Seriousness */
    DECLARE
        L_CASE_ID           NUMBER := pi_tcase_id;
        L_SERIOUSNESS       NUMBER := NULL;
        L_SERIOUS_NOTES     VARCHAR2(2000) := NULL;
        L_SERIOUS_NOTES_J   VARCHAR2(2000) := NULL;
        V_RETURN            NUMBER;
    BEGIN
        V_RETURN := ARGUS_APP.SF_CASE_SERIOUSNESS(  PI_CASE_ID          => L_CASE_ID,
                                                    PO_SERIOUSNESS      => L_SERIOUSNESS,
                                                    PO_SERIOUS_NOTES    => L_SERIOUS_NOTES,
                                                    PO_SERIOUS_NOTES_J  => L_SERIOUS_NOTES_J
                                                );
        
        --  Reassign above out parameters to local variables
        v_case_assess(v_index).seriousness      := L_SERIOUSNESS;
        v_case_assess(v_index).serious_notes    := L_SERIOUS_NOTES;
        v_case_assess(v_index).serious_notes_j  := L_SERIOUS_NOTES_J;                                     
    END;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_assess VALUES v_case_assess ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_ASSESS ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_assess;

    PROCEDURE p_mg_case_contact_log (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) AS
    BEGIN
    -- TODO: Implementation required for PROCEDURE PKG_MG_MIGRATION.p_mg_case_contact_log
        NULL;
    END p_mg_case_contact_log;

    PROCEDURE p_mg_case_reporters (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_case_reporters IS
        SELECT
            ps.reportergivename,
            ps.reporterfamilyname,
            ps.qualification,
            ps.reporterorganization,
            ps.reporterstreet,
            ps.reporterdepartment,
            ps.reportercity,
            ps.reporterstate,
            ps.reporterpostcode,
            ps.reportercountry,
            ps.reportertitle,
            ps.reportermiddlename,
            ps.case_number,
                  PS.PRIMARYSOURCE_SEQ,
  SRL.AUTHORITY_NUMBER,
  SRL.ARGUS_SEQUENCE_NUMBER,
  SRL.ARGUS_DISPLAY_ORDER,
  SRL.REPORTER_TYPE,
  SRL.HCP_FLAG,
  SRL.REPORTER_FIRST_NAME,
  SRL.REPORTER_LAST_NAME,
  SRL.INSTITUTION_NAME,
  SRL.REPORTER_ADDRESS,
  SRL.FLAG_OF_PRIMARY_REPORTER,
  SRL.GEN_SEQ
        FROM
            s_primarysource ps
            inner join s_reporterlevel srl
            on ps.case_number=srl.case_number and ps.gen_seq=srl.gen_seq
        WHERE
            ps.case_number = src_case_num ORDER BY SRL.ARGUS_DISPLAY_ORDER;

        v_index          PLS_INTEGER := 0;
        TYPE v_case_reporters_tab IS
            TABLE OF tcase_reporters%rowtype INDEX BY PLS_INTEGER;
        v_case_reporters v_case_reporters_tab;
    BEGIN
        FOR v_row IN c_case_reporters LOOP
            v_index := v_index + 1;
            v_case_reporters(v_index).case_id := pi_tcase_id;
            v_case_reporters(v_index).seq_num := pkg_mg_util.f_mg_seq_num('CASE_REPORTERS', 'SEQ_NUM');
            v_case_reporters(v_index).sort_id := v_index;
            v_case_reporters(v_index).first_name := nvl(v_row.reportergivename,v_row.REPORTER_FIRST_NAME);
            v_case_reporters(v_index).last_name := nvl(v_row.reporterfamilyname,v_row.REPORTER_LAST_NAME);
            v_case_reporters(v_index).middle_name := v_row.reportermiddlename;
            v_case_reporters(v_index).institution := nvl(v_row.reporterorganization,v_row.INSTITUTION_NAME);
            v_case_reporters(v_index).address := nvl(v_row.reporterstreet,v_row.REPORTER_ADDRESS);
            v_case_reporters(v_index).department := v_row.reporterdepartment;
            v_case_reporters(v_index).city := v_row.reportercity;
            v_case_reporters(v_index).state := v_row.reporterstate;
            v_case_reporters(v_index).postcode := v_row.reporterpostcode;
            v_case_reporters(v_index).prefix := v_row.reportertitle;
            v_case_reporters(v_index).country_id := pkg_mg_util.f_mg_codelist_code('E2B', 'Countries', v_row.reportercountry);

            v_case_reporters(v_index).reporter_type := pkg_mg_util.f_mg_codelist_code('E2B', 'Reporter Type', v_row.qualification);
             v_case_reporters(v_index).country:= v_row.reportercountry;

            v_case_reporters(v_index).hcp_flag := case when UPPER(V_ROW.HCP_FLAG)=1 THEN 1
                                                    ELSE 0 END;
            V_CASE_REPORTERS(V_INDEX).PRIMARY_CONTACT:=case when UPPER(V_ROW.FLAG_OF_PRIMARY_REPORTER)='YES' THEN 1
                                                                WHEN UPPER(V_ROW.FLAG_OF_PRIMARY_REPORTER)='NO' THEN 0 
                                                                ELSE NULL END; 
            v_case_reporters(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');

            pkg_mg_util.p_insert_seq_mapping('S_PRIMARYSOURCE',
                                             'CASE_REPORTERS',
                                             'PRIMARYSOURCE_SEQ',
                                             'SEQ_NUM',
                                             V_ROW.PRIMARYSOURCE_SEQ,
                                                   v_case_reporters(v_index).seq_num);


        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_reporters VALUES v_case_reporters ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_REPORTERS ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_reporters;

    PROCEDURE p_mg_case_reference--HAVE TO BE ADDED.PLEASE KEEP A NOTE

     (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) AS

        CURSOR c_linked_report IS
        SELECT
            *
        FROM
            s_linkedreport
        WHERE
            case_number = src_case_num;

        CURSOR c_report_duplicate IS
        SELECT
            *
        FROM
            s_reportduplicate
        WHERE
            case_number = src_case_num;

        CURSOR c_company_numb IS
        SELECT
            *
        FROM
            S_SAFETYREPORT
        WHERE
            case_number = src_case_num;

        v_linkedreport_ref_type   NUMBER;
        v_dupicatereport_ref_type NUMBER;
        v_companynum_ref_type     NUMBER;
        v_index                   PLS_INTEGER := 0;
        TYPE v_case_reference_tab IS
            TABLE OF tcase_reference%rowtype INDEX BY PLS_INTEGER;
        v_case_reference          v_case_reference_tab;
    BEGIN
        SELECT
            ref_type_id
        INTO v_linkedreport_ref_type
        FROM
            tlm_ref_types
        WHERE
            type_desc = 'E2B Linked Report';

        SELECT
            ref_type_id
        INTO v_dupicatereport_ref_type
        FROM
            tlm_ref_types
        WHERE
            type_desc = 'E2B Report Duplicate';

        SELECT
            ref_type_id
        INTO v_companynum_ref_type
        FROM
            tlm_ref_types
        WHERE
            type_desc = 'E2B Company Number';

        FOR v_linked IN c_linked_report LOOP
            v_index := v_index + 1;
            v_case_reference(v_index).case_id := pi_tcase_id;
            v_case_reference(v_index).seq_num := pkg_mg_util.f_mg_seq_num('CASE_REFERENCE', 'SEQ_NUM');
            v_case_reference(v_index).ref_no := v_linked.linkreportnumb;
            v_case_reference(v_index).ref_type_id := v_linkedreport_ref_type;
            v_case_reference(v_index).sort_id := v_index;
            v_case_reference(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
        END LOOP;

        FOR v_duplicate IN c_report_duplicate LOOP
            v_index := v_index + 1;
            v_case_reference(v_index).case_id := pi_tcase_id;
            v_case_reference(v_index).seq_num := pkg_mg_util.f_mg_seq_num('CASE_REFERENCE', 'SEQ_NUM');
            v_case_reference(v_index).ref_no := v_duplicate.duplicatenumb;
            v_case_reference(v_index).ref_type_id := v_dupicatereport_ref_type;
            v_case_reference(v_index).sort_id := v_index;
            v_case_reference(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
        END LOOP;

        FOR v_comp_num IN c_company_numb LOOP
            v_index := v_index + 1;
            v_case_reference(v_index).case_id := pi_tcase_id;
            v_case_reference(v_index).seq_num := pkg_mg_util.f_mg_seq_num('CASE_REFERENCE', 'SEQ_NUM');
            v_case_reference(v_index).ref_no := v_comp_num.companynumb;
            v_case_reference(v_index).ref_type_id := v_dupicatereport_ref_type;
            v_case_reference(v_index).sort_id := v_index;
            v_case_reference(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
        END LOOP;

        v_index := v_index + 1;
        SELECT
            ref_type_id
        INTO v_case_reference(v_index).ref_type_id
        FROM
            tlm_ref_types
        WHERE
            type_desc = 'Migrated Case Number';

        v_case_reference(v_index).case_id := pi_tcase_id;
        v_case_reference(v_index).seq_num := pkg_mg_util.f_mg_seq_num('CASE_REFERENCE', 'SEQ_NUM');
        v_case_reference(v_index).ref_no := src_case_num;
        v_case_reference(v_index).sort_id := v_index;
        v_case_reference(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
        FOR i IN 1..v_index LOOP
            INSERT INTO tcase_reference VALUES v_case_reference ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_REFERENCE ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_reference;

    PROCEDURE p_mg_case_worklist (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) AS
    BEGIN
    -- TODO: Implementation required for PROCEDURE PKG_MG_MIGRATION.p_mg_case_worklist
        NULL;
    END p_mg_case_worklist;

   PROCEDURE p_mg_case_routing (
      src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) AS

        l_enterprise_id     tcase_routing.enterprise_id%TYPE ;
        l_comment_txt       VARCHAR(500) := 'Case locked, dummy routing for migration, Migrated from Sebela';
        l_sort_id           tcase_routing.sort_id%TYPE := 1;
        l_seq_num           tcase_routing.seq_num%TYPE := 1;
        l_report_scheduling NUMBER := 0;--confirm this
        l_fr_state_id       NUMBER := NULL;
        l_to_state_id       NUMBER := NULL;
        l_src_seq_value     NUMBER := 0;
        l_sfup              NUMBER := 0;
    BEGIN
       l_enterprise_id :=pkg_mg_util.f_mg_key_val('Enterprise Id');
        l_seq_num := pkg_mg_util.f_mg_seq_num('CASE_ROUTING', 'SEQ_NUM');

         SELECT
            state_id,
            last_state_id
        INTO
            l_to_state_id,
           l_fr_state_id
        FROM
            tcase_master
        WHERE
            case_id = pi_tcase_id;

        INSERT INTO tcase_routing (
            case_id,
            case_status,--cnf case status
            comment_txt,
            enterprise_id,
            followup_num,
            fr_state_id,
            justification_id,
            last_update_time,
            report_scheduling,
            route_date,
            s_followup_num,
            seq_num,
            sort_id,
            to_state_id,
            user_id,
            workflow_seq_num
        ) VALUES ( pi_tcase_id,
                   3,
                   l_comment_txt,
                   l_enterprise_id,
                   NULL,
                   l_fr_state_id,
                   NULL,
                   pkg_mg_util.f_mg_key_val('Migration Date'),
                   l_report_scheduling,
                   pkg_mg_util.f_mg_key_val('Migration Date'),
                   NULL,
                   l_seq_num,
                   l_sort_id,
                   l_to_state_id,
                   pkg_mg_util.f_mg_key_val('Migration User Id'),
                   NULL );

                       EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
              pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CASE_ROUTING' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_case_routing;

    PROCEDURE p_mg_case_null_flavor (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) AS
    BEGIN
    -- TODO: Implementation required for PROCEDURE PKG_MG_MIGRATION.p_mg_case_null_flavor
        NULL;
    END p_mg_case_null_flavor;

    PROCEDURE p_mg_case_local_lock (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) AS
    BEGIN
    -- TODO: Implementation required for PROCEDURE PKG_MG_MIGRATION.p_mg_case_local_lock
        NULL;
    END p_mg_case_local_lock;

    PROCEDURE p_mg_cmn_reg_reports (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

        CURSOR c_cmn_reg_reports IS
        SELECT
            ss.*,
            (
                SELECT
                    seq_num
                FROM
                    tcase_product
                WHERE
                        case_id = pi_tcase_id
                    AND first_sus_prod = 1
            ) t_prod_seq_num,
            (
                SELECT
                    CASE WHEN NVL(product_id,PAT_EXPOSURE)=0 THEN NULL
                    ELSE
                    NVL(product_id,PAT_EXPOSURE) END
                FROM
                    tcase_product
                WHERE
                        case_id = pi_tcase_id
                    AND first_sus_prod = 1
            ) t_prod_id,
            (SELECT SERIOUSNESS FROM TCASE_MASTER 
            WHERE CASE_NUM=SRC_CASE_NUM ) V_SERIOUSNESS,
            (select tlrt.INCL_TRIAL
            from tcase_master tcm
            inner join tlm_report_type tlrt
            on tlrt.rpt_type_id=tcm.rpt_type_id
            where tcm.case_num=ss.case_number
            ) clin_flag
        FROM
            s_submissionlevel ss
        WHERE
            ss.case_number = src_case_num;

        v_index            PLS_INTEGER := 0;
        TYPE v_cmn_reg_reports_tab IS
            TABLE OF tcmn_reg_reports%rowtype INDEX BY PLS_INTEGER;
        v_cmn_reg_reports  v_cmn_reg_reports_tab;

    /*case_reg_REPORT*/

        TYPE v_case_reg_reports_tab IS
            TABLE OF tcase_reg_reports%rowtype INDEX BY PLS_INTEGER;
        v_case_reg_reports v_case_reg_reports_tab;
    BEGIN
        FOR v_row IN c_cmn_reg_reports LOOP
            v_index := v_index + 1;
            v_cmn_reg_reports(v_index).reg_report_id := pkg_mg_util.f_mg_seq_num('CMN_REG_REPORTS', 'REG_REPORT_ID');



 v_cmn_reg_reports(v_index).schedule_date :=pkg_mg_util.f_var_to_date('cmn_reg_reports->date_scheduled',null,v_row.scheduled_date);

            v_cmn_reg_reports(v_index).date_scheduled := pkg_mg_util.f_var_to_date('cmn_reg_reports->date_scheduled',null,v_row.scheduled_date);

            v_cmn_reg_reports(v_index).date_generated := nvl(
            pkg_mg_util.f_var_to_date('cmn_reg_reports->report_generated_date',null,v_row.report_generated_date),
              v_cmn_reg_reports(v_index).date_scheduled 
            );

            v_cmn_reg_reports(v_index).date_submitted := nvl(
pkg_mg_util.f_var_to_date('cmn_reg_reports->report_submitted_date',null,v_row.report_submitted_date),
                v_cmn_reg_reports(v_index).date_generated
            );

 v_cmn_reg_reports(v_index).due_date := v_cmn_reg_reports(v_index).date_submitted ;
            v_cmn_reg_reports(v_index).date_approved :=  v_cmn_reg_reports(v_index).date_scheduled;

            v_cmn_reg_reports(v_index).date_submission_determined := null;

            v_cmn_reg_reports(v_index).product_id := v_row.t_prod_id;
            dbms_output.put_line('product_id->' || v_row.t_prod_id);
            BEGIN
                SELECT
                    tll.license_id
                INTO v_cmn_reg_reports(v_index).license_id
                FROM
                         tlm_lic_products tllp
                    INNER JOIN tlm_license tll ON ( tllp.license_id = tll.license_id )
                WHERE
                    tllp.product_id = v_row.t_prod_id;

            EXCEPTION
               WHEN no_data_found THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => pkg_mg_util.g_scase_num,
                pi_tcase_id     => pkg_mg_util.g_tcase_id,
                pi_message_type => 'WARNING',
                pi_message      => 'License Not found in CMN_REG_REPORT',
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

                   WHEN too_many_rows THEN
                   IF V_ROW.CLIN_FLAG=1 THEN

                    SELECT
                    tll.license_id
                INTO v_cmn_reg_reports(v_index).license_id
                FROM
                         tlm_lic_products tllp
                    INNER JOIN tlm_license tll ON ( tllp.license_id = tll.license_id )
                WHERE
                    tllp.product_id = v_row.t_prod_id AND TLL.LICENSE_TYPE_ID=1;
                    ELSE
                     SELECT
                    tll.license_id
                INTO v_cmn_reg_reports(v_index).license_id
                FROM
                         tlm_lic_products tllp
                    INNER JOIN tlm_license tll ON ( tllp.license_id = tll.license_id )
                WHERE
                    tllp.product_id = v_row.t_prod_id AND TLL.LICENSE_TYPE_ID=4;
                    END IF;

            END;

            v_cmn_reg_reports(v_index).prod_seq_num := v_row.t_prod_seq_num;

            v_cmn_reg_reports(v_index).last_state_id := 6;
            v_cmn_reg_reports(v_index).state_id := 6;
            v_cmn_reg_reports(v_index).report_form_type := NULL;
            v_cmn_reg_reports(v_index).group_id := NULL;
            v_cmn_reg_reports(v_index).determined_user_id := NULL;

            v_cmn_reg_reports(v_index).report_form_id := pkg_mg_util.f_mg_codelist_code('Non_E2B', 'Report Form', v_row.report_form);

            v_cmn_reg_reports(v_index).last_update_time := pkg_mg_util.f_mg_key_val('Migration Date');
            v_cmn_reg_reports(v_index).no_followup_downgrade := v_row.flag_of_downgrade_report;
            v_cmn_reg_reports(v_index).followup_num := nvl(v_row.followup_number, 0);
            v_cmn_reg_reports(v_index).rpt_comment := v_row.report_comments;
            v_cmn_reg_reports(v_index).owner_id := pkg_mg_util.f_mg_key_val('Migration User Id');
            v_cmn_reg_reports(v_index).agency_id := pkg_mg_util.f_mg_codelist_code('Non_E2B', 'Reporting Destination', v_row.reporting_destination
            );

            v_cmn_reg_reports(v_index).user_id := pkg_mg_util.f_mg_key_val('Migration User Id');
            v_cmn_reg_reports(v_index).tracking_num := src_case_num;
            v_cmn_reg_reports(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');


                v_cmn_reg_reports(v_index).aware_method := 0;
             v_cmn_reg_reports(v_index).TIMEFRAME := CASE WHEN V_ROW.V_SERIOUSNESS=1 THEN 15 
                                                                                    ELSE 30 END;
             v_cmn_reg_reports(v_index).MESSAGE_TYPE_ID:=1;
            v_cmn_reg_reports(v_index).auto_distribute_reports := 0;


            BEGIN

            select pref_term, pref_term_j, body_sys, body_sys_j
            into v_cmn_reg_reports(v_index).event,v_cmn_reg_reports(v_index).event_j
            ,v_cmn_reg_reports(v_index).body_sys,v_cmn_reg_reports(v_index).body_sys_j
            from tcase_event
            where case_id=pi_tcase_id
            and sort_id=(select min(sort_id) from tcase_event where case_id=pi_tcase_id);

            EXCEPTION
            WHEN OTHERS THEN 
            NULL;
            END;


--            pkg_mg_buss_rules.p_get_body_sys_event(v_cmn_reg_reports(v_index).body_sys,  v_cmn_reg_reports(v_index).event);
            v_case_reg_reports(v_index).enterprise_id := pkg_mg_util.f_mg_key_val('Enterprise Id');
            v_cmn_reg_reports(v_index).SUBMIT_REQUIRED:=1;
             v_cmn_reg_reports(v_index).AUTO_SCHED:=0;
             v_cmn_reg_reports(v_index).TEMPLATE_ID:=NULL;
             v_cmn_reg_reports(v_index).METHOD:=0;
             v_cmn_reg_reports(v_index).OUTPUT_STATUS:=0;
             v_cmn_reg_reports(v_index).PROTECT:=0;
             v_cmn_reg_reports(v_index).SUSAR:=1;
             v_cmn_reg_reports(v_index).BLIND_STUDY_PRODUCT:=0;
             v_cmn_reg_reports(v_index).NULLIFICATION:=0;
             v_cmn_reg_reports(v_index).PREV_ESM_RPT_ID:=-1;
             v_cmn_reg_reports(v_index).NO_FOLLOWUP_DOWNGRADE:=0;
             v_cmn_reg_reports(v_index).LOCAL_REPORT:=0;
             v_cmn_reg_reports(v_index).GENERATE_RPT:=1;
             v_cmn_reg_reports(v_index).AMENDMENT:=0;
             v_cmn_reg_reports(v_index).URGENT_REPORT:=0;

                select tcm.rev ,tcm.INIT_REPT_DATE,tcm.INIT_REPT_DATE
                into v_cmn_reg_reports(v_index).CASE_REV,
                v_cmn_reg_reports(v_index).aware_date,
                    v_cmn_reg_reports(v_index).SAFETY_DATE
                from tcase_master tcm 
                where  tcm.case_num=v_row.case_number;


                v_cmn_reg_reports(v_index).TEMPLATE_ID := 1;

            /*case_reg_report*/

            v_case_reg_reports(v_index).case_id := pi_tcase_id;
            v_case_reg_reports(v_index).seq_num := pkg_mg_util.f_mg_seq_num('CASE_REG_REPORTS', 'SEQ_NUM');
            v_case_reg_reports(v_index).reg_report_id := v_cmn_reg_reports(v_index).reg_report_id;
            v_case_reg_reports(v_index).date_assessed := NULL;
            v_case_reg_reports(v_index).sort_id := v_index;
           BEGIN
           SELECT 
           COUNTRY
           INTO  v_cmn_reg_reports(v_index).country_id 
           FROM tlm_regulatory_contact
           WHERE AGENCY_ID=v_cmn_reg_reports(v_index).AGENCY_ID;
           EXCEPTION
           WHEN OTHERS THEN
           v_cmn_reg_reports(v_index).country_id:=null;
           END;

           v_cmn_reg_reports(v_index).SUBMIT_NOTES:='Migrated from Sebela';
            pkg_mg_util.p_insert_seq_mapping('S_SUBMISSIONLEVEL',
                                             'CMN_REG_REPORTS',
                                             'SUBMISSION_ID',
                                             'REG_REPORT_ID',
                                             V_ROW.SUBMISSION_ID,
                                             v_cmn_reg_reports(v_index).reg_report_id);

        END LOOP;

        FOR i IN 1..v_index LOOP
            INSERT INTO tcmn_reg_reports VALUES v_cmn_reg_reports ( i );

            INSERT INTO tcase_reg_reports VALUES v_case_reg_reports ( i );

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_CMN_REG_REPORTS ' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_cmn_reg_reports;

    PROCEDURE p_mg_cfg_audit_log_pending (
       src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS
    BEGIN
        INSERT INTO tcfg_audit_log_pending (
            audit_by_dlp,
            case_id,
            create_time,
            dlp_revision,
            id,
            op_type,
            processed,
            processing_count,
            processing_user,
            user_id,
            enterprise_id
        )
            SELECT
                0,
                pi_tcase_id,
                pkg_mg_util.f_mg_key_val('Migration Date'),
                0,
                pkg_mg_util.f_mg_seq_num('CFG_AUDIT_LOG_PENDING', 'ID'),
                3,
                0,
                0,
                0,
                pkg_mg_util.f_mg_key_val('Migration User Id'),
                pkg_mg_util.f_mg_key_val('Enterprise Id')
            FROM
                dual;

    END p_mg_cfg_audit_log_pending;

 PROCEDURE p_mg_Audit_log (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) IS

Begin

     INSERT /*+APPEND*/ INTO tcase_notes_attach
     (CASE_ID,
     SEQ_NUM,
     BLOB_SEQ,classification,ENTRY_DATE,TYPE,E2B_ADD_DOC,BLOBSIZE,SORT_ID,FILETYPE,KEYWORDS,
LAM_ID,
LAM_NOTES_ATTACHMENT_ID,
DELETED,
DATA,
DOCUMENTUM_ID,
INCL_REG_SUB,
ESM_REPORT_ID,
KEYWORDS_J,
Enterprise_id,
NOTES,
NOTES_J
     )
            SELECT
                pi_tcase_id,
                pkg_mg_util.f_mg_seq_num('CASE_NOTES_ATTACH', 'SEQ_NUM'),
                1,
                (
                    SELECT
                        classification_id
                    FROM
                        tlm_classification tlc
                    WHERE
                            tlc.classification = 'Legacy Sebala Audit History'
                        AND deleted IS NULL
                )                           classification,
                sysdate,
                1,
                NULL,
                dbms_lob.getlength(content) blobsize,
                (
                    SELECT
                        MAX(sort_id) + 1
                    FROM
                        tcase_notes_attach
                    WHERE
                        case_id = pi_tcase_id
                )                           sort_id,
                File_name,
                NULL,
                NULL,
                NULL,
                NULL,
                content,
                NULL,
                NULL,
                NULL,
                NULL,
                pkg_mg_util.f_mg_key_val('Enterprise Id'),

                'Migrated Audit Log info file from Sebela',
                NULL
            FROM
                mg_audit_log_tmp
            WHERE
                case_num = SRC_CASE_NUM;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_mg_util.p_mg_log_message(
                pi_scase_num    => src_case_num,
                pi_tcase_id     => pi_tcase_id,
                pi_message_type => 'ERROR',
                pi_message      => 'P_MG_AUDIT_LOG' || dbms_utility.format_error_stack,
                pi_thread_id    => NULL,
                pi_date_time    => systimestamp
            );

            raise_application_error(-20001, sqlerrm);
    END p_mg_Audit_log;




    PROCEDURE p_mg_execution (
        pi_thread_id NUMBER,
        pi_scase_num VARCHAR2 DEFAULT NULL
    ) IS

        CURSOR case_cur IS
        SELECT
            *
        FROM
            mg_case_list
        WHERE
                exec_thread_id = pi_thread_id
            AND scasenum = nvl(pi_scase_num, scasenum)
            AND status = 0;

        v_message         mg_case_error_log.message_type%TYPE;
        v_msg_cnt         NUMBER := 0;
        v_msg_cnt_e       NUMBER := 0;
        v_msg_cnt_w       NUMBER := 0;
        v_mig_status_code NUMBER := 0;
    BEGIN
        vpd_admin.pkg_rls.set_context('SYSTEM', 5, 'ARGUS_SAFETY');
        FOR r IN case_cur LOOP
            v_msg_cnt := 0;
            v_msg_cnt_e := 0;
            v_msg_cnt_w := 0;
            v_mig_status_code := 1;
            pkg_mg_util.g_scase_num := r.scasenum;
            pkg_mg_util.g_tcase_id := r.tcaseid;
            DELETE FROM mg_case_error_log
            WHERE
                tcase_id = r.tcaseid;

            DELETE FROM mg_st_sequence_map
            WHERE
                tcaseid = r.tcaseid;

            BEGIN
                pkg_mg_migration.p_mg_case_master(r.scasenum, r.tcaseid);
                pkg_mg_migration.p_mg_case_study(r.scasenum, r.tcaseid);
             --   pkg_mg_migration.p_mg_case_followup(r.scasenum, r.tcaseid);
                pkg_mg_migration.p_mg_case_literature(r.scasenum, r.tcaseid);
         --       pkg_mg_migration.p_mg_case_classifications(r.scasenum, r.tcaseid);
                pkg_mg_migration.p_mg_case_pat_info(r.scasenum, r.tcaseid);
                pkg_mg_migration.p_mg_case_pat_hist(r.scasenum, r.tcaseid);
                pkg_mg_migration.p_mg_case_lab_data(r.scasenum, r.tcaseid);
                pkg_mg_migration.p_mg_case_pat_tests(r.scasenum, r.tcaseid);
           --     pkg_mg_migration.p_mg_case_parent_info(r.scasenum, r.tcaseid);
              --  pkg_mg_migration.p_mg_case_pat_race(r.scasenum, r.tcaseid);
              --  pkg_mg_migration.p_mg_case_pregnancy(r.scasenum, r.tcaseid);
              --  pkg_mg_migration.p_mg_case_neonates(r.scasenum, r.tcaseid);
                pkg_mg_migration.p_mg_case_event(r.scasenum, r.tcaseid);
         --       pkg_mg_migration.p_mg_case_hosp(r.scasenum, r.tcaseid);
                pkg_mg_migration.p_mg_case_product(r.scasenum, r.tcaseid);
                --dbms_output.put_line('N');
                pkg_mg_migration.p_mg_case_prod_ingredient(r.scasenum, r.tcaseid);
         pkg_mg_migration.p_mg_case_prod_indications(r.scasenum, r.tcaseid);
            --    pkg_mg_migration.p_mg_case_death(r.scasenum, r.tcaseid);
             --   pkg_mg_migration.p_mg_case_death_details(r.scasenum, r.tcaseid);
           --     pkg_mg_migration.p_mg_case_event_detail(r.scasenum, r.tcaseid);
                pkg_mg_migration.p_mg_case_event_assess(r.scasenum, r.tcaseid);
                pkg_mg_migration.p_mg_case_comments(r.scasenum, r.tcaseid);
                pkg_mg_migration.p_mg_case_company_cmts(r.scasenum, r.tcaseid);
--           pkg_mg_migration.p_mg_case_lock_info(r.scasenum, r.tcaseid);
             --   pkg_mg_migration.p_mg_case_justifications(r.scasenum, r.tcaseid);
              --  pkg_mg_migration.p_mg_case_local_eva_comment(r.scasenum, r.tcaseid);
                pkg_mg_migration.p_mg_case_narrative(r.scasenum, r.tcaseid);
             pkg_mg_migration.p_mg_case_notes_attach(r.scasenum, r.tcaseid);
                --pkg_mg_migration.p_mg_case_medwatch_data(r.scasenum, r.tcaseid);
              --  pkg_mg_migration.p_mg_case_actions(r.scasenum, r.tcaseid);
                pkg_mg_migration.p_mg_case_assess(r.scasenum, r.tcaseid);
            --    pkg_mg_migration.p_mg_case_pmda_license(r.scasenum, r.tcaseid);
         --       pkg_mg_migration.p_mg_case_pmda_notes(r.scasenum, r.tcaseid);
                pkg_mg_migration.p_mg_case_reporters(r.scasenum, r.tcaseid);
                pkg_mg_migration.p_mg_case_reference(r.scasenum, r.tcaseid);
--                pkg_mg_migration.p_mg_case_user_defined(r.scasenum, r.tcaseid);
               -- pkg_mg_migration.p_mg_case_worklist(r.scasenum, r.tcaseid);
                pkg_mg_migration.p_mg_case_routing(r.scasenum, r.tcaseid);
         --       pkg_mg_migration.p_mg_case_null_flavor(r.scasenum, r.tcaseid);
             --   pkg_mg_migration.p_mg_case_local_lock(r.scasenum, r.tcaseid);
           --     pkg_mg_migration.p_mg_case_contact_log(r.scasenum, r.tcaseid);
                pkg_mg_migration.p_mg_cmn_reg_reports(r.scasenum, r.tcaseid);
                pkg_mg_migration.p_mg_Audit_log(r.scasenum, r.tcaseid);
             --   pkg_mg_migration.p_mg_rpt_saved_msg(r.scasenum, r.tcaseid);
             pkg_mg_migration.p_mg_cfg_audit_log_pending(r.scasenum, r.tcaseid);
              --  p_post_migration(r.scasenum, r.tcaseid);

            /*Updating Migration Status*/
               SELECT
                    COUNT(1)
                INTO v_msg_cnt
                FROM
                    mg_case_error_log mel
                WHERE
                    tcase_id = r.tcaseid;

                SELECT
                    COUNT(1)
                INTO v_msg_cnt_w
                FROM
                    mg_case_error_log mel
                WHERE
                        tcase_id = r.tcaseid
                    AND message_type = 'WARNING';

                SELECT
                    COUNT(1)
                INTO v_msg_cnt_e
                FROM
                    mg_case_error_log mel
                WHERE
                        tcase_id = r.tcaseid
                    AND message_type = 'ERROR';

                IF
                    v_msg_cnt > 0
                    AND v_msg_cnt_w > 0
                THEN
                    v_mig_status_code := 3;
                ELSE
                    v_mig_status_code := 4;
                END IF;

                IF
                    v_msg_cnt > 0
                    AND v_msg_cnt_e > 0
                THEN
                 v_mig_status_code := 2;
                 END IF;
    update
    mg_case_list
    set
    status = v_mig_status_code
    where
        tcaseid = r.tcaseid;
        commit;
        commit;
    exception
    when
    others
    then
        rollback;
        pkg_mg_util.p_mg_log_message ( pi_scase_num =>
            pkg_mg_util.g_scase_num, pi_tcase_id =>
                pkg_mg_util.g_tcase_id, pi_message_type =>
                    'ERROR', pi_message =>
                        'Error in Executing Migration for Case Id'
                        || pkg_mg_util.g_tcase_id
                        || ', '
                        || dbms_utility.format_error_backtrace
                        || ', ' || sqlerrm, pi_thread_id =>
                            NULL, pi_date_time => systimestamp
        );
    update
    mg_case_list
    set
    status = 2
    where
        tcaseid = pkg_mg_util.g_tcase_id;
        commit;
        end;
    end
        loop;
    exception
    when
    others
    then
        rollback;
        pkg_mg_util.p_mg_log_message ( pi_scase_num =>
            pkg_mg_util.g_scase_num, pi_tcase_id =>
                pkg_mg_util.g_tcase_id, pi_message_type =>
                    'ERROR', pi_message =>
                        'Error in Executing Migration '
                        || dbms_utility.format_error_backtrace
                        || ' , ' || sqlerrm, pi_thread_id =>
                            NULL, pi_date_time => systimestamp
        );
    update
    mg_case_list
    set
    status = 2
    where
        tcaseid = pkg_mg_util.g_tcase_id;
        commit;
    end
        p_mg_execution;
    procedure
    p_execute_migration_job
    ( pi_exec_thread_id IN number )
        is
    v_job
        number;
    begin
        dbms_job.submit ( job =>
            v_job, what =>
                'BEGIN
                    PKG_MG_MIGRATION.p_mg_execution('
                || pi_exec_thread_id || ');
                  END;', next_date =>
                    sysdate,  -- run immediately
                     interval => NULL      -- no repeat, runs once
        );
        commit;  -- important: job only created after commit
    exception
    when
    others
    then
        raise;
    END p_execute_migration_job;

END pkg_mg_migration;

create or replace PACKAGE BODY pkg_cleanup_argus AS

    g_tgt_case_id NUMBER;
    v_err         VARCHAR2(500);

    PROCEDURE p_cleanup (
        pi_batch_no    NUMBER,
        pi_case_number VARCHAR2 DEFAULT NULL
    ) AS

        CURSOR c_case_cleanup IS
        SELECT
            mcl.tcaseid,mcl.tcasenum
        FROM
            mg_case_list mcl
        WHERE
                mcl.exec_thread_id = pi_batch_no
            AND nvl(pi_case_number, tcasenum) = tcasenum;

v_case_number VARCHAR2(1000):=0;

    BEGIN
        FOR rec IN c_case_cleanup LOOP
        BEGIN
            g_tgt_case_id := NULL;
            g_tgt_case_id := rec.tcaseid;
            v_case_number:=rec.tcasenum;
            DELETE FROM argus_app.case_e2battachment_status
            WHERE
                case_id = rec.tcaseid;

            --COMMIT;

            DELETE FROM argus_app.user_case_assignment
            WHERE
                case_id = rec.tcaseid;

                DELETE FROM argus_app.cmn_audit_log
            WHERE
                case_id = rec.tcaseid;

                DELETE FROM argus_app.case_null_flavor
            WHERE
                case_id = rec.tcaseid;
            --COMMIT;

            DELETE FROM argus_app.user_case_processing_time
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;
DELETE FROM tcase_lock_info WHERE case_id=rec.tcaseid;

            DELETE FROM tcase_local_lock
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;





            DELETE FROM tcfg_audit_log_pending
            WHERE
                case_id = rec.tcaseid;

            DELETE FROM tcase_actions
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;

            DELETE FROM tcase_letters
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;

            DELETE FROM tcase_eu_device
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;

            DELETE FROM tcase_assess
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;

            DELETE FROM tcase_access
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;

            DELETE FROM tcase_justifications
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;

            DELETE FROM tcase_literature
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;

            DELETE FROM tcase_event_detail
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;

            DELETE FROM tcase_neonates
            WHERE
                case_id = rec.tcaseid;
           --COMMIT;

            DELETE FROM tcase_medwatch_data
            WHERE
                case_id = rec.tcaseid;
           --COMMIT;

            DELETE FROM tcase_hosp
            WHERE
                case_id = rec.tcaseid;
           --COMMIT;

            DELETE FROM tcase_contact_log
            WHERE
                case_id = rec.tcaseid;
           --COMMIT;

            DELETE FROM tcase_lab_data
            WHERE
                case_id = rec.tcaseid;
           --COMMIT;

            DELETE FROM tcase_classifications
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;

            DELETE FROM tcase_pat_tests
            WHERE
                rel_test_id = rec.tcaseid;
           --COMMIT;

           DELETE FROM tcase_pat_race
            WHERE
                case_id = rec.tcaseid;

            DELETE FROM tcase_pregnancy
            WHERE
                case_id = rec.tcaseid;
           --COMMIT;

            DELETE FROM tcase_notes_attach
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;

            DELETE FROM tcase_company_cmts
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;

            DELETE FROM tcase_comments
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;

            DELETE FROM tcase_narrative
            WHERE
                case_id = rec.tcaseid;
           --COMMIT;

            DELETE FROM tcase_parent_info
            WHERE
                case_id = rec.tcaseid;
           --COMMIT;

            DELETE FROM tcase_pat_hist
            WHERE
                case_id = rec.tcaseid;
           --COMMIT;

            DELETE FROM tcase_reference
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;

            DELETE FROM tcase_event_nature
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;

            DELETE FROM tcase_event_imputability
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;

            DELETE FROM tcase_event_rech_prod
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;

            DELETE FROM tcase_event_assess
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;

            DELETE FROM tcase_pat_info
            WHERE
                case_id = rec.tcaseid;
           --COMMIT;

            DELETE FROM tcase_routing
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;

            DELETE FROM tcase_followup
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;

            DELETE FROM tcase_study
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;

            DELETE FROM tcase_reporters
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;

            DELETE FROM tcase_death_details
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;

            DELETE FROM tcase_death
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;

            DELETE FROM tcase_event
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;

            DELETE FROM tcase_dose_regimens
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;

            DELETE FROM tcase_prod_drugs
            WHERE
                case_id = rec.tcaseid;
         --COMMIT;

            DELETE FROM tcase_prod_devices
            WHERE
                case_id = rec.tcaseid;
       --COMMIT;

            DELETE FROM tcase_prod_indications
            WHERE
                case_id = rec.tcaseid;
           --COMMIT;

            DELETE FROM tcase_prod_ingredient
            WHERE
                case_id = rec.tcaseid;
           --COMMIT;

           DELETE FROM tcase_pmda_notes
            WHERE
                case_id = rec.tcaseid;

                 DELETE FROM tcase_pmda_license
            WHERE
                case_id = rec.tcaseid;

            DELETE FROM tcase_product
            WHERE
                case_id = rec.tcaseid;

                 DELETE FROM tcase_reg_reports
                    WHERE
                        case_id = rec.tcaseid;
          --COMMIT;

            BEGIN
                FOR rec_report IN (
                    SELECT
                        cmrr.reg_report_id
                    FROM
                        tcase_reg_reports crr,
                        tcmn_reg_reports  cmrr
                    WHERE
                            crr.case_id = rec.tcaseid
                        AND crr.reg_report_id = cmrr.reg_report_id
                ) LOOP
                    DELETE FROM trpt_saved_msg
                    WHERE
                        reg_report_id = rec_report.reg_report_id;
      --COMMIT;

                    DELETE FROM tcase_reg_reports
                    WHERE
                        reg_report_id = rec_report.reg_report_id;
            --COMMIT;
 DELETE FROM TRPT_TRANSMIT_LOG
            WHERE
                pdf_id IN (select pdf_id from trpt_pdf where  reg_report_id = rec_report.reg_report_id
                );

                    DELETE FROM trpt_pdf
                    WHERE
                        reg_report_id = rec_report.reg_report_id;


      --COMMIT;

                    DELETE FROM trpt_routing
                    WHERE
                        reg_report_id = rec_report.reg_report_id;
      --COMMIT;

                    DELETE FROM tcmn_reg_reports
                    WHERE
                        reg_report_id = rec_report.reg_report_id;


      --COMMIT;

                END LOOP;
            END;

            DELETE FROM trpt_routing
            where reg_Report_id in (select reg_Report_id from tcmn_reg_reports
                    WHERE
                        tracking_num = v_case_number);

                        DELETE FROM trpt_saved_msg
            where reg_Report_id in (select reg_Report_id from tcmn_reg_reports
                    WHERE
                        tracking_num = v_case_number);

                  DELETE FROM trpt_transmit_log
                  where pdf_id in (select pdf_id from trpt_pdf
            where reg_Report_id in (select reg_Report_id from tcmn_reg_reports
                    WHERE
                        tracking_num = v_case_number));


                        DELETE FROM trpt_pdf
            where reg_Report_id in (select reg_Report_id from tcmn_reg_reports
                    WHERE
                        tracking_num = v_case_number);

                        DELETE FROM tcase_Reg_Reports
            where reg_Report_id in (select reg_Report_id from tcmn_reg_reports
                    WHERE
                        tracking_num = v_case_number);

             DELETE FROM tcmn_reg_reports
                    WHERE
                        tracking_num = v_case_number;

            delete from tcase_local_eva_comment
            WHERE
                case_id = rec.tcaseid;

            DELETE FROM tcase_worklist
            WHERE
                case_id = rec.tcaseid;



            DELETE FROM tcase_master
            WHERE
                case_id = rec.tcaseid;
          --COMMIT;

            DELETE FROM mg_st_sequence_map dsm
            WHERE
                dsm.tcaseid = rec.tcaseid;

                DELETE FROM MG_CASE_ERROR_LOG dsm
            WHERE
                dsm.tcase_id = rec.tcaseid;
          --COMMIT;
          UPDATE MG_CASE_LIST
          SET STATUS=0
          WHERE tcaseid=rec.tcaseid;

        /*  delete from mg_audit_log_tmp
          where case_num=v_case_number;*/

            COMMIT;


                                 end;
        END LOOP;

	----COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            v_err := sqlerrm;


    END p_cleanup;

END pkg_cleanup_argus;
/
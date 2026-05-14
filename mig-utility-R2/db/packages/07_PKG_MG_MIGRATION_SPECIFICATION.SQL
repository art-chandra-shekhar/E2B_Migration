create or replace PACKAGE pkg_mg_migration IS
  PROCEDURE p_mg_case_master (
    src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
  );
  PROCEDURE p_mg_case_study (
       src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

    PROCEDURE p_mg_case_followup (
        src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

    PROCEDURE p_mg_case_literature (
        src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

    PROCEDURE p_mg_case_event (
        src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

    PROCEDURE p_mg_case_product (
       src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

    PROCEDURE p_mg_case_classifications (
       src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

    PROCEDURE p_mg_case_death (
       src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

    PROCEDURE p_mg_case_contact_log (
       src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

    PROCEDURE p_mg_case_event_detail (
       src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

    PROCEDURE p_mg_case_prod_ingredient (
      src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

    PROCEDURE p_mg_case_actions (
      src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

  

    PROCEDURE p_mg_case_assess (
       src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

    PROCEDURE p_mg_case_death_details (
       src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );


    PROCEDURE p_mg_case_comments (
       src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

    

    PROCEDURE p_mg_case_event_assess (
       src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

    PROCEDURE p_mg_case_lock_info (
       src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

    PROCEDURE p_mg_case_hosp (
      src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

    PROCEDURE p_mg_case_justifications (
       src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

    PROCEDURE p_mg_case_lab_data (
       src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

    PROCEDURE p_mg_case_local_eva_comment (
       src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

    PROCEDURE p_mg_case_narrative (
       src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

    PROCEDURE p_mg_case_neonates (
       src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

    PROCEDURE p_mg_case_notes_attach (
        src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

    PROCEDURE p_mg_case_medwatch_data (
        src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

    PROCEDURE p_mg_case_parent_info (
       src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

  PROCEDURE p_mg_case_pat_hist
(
      src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

PROCEDURE p_mg_case_pat_info
(
src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );



PROCEDURE p_mg_case_pregnancy
(
       src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );


PROCEDURE p_mg_case_reporters
(
      src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );
PROCEDURE p_mg_case_prod_indications
(
       src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

    PROCEDURE p_mg_case_reference
(
       src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );


    PROCEDURE p_mg_case_worklist
(
       src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

    PROCEDURE p_mg_case_routing
(
       src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );

PROCEDURE p_mg_case_null_flavor
(
       src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );
    PROCEDURE p_mg_case_pat_race
(
       src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );
    
    
    PROCEDURE p_mg_case_local_lock
(
       src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );
    
      
    PROCEDURE p_mg_cmn_reg_reports
(
       src_case_num IN VARCHAR2,
    pi_tcase_id  IN NUMBER
    );
     PROCEDURE p_mg_Audit_log (
        src_case_num IN VARCHAR2,
        pi_tcase_id  IN NUMBER
    ) ;
      PROCEDURE P_MG_EXECUTION(pi_thread_id NUMBER,
   pi_scase_num VARCHAR2 DEFAULT NULL);
      PROCEDURE P_EXECUTE_MIGRATION_JOB(PI_EXEC_THREAD_ID IN NUMBER);
      

END pkg_mg_migration;
/
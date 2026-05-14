-- Purpose:
--   One-time data fix to align USER_NAME with USER_EMAIL for requested configuration scope,
--   and enqueue corresponding rows in ARGUS_APP.CFG_AUDIT_LOG_PENDING.
--
-- Scope:
--   1) ARGUS_APP.CFG_USERS
--   2) ARGUS_APP.CFG_USER_ENTERPRISE_APPS
--   3) ARGUS_APP.USER_ACCESS_STUDY       (if exists)
--   4) ARGUS_APP.USER_ACCESS_PRODUCT     (if exists)
--
-- Notes:
--   - Fixed audit user id is set to 2, as requested.
--   - Script is rerunnable; updates only rows where values differ.
--   - USER_ACCESS_* tables are handled conditionally because they are not present in the checked-in model.

SET SERVEROUTPUT ON SIZE UNLIMITED;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

DECLARE
  c_audit_user_id CONSTANT NUMBER := 2;

  v_updated_cfg_users           NUMBER := 0;
  v_updated_cfg_user_ent_apps   NUMBER := 0;
  v_updated_user_access_study   NUMBER := 0;
  v_updated_user_access_product NUMBER := 0;
  v_audit_inserted              NUMBER := 0;

  v_audit_seq_exists NUMBER := 0;
  v_audit_id_seed    NUMBER := 0;
  v_dummy            NUMBER := 0;

  FUNCTION fq_table(p_table_name IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN 'ARGUS_APP.' || UPPER(TRIM(p_table_name));
  END fq_table;

  FUNCTION table_exists(p_table_name IN VARCHAR2) RETURN BOOLEAN IS
    v_count NUMBER;
  BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM all_tables
     WHERE owner = 'ARGUS_APP'
       AND table_name = UPPER(TRIM(p_table_name));
    RETURN v_count > 0;
  END table_exists;

  FUNCTION column_exists(p_table_name IN VARCHAR2, p_column_name IN VARCHAR2) RETURN BOOLEAN IS
    v_count NUMBER;
  BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM all_tab_cols
     WHERE owner = 'ARGUS_APP'
       AND table_name = UPPER(TRIM(p_table_name))
       AND column_name = UPPER(TRIM(p_column_name));
    RETURN v_count > 0;
  END column_exists;

  FUNCTION has_deleted_column(p_table_name IN VARCHAR2) RETURN BOOLEAN IS
  BEGIN
    RETURN column_exists(p_table_name => p_table_name, p_column_name => 'DELETED');
  END has_deleted_column;

  FUNCTION next_audit_id RETURN NUMBER IS
    v_id NUMBER;
  BEGIN
    IF v_audit_seq_exists = 1 THEN
      EXECUTE IMMEDIATE 'SELECT ARGUS_APP.S_CFG_AUDIT_LOG_PENDING.NEXTVAL FROM dual' INTO v_id;
      RETURN v_id;
    END IF;

    v_audit_id_seed := v_audit_id_seed + 1;
    RETURN v_audit_id_seed;
  END next_audit_id;

  PROCEDURE insert_audit_row(
    p_table_name    IN VARCHAR2,
    p_item_seq_num  IN NUMBER,
    p_pk2_field_val IN NUMBER,
    p_data          IN CLOB,
    p_enterprise_id IN NUMBER
  ) IS
  BEGIN
    INSERT INTO ARGUS_APP.CFG_AUDIT_LOG_PENDING (
      ID,
      OP_TYPE,
      USER_ID,
      TABLE_NAME,
      ITEM_SEQ_NUM,
      PK2_FIELD_VAL,
      PROCESSED,
      CREATE_TIME,
      DATA,
      AUDIT_BY_DLP,
      DLP_REVISION,
      PROCESSING_COUNT,
      ENTERPRISE_ID
    ) VALUES (
      next_audit_id(),
      1, -- List Maintenance
      c_audit_user_id,
      UPPER(p_table_name),
      p_item_seq_num,
      p_pk2_field_val,
      0,
      SYSDATE,
      p_data,
      0,
      0,
      0,
      NVL(p_enterprise_id, SYS_CONTEXT('Argus_ctx', 'enterprise_id'))
    );
    v_audit_inserted := v_audit_inserted + 1;
  END insert_audit_row;

  FUNCTION precheck_count_direct(
    p_table_name  IN VARCHAR2,
    p_user_name   IN VARCHAR2,
    p_user_email  IN VARCHAR2
  ) RETURN NUMBER IS
    v_count NUMBER := 0;
    v_sql   VARCHAR2(4000);
  BEGIN
    v_sql := 'SELECT COUNT(*) FROM ' || fq_table(p_table_name) ||
             ' t WHERE t.' || p_user_email || ' IS NOT NULL' ||
             ' AND NVL(TRIM(t.' || p_user_name || '), ''~NULL~'') <> NVL(TRIM(t.' || p_user_email || '), ''~NULL~'')';

    IF has_deleted_column(p_table_name) THEN
      v_sql := v_sql || ' AND t.DELETED IS NULL';
    END IF;

    EXECUTE IMMEDIATE v_sql INTO v_count;
    RETURN v_count;
  END precheck_count_direct;

  FUNCTION precheck_count_join_user(
    p_table_name IN VARCHAR2
  ) RETURN NUMBER IS
    v_count NUMBER := 0;
    v_sql   VARCHAR2(4000);
  BEGIN
    v_sql := 'SELECT COUNT(*) FROM ' || fq_table(p_table_name) || ' t ' ||
             'JOIN ARGUS_APP.CFG_USERS cu ON cu.USER_ID = t.USER_ID ' ||
             'WHERE cu.USER_EMAIL IS NOT NULL ' ||
             'AND NVL(TRIM(t.USER_NAME), ''~NULL~'') <> NVL(TRIM(cu.USER_EMAIL), ''~NULL~'')';

    IF has_deleted_column(p_table_name) THEN
      v_sql := v_sql || ' AND t.DELETED IS NULL';
    END IF;

    v_sql := v_sql || ' AND cu.DELETED IS NULL';

    EXECUTE IMMEDIATE v_sql INTO v_count;
    RETURN v_count;
  END precheck_count_join_user;

BEGIN
  DBMS_OUTPUT.PUT_LINE('--- USER_NAME -> USER_EMAIL update with audit start ---');

  SELECT COUNT(*)
    INTO v_dummy
    FROM ARGUS_APP.CFG_USERS
   WHERE USER_ID = c_audit_user_id
     AND DELETED IS NULL;

  IF v_dummy = 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Audit user id ' || c_audit_user_id || ' not found in ARGUS_APP.CFG_USERS.');
  END IF;

  IF NOT table_exists('CFG_AUDIT_LOG_PENDING') THEN
    RAISE_APPLICATION_ERROR(-20002, 'ARGUS_APP.CFG_AUDIT_LOG_PENDING does not exist.');
  END IF;

  SELECT COUNT(*)
    INTO v_audit_seq_exists
    FROM all_sequences
   WHERE sequence_owner = 'ARGUS_APP'
     AND sequence_name = 'S_CFG_AUDIT_LOG_PENDING';

  IF v_audit_seq_exists = 0 THEN
    SELECT NVL(MAX(ID), 0)
      INTO v_audit_id_seed
      FROM ARGUS_APP.CFG_AUDIT_LOG_PENDING;
  END IF;

  DBMS_OUTPUT.PUT_LINE('Precheck counts:');
  DBMS_OUTPUT.PUT_LINE('  CFG_USERS: ' || precheck_count_direct('CFG_USERS', 'USER_NAME', 'USER_EMAIL'));
  DBMS_OUTPUT.PUT_LINE('  CFG_USER_ENTERPRISE_APPS: ' ||
    (
      SELECT COUNT(*)
        FROM ARGUS_APP.CFG_USER_ENTERPRISE_APPS cuea
        JOIN ARGUS_APP.CFG_USERS cu
          ON cu.USER_NAME = cuea.USER_NAME
       WHERE cu.USER_EMAIL IS NOT NULL
         AND cu.DELETED IS NULL
         AND NVL(TRIM(cuea.USER_NAME), '~NULL~') <> NVL(TRIM(cu.USER_EMAIL), '~NULL~')
    )
  );

  IF table_exists('USER_ACCESS_STUDY') AND column_exists('USER_ACCESS_STUDY', 'USER_NAME') THEN
    IF column_exists('USER_ACCESS_STUDY', 'USER_EMAIL') THEN
      DBMS_OUTPUT.PUT_LINE('  USER_ACCESS_STUDY (direct): ' ||
        precheck_count_direct('USER_ACCESS_STUDY', 'USER_NAME', 'USER_EMAIL'));
    ELSIF column_exists('USER_ACCESS_STUDY', 'USER_ID') THEN
      DBMS_OUTPUT.PUT_LINE('  USER_ACCESS_STUDY (join CFG_USERS): ' ||
        precheck_count_join_user('USER_ACCESS_STUDY'));
    ELSE
      DBMS_OUTPUT.PUT_LINE('  USER_ACCESS_STUDY: skipped (no USER_EMAIL/USER_ID mapping columns)');
    END IF;
  ELSE
    DBMS_OUTPUT.PUT_LINE('  USER_ACCESS_STUDY: table or USER_NAME column not found, skipping');
  END IF;

  IF table_exists('USER_ACCESS_PRODUCT') AND column_exists('USER_ACCESS_PRODUCT', 'USER_NAME') THEN
    IF column_exists('USER_ACCESS_PRODUCT', 'USER_EMAIL') THEN
      DBMS_OUTPUT.PUT_LINE('  USER_ACCESS_PRODUCT (direct): ' ||
        precheck_count_direct('USER_ACCESS_PRODUCT', 'USER_NAME', 'USER_EMAIL'));
    ELSIF column_exists('USER_ACCESS_PRODUCT', 'USER_ID') THEN
      DBMS_OUTPUT.PUT_LINE('  USER_ACCESS_PRODUCT (join CFG_USERS): ' ||
        precheck_count_join_user('USER_ACCESS_PRODUCT'));
    ELSE
      DBMS_OUTPUT.PUT_LINE('  USER_ACCESS_PRODUCT: skipped (no USER_EMAIL/USER_ID mapping columns)');
    END IF;
  ELSE
    DBMS_OUTPUT.PUT_LINE('  USER_ACCESS_PRODUCT: table or USER_NAME column not found, skipping');
  END IF;

  -- 1) CFG_USER_ENTERPRISE_APPS first, before CFG_USERS USER_NAME changes.
  FOR r IN (
    SELECT cuea.ROWID AS rid,
           cuea.USER_NAME AS old_user_name,
           cuea.APP_NAME,
           cuea.ENTERPRISE_ID,
           cu.USER_EMAIL AS new_user_name
      FROM ARGUS_APP.CFG_USER_ENTERPRISE_APPS cuea
      JOIN ARGUS_APP.CFG_USERS cu
        ON cu.USER_NAME = cuea.USER_NAME
     WHERE cu.USER_EMAIL IS NOT NULL
       AND cu.DELETED IS NULL
       AND NVL(TRIM(cuea.USER_NAME), '~NULL~') <> NVL(TRIM(cu.USER_EMAIL), '~NULL~')
  ) LOOP
    UPDATE ARGUS_APP.CFG_USER_ENTERPRISE_APPS
       SET USER_NAME = r.new_user_name
     WHERE ROWID = r.rid;

    v_updated_cfg_user_ent_apps := v_updated_cfg_user_ent_apps + SQL%ROWCOUNT;

    insert_audit_row(
      p_table_name    => 'CFG_USER_ENTERPRISE_APPS',
      p_item_seq_num  => NULL,
      p_pk2_field_val => NULL,
      p_data          => 'APP_NAME=' || r.APP_NAME ||
                         ';OLD_USER_NAME=' || r.old_user_name ||
                         ';NEW_USER_NAME=' || r.new_user_name,
      p_enterprise_id => r.ENTERPRISE_ID
    );
  END LOOP;

  -- 2) CFG_USERS
  FOR r IN (
    SELECT cu.ROWID AS rid,
           cu.USER_ID,
           cu.USER_NAME AS old_user_name,
           cu.USER_EMAIL AS new_user_name,
           cu.ENTERPRISE_ID
      FROM ARGUS_APP.CFG_USERS cu
     WHERE cu.USER_EMAIL IS NOT NULL
       AND cu.DELETED IS NULL
       AND NVL(TRIM(cu.USER_NAME), '~NULL~') <> NVL(TRIM(cu.USER_EMAIL), '~NULL~')
  ) LOOP
    UPDATE ARGUS_APP.CFG_USERS
       SET USER_NAME = r.new_user_name
     WHERE ROWID = r.rid;

    v_updated_cfg_users := v_updated_cfg_users + SQL%ROWCOUNT;

    insert_audit_row(
      p_table_name    => 'CFG_USERS',
      p_item_seq_num  => r.USER_ID,
      p_pk2_field_val => NULL,
      p_data          => 'USER_ID=' || r.USER_ID ||
                         ';OLD_USER_NAME=' || r.old_user_name ||
                         ';NEW_USER_NAME=' || r.new_user_name,
      p_enterprise_id => r.ENTERPRISE_ID
    );
  END LOOP;

  -- 3) USER_ACCESS_STUDY (if present)
  IF table_exists('USER_ACCESS_STUDY') AND column_exists('USER_ACCESS_STUDY', 'USER_NAME') THEN
    IF column_exists('USER_ACCESS_STUDY', 'USER_EMAIL') THEN
      FOR r IN (
        SELECT t.ROWID AS rid,
               t.USER_NAME AS old_user_name,
               t.USER_EMAIL AS new_user_name
          FROM ARGUS_APP.USER_ACCESS_STUDY t
         WHERE t.USER_EMAIL IS NOT NULL
           AND NVL(TRIM(t.USER_NAME), '~NULL~') <> NVL(TRIM(t.USER_EMAIL), '~NULL~')
      ) LOOP
        UPDATE ARGUS_APP.USER_ACCESS_STUDY
           SET USER_NAME = r.new_user_name
         WHERE ROWID = r.rid;
        v_updated_user_access_study := v_updated_user_access_study + SQL%ROWCOUNT;
        insert_audit_row(
          p_table_name    => 'USER_ACCESS_STUDY',
          p_item_seq_num  => NULL,
          p_pk2_field_val => NULL,
          p_data          => 'OLD_USER_NAME=' || r.old_user_name || ';NEW_USER_NAME=' || r.new_user_name,
          p_enterprise_id => NULL
        );
      END LOOP;
    ELSIF column_exists('USER_ACCESS_STUDY', 'USER_ID') THEN
      FOR r IN (
        SELECT t.ROWID AS rid,
               t.USER_ID,
               t.USER_NAME AS old_user_name,
               cu.USER_EMAIL AS new_user_name,
               cu.ENTERPRISE_ID AS enterprise_id
          FROM ARGUS_APP.USER_ACCESS_STUDY t
          JOIN ARGUS_APP.CFG_USERS cu
            ON cu.USER_ID = t.USER_ID
         WHERE cu.USER_EMAIL IS NOT NULL
           AND cu.DELETED IS NULL
           AND NVL(TRIM(t.USER_NAME), '~NULL~') <> NVL(TRIM(cu.USER_EMAIL), '~NULL~')
      ) LOOP
        UPDATE ARGUS_APP.USER_ACCESS_STUDY
           SET USER_NAME = r.new_user_name
         WHERE ROWID = r.rid;
        v_updated_user_access_study := v_updated_user_access_study + SQL%ROWCOUNT;
        insert_audit_row(
          p_table_name    => 'USER_ACCESS_STUDY',
          p_item_seq_num  => r.USER_ID,
          p_pk2_field_val => NULL,
          p_data          => 'USER_ID=' || r.USER_ID ||
                             ';OLD_USER_NAME=' || r.old_user_name ||
                             ';NEW_USER_NAME=' || r.new_user_name,
          p_enterprise_id => r.enterprise_id
        );
      END LOOP;
    END IF;
  END IF;

  -- 4) USER_ACCESS_PRODUCT (if present)
  IF table_exists('USER_ACCESS_PRODUCT') AND column_exists('USER_ACCESS_PRODUCT', 'USER_NAME') THEN
    IF column_exists('USER_ACCESS_PRODUCT', 'USER_EMAIL') THEN
      FOR r IN (
        SELECT t.ROWID AS rid,
               t.USER_NAME AS old_user_name,
               t.USER_EMAIL AS new_user_name
          FROM ARGUS_APP.USER_ACCESS_PRODUCT t
         WHERE t.USER_EMAIL IS NOT NULL
           AND NVL(TRIM(t.USER_NAME), '~NULL~') <> NVL(TRIM(t.USER_EMAIL), '~NULL~')
      ) LOOP
        UPDATE ARGUS_APP.USER_ACCESS_PRODUCT
           SET USER_NAME = r.new_user_name
         WHERE ROWID = r.rid;
        v_updated_user_access_product := v_updated_user_access_product + SQL%ROWCOUNT;
        insert_audit_row(
          p_table_name    => 'USER_ACCESS_PRODUCT',
          p_item_seq_num  => NULL,
          p_pk2_field_val => NULL,
          p_data          => 'OLD_USER_NAME=' || r.old_user_name || ';NEW_USER_NAME=' || r.new_user_name,
          p_enterprise_id => NULL
        );
      END LOOP;
    ELSIF column_exists('USER_ACCESS_PRODUCT', 'USER_ID') THEN
      FOR r IN (
        SELECT t.ROWID AS rid,
               t.USER_ID,
               t.USER_NAME AS old_user_name,
               cu.USER_EMAIL AS new_user_name,
               cu.ENTERPRISE_ID AS enterprise_id
          FROM ARGUS_APP.USER_ACCESS_PRODUCT t
          JOIN ARGUS_APP.CFG_USERS cu
            ON cu.USER_ID = t.USER_ID
         WHERE cu.USER_EMAIL IS NOT NULL
           AND cu.DELETED IS NULL
           AND NVL(TRIM(t.USER_NAME), '~NULL~') <> NVL(TRIM(cu.USER_EMAIL), '~NULL~')
      ) LOOP
        UPDATE ARGUS_APP.USER_ACCESS_PRODUCT
           SET USER_NAME = r.new_user_name
         WHERE ROWID = r.rid;
        v_updated_user_access_product := v_updated_user_access_product + SQL%ROWCOUNT;
        insert_audit_row(
          p_table_name    => 'USER_ACCESS_PRODUCT',
          p_item_seq_num  => r.USER_ID,
          p_pk2_field_val => NULL,
          p_data          => 'USER_ID=' || r.USER_ID ||
                             ';OLD_USER_NAME=' || r.old_user_name ||
                             ';NEW_USER_NAME=' || r.new_user_name,
          p_enterprise_id => r.enterprise_id
        );
      END LOOP;
    END IF;
  END IF;

  DBMS_OUTPUT.PUT_LINE('Post-update summary:');
  DBMS_OUTPUT.PUT_LINE('  CFG_USER_ENTERPRISE_APPS updated: ' || v_updated_cfg_user_ent_apps);
  DBMS_OUTPUT.PUT_LINE('  CFG_USERS updated: ' || v_updated_cfg_users);
  DBMS_OUTPUT.PUT_LINE('  USER_ACCESS_STUDY updated: ' || v_updated_user_access_study);
  DBMS_OUTPUT.PUT_LINE('  USER_ACCESS_PRODUCT updated: ' || v_updated_user_access_product);
  DBMS_OUTPUT.PUT_LINE('  CFG_AUDIT_LOG_PENDING inserted: ' || v_audit_inserted);

  DBMS_OUTPUT.PUT_LINE('Postcheck counts:');
  DBMS_OUTPUT.PUT_LINE('  CFG_USERS remaining diffs: ' || precheck_count_direct('CFG_USERS', 'USER_NAME', 'USER_EMAIL'));
  DBMS_OUTPUT.PUT_LINE('  CFG_USER_ENTERPRISE_APPS remaining diffs: ' ||
    (
      SELECT COUNT(*)
        FROM ARGUS_APP.CFG_USER_ENTERPRISE_APPS cuea
        JOIN ARGUS_APP.CFG_USERS cu
          ON cu.USER_EMAIL = cuea.USER_NAME
       WHERE cu.USER_EMAIL IS NOT NULL
         AND cu.DELETED IS NULL
         AND NVL(TRIM(cuea.USER_NAME), '~NULL~') <> NVL(TRIM(cu.USER_EMAIL), '~NULL~')
    )
  );

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('--- Completed successfully ---');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    RAISE;
END;
/

-- Optional verification queries after run:
-- SELECT COUNT(*) AS cfg_users_diff
--   FROM ARGUS_APP.CFG_USERS
--  WHERE USER_EMAIL IS NOT NULL
--    AND DELETED IS NULL
--    AND NVL(TRIM(USER_NAME), '~NULL~') <> NVL(TRIM(USER_EMAIL), '~NULL~');
--
-- SELECT TABLE_NAME, COUNT(*) AS pending_count
--   FROM ARGUS_APP.CFG_AUDIT_LOG_PENDING
--  WHERE USER_ID = 2
--    AND OP_TYPE = 1
--    AND CREATE_TIME >= (SYSDATE - (15/1440))
--  GROUP BY TABLE_NAME
--  ORDER BY TABLE_NAME;

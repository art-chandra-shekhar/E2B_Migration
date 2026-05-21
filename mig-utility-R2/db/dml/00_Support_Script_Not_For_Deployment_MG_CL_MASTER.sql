-- Populate MG_CL_MASTER table
declare
    v_col1 varchar2(30);
    v_col2 varchar2(30);

    cursor ccur is 
        select code_list_desc as cl_name,
               src_table_name as t_cl_table,
               substr(src_table_name,4) as t_cl_code_col,
               substr(src_table_name,4)||'_ID' as t_cl_decode_col,
               src_table_filter as t_where_cond
          from argus_app.code_list_master 
        where src_table_name is not null and src_table_name not like 'V$%' 
        order by code_list_desc;
begin
    -- Delete existing records from MG_CL_MASTER table
    delete from mg_cl_master;
    -- Loop through code list master table
    for rec in ccur
    loop
        v_col1 := null;
        begin
            select column_name into v_col1
              from all_tab_columns 
             where table_name = rec.t_cl_table and table_name not like 'V$%' and column_name = rec.t_cl_code_col;
        exception
            when no_data_found then
                v_col1 := '';
        end;
        
        v_col2 := null;
        begin
            select column_name into v_col2
              from all_tab_columns 
             where table_name = rec.t_cl_table and table_name not like 'V$%' and column_name = rec.t_cl_decode_col;
        exception
            when no_data_found then
                v_col2 := '';
        end;

        insert into mg_cl_master(cl_name, t_cl_table, t_cl_code_col, t_cl_decode_col, t_where_cond)
        values(rec.cl_name, rec.t_cl_table, v_col1, v_col2, rec.t_where_cond);
    end loop;    
    commit;
end;
/

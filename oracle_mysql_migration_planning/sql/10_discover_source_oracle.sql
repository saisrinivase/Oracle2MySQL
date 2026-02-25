set define on
set verify off
set feedback on

define RUN_ID='&1'
define OWNER_FILTER='&2'

prompt Running DISCOVER stage...
prompt RUN_ID       = &&RUN_ID
prompt OWNER_FILTER = &&OWNER_FILTER

delete from omm_discover_index_expr where run_id = &&RUN_ID;
delete from omm_discover_mviews where run_id = &&RUN_ID;
delete from omm_discover_scheduler_jobs where run_id = &&RUN_ID;
delete from omm_discover_db_links where run_id = &&RUN_ID;
delete from omm_discover_dependencies where run_id = &&RUN_ID;
delete from omm_discover_code where run_id = &&RUN_ID;
delete from omm_discover_columns where run_id = &&RUN_ID;
delete from omm_discover_tables where run_id = &&RUN_ID;
delete from omm_discover_objects where run_id = &&RUN_ID;

insert into omm_discover_objects (
  run_id, owner, object_name, object_type, status, created, last_ddl_time
)
select
  &&RUN_ID,
  o.owner,
  o.object_name,
  o.object_type,
  o.status,
  o.created,
  o.last_ddl_time
from all_objects o
where o.owner like upper('&&OWNER_FILTER')
  and o.owner not in (
    'SYS', 'SYSTEM', 'XDB', 'MDSYS', 'CTXSYS', 'OUTLN',
    'ORDSYS', 'DBSNMP', 'GSMADMIN_INTERNAL'
  )
  and o.object_type in (
    'TABLE', 'VIEW', 'MATERIALIZED VIEW', 'INDEX', 'SEQUENCE', 'SYNONYM',
    'PROCEDURE', 'FUNCTION', 'PACKAGE', 'PACKAGE BODY',
    'TRIGGER', 'TYPE', 'TYPE BODY'
  );

insert into omm_discover_tables (
  run_id, owner, table_name, num_rows, blocks, avg_row_len, partitioned,
  temporary, compression, iot_type, last_analyzed
)
select
  &&RUN_ID,
  t.owner,
  t.table_name,
  t.num_rows,
  t.blocks,
  t.avg_row_len,
  t.partitioned,
  t.temporary,
  t.compression,
  t.iot_type,
  t.last_analyzed
from all_tables t
where t.owner like upper('&&OWNER_FILTER')
  and t.owner not in (
    'SYS', 'SYSTEM', 'XDB', 'MDSYS', 'CTXSYS', 'OUTLN',
    'ORDSYS', 'DBSNMP', 'GSMADMIN_INTERNAL'
  );

insert into omm_discover_columns (
  run_id, owner, table_name, column_name, data_type, data_length,
  data_precision, data_scale, nullable, char_used
)
select
  &&RUN_ID,
  c.owner,
  c.table_name,
  c.column_name,
  c.data_type,
  c.data_length,
  c.data_precision,
  c.data_scale,
  c.nullable,
  c.char_used
from all_tab_columns c
join all_tables t
  on t.owner = c.owner
 and t.table_name = c.table_name
where c.owner like upper('&&OWNER_FILTER')
  and c.owner not in (
    'SYS', 'SYSTEM', 'XDB', 'MDSYS', 'CTXSYS', 'OUTLN',
    'ORDSYS', 'DBSNMP', 'GSMADMIN_INTERNAL'
  );

insert into omm_discover_code (
  run_id, owner, object_name, object_type, line_count
)
select
  &&RUN_ID,
  s.owner,
  s.name,
  s.type,
  count(*) as line_count
from all_source s
where s.owner like upper('&&OWNER_FILTER')
  and s.owner not in (
    'SYS', 'SYSTEM', 'XDB', 'MDSYS', 'CTXSYS', 'OUTLN',
    'ORDSYS', 'DBSNMP', 'GSMADMIN_INTERNAL'
  )
  and s.type in (
    'PROCEDURE', 'FUNCTION', 'PACKAGE', 'PACKAGE BODY', 'TRIGGER', 'TYPE', 'TYPE BODY'
  )
group by s.owner, s.name, s.type;

insert into omm_discover_dependencies (
  run_id, owner, name, type, referenced_owner, referenced_name, referenced_type, referenced_link_name
)
select
  &&RUN_ID,
  d.owner,
  d.name,
  d.type,
  d.referenced_owner,
  d.referenced_name,
  d.referenced_type,
  d.referenced_link_name
from all_dependencies d
where d.owner like upper('&&OWNER_FILTER')
  and d.owner not in (
    'SYS', 'SYSTEM', 'XDB', 'MDSYS', 'CTXSYS', 'OUTLN',
    'ORDSYS', 'DBSNMP', 'GSMADMIN_INTERNAL'
  );

insert into omm_discover_db_links (
  run_id, owner, db_link, username, host
)
select
  &&RUN_ID,
  l.owner,
  l.db_link,
  l.username,
  l.host
from all_db_links l
where l.owner like upper('&&OWNER_FILTER')
   or l.owner = 'PUBLIC';

insert into omm_discover_scheduler_jobs (
  run_id, owner, job_name, enabled, state, program_name, schedule_type
)
select
  &&RUN_ID,
  j.owner,
  j.job_name,
  j.enabled,
  j.state,
  j.program_name,
  j.schedule_type
from all_scheduler_jobs j
where j.owner like upper('&&OWNER_FILTER');

insert into omm_discover_mviews (
  run_id, owner, mview_name, refresh_mode, refresh_method, build_mode, last_refresh_type, last_refresh_date
)
select
  &&RUN_ID,
  m.owner,
  m.mview_name,
  m.refresh_mode,
  m.refresh_method,
  m.build_mode,
  m.last_refresh_type,
  m.last_refresh_date
from all_mviews m
where m.owner like upper('&&OWNER_FILTER');

insert into omm_discover_index_expr (
  run_id, index_owner, index_name, table_owner, table_name, column_expression
)
select
  &&RUN_ID,
  i.index_owner,
  i.index_name,
  x.table_owner,
  x.table_name,
  i.column_expression
from all_ind_expressions i
join all_indexes x
  on x.owner = i.index_owner
 and x.index_name = i.index_name
where i.index_owner like upper('&&OWNER_FILTER');

commit;

prompt DISCOVER stage complete.

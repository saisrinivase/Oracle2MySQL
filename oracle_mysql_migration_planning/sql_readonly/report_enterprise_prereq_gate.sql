set define on
set verify off
set feedback off
set heading off
set pagesize 0
set linesize 32767
set trimspool on
set termout on

define SCHEMA_FILTER='&1'
define REPORT_DIR='&2'
define SOURCE_DB_VERSION='&3'
define SOURCE_VCPUS='&4'
define SOURCE_SGA_GB='&5'
define SOURCE_PGA_LIMIT_GB='&6'

spool "&&REPORT_DIR/enterprise_prereq_gate.html"

prompt <!DOCTYPE html>
prompt <html lang="en">
prompt <head>
prompt <meta charset="utf-8">
prompt <title>Enterprise Pre-Req Gate</title>
prompt <style>
prompt body { font-family: Arial, sans-serif; margin: 24px; background: #f7f9fc; color: #1f2937; }
prompt h1, h2 { margin: 0 0 12px 0; }
prompt .card { background: #ffffff; border: 1px solid #e5e7eb; border-radius: 10px; padding: 16px; margin-bottom: 16px; }
prompt table { border-collapse: collapse; width: 100%; }
prompt th, td { border: 1px solid #d1d5db; padding: 8px; text-align: left; vertical-align: top; }
prompt .pass { color: #166534; font-weight: 700; }
prompt .warn { color: #b45309; font-weight: 700; }
prompt .fail { color: #b91c1c; font-weight: 700; }
prompt .nav { margin-bottom: 16px; }
prompt a { color: #0f4c81; text-decoration: none; }
prompt a:hover { text-decoration: underline; }
prompt </style>
prompt </head>
prompt <body>
prompt <h1>Enterprise Pre-Requisite Gate</h1>
prompt <div class="nav"><a href="source_intelligence.html">Source Intelligence</a> | <a href="sct_decision_matrix.html">SCT Decision Matrix</a></div>

prompt <div class="card">
prompt <h2>Gate Checks</h2>
prompt <table>
prompt <tr><th>Check</th><th>Observed Value</th><th>Status</th><th>Action</th></tr>
with m as (
  select
    (select count(distinct owner) from all_objects where owner like upper('&&SCHEMA_FILTER')) as owner_cnt,
    (select count(*) from all_tables where owner like upper('&&SCHEMA_FILTER')) as table_cnt,
    (select count(*) from all_dependencies where owner like upper('&&SCHEMA_FILTER') and (referenced_owner is null or referenced_owner <> owner)) as cross_schema_out_cnt,
    (select count(*) from all_objects where owner like upper('&&SCHEMA_FILTER') and object_type in ('PACKAGE', 'PACKAGE BODY')) as package_cnt,
    (select count(*) from all_mviews where owner like upper('&&SCHEMA_FILTER')) as mview_cnt,
    (select count(*) from all_db_links where owner like upper('&&SCHEMA_FILTER')) as dblink_cnt,
    (select count(*) from all_tab_columns where owner like upper('&&SCHEMA_FILTER') and data_type in ('LONG', 'LONG RAW', 'BFILE', 'XMLTYPE', 'UROWID')) as legacy_col_cnt,
    (select count(*) from (
      select owner, object_name from all_objects where owner like upper('&&SCHEMA_FILTER') and length(object_name) > 64
      union all
      select owner, column_name from all_tab_columns where owner like upper('&&SCHEMA_FILTER') and length(column_name) > 64
    )) as overlength_name_cnt,
    (select count(*) from all_tables where owner like upper('&&SCHEMA_FILTER')
      and (last_analyzed is null or last_analyzed < sysdate - 30)) as stale_stats_table_cnt
  from dual
)
select '<tr><td>Schema visibility</td><td>' || to_char(owner_cnt) || ' owner(s)</td><td>' ||
       case when owner_cnt > 0 then '<span class="pass">PASS</span>' else '<span class="fail">FAIL</span>' end ||
       '</td><td>Confirm schema filter and privileges.</td></tr>'
from m
union all
select '<tr><td>Table inventory availability</td><td>' || to_char(table_cnt) || ' table(s)</td><td>' ||
       case when table_cnt > 0 then '<span class="pass">PASS</span>' else '<span class="fail">FAIL</span>' end ||
       '</td><td>POC schema should contain representative transactional tables.</td></tr>'
from m
union all
select '<tr><td>Cross-schema outbound dependencies</td><td>' || to_char(cross_schema_out_cnt) || '</td><td>' ||
       case
         when cross_schema_out_cnt = 0 then '<span class="pass">PASS</span>'
         when cross_schema_out_cnt <= 50 then '<span class="warn">WARN</span>'
         else '<span class="fail">FAIL</span>'
       end ||
       '</td><td>Coordinate object owners and define blast-radius controls.</td></tr>'
from m
union all
select '<tr><td>Package / MView / DB Link hotspots</td><td>' ||
       to_char(package_cnt + mview_cnt + dblink_cnt) || ' total</td><td>' ||
       case
         when package_cnt + mview_cnt + dblink_cnt = 0 then '<span class="pass">PASS</span>'
         when package_cnt + mview_cnt + dblink_cnt <= 20 then '<span class="warn">WARN</span>'
         else '<span class="fail">FAIL</span>'
       end ||
       '</td><td>Estimate manual rewrite effort before committing migration window.</td></tr>'
from m
union all
select '<tr><td>Legacy datatype blockers</td><td>' || to_char(legacy_col_cnt) || ' column(s)</td><td>' ||
       case
         when legacy_col_cnt = 0 then '<span class="pass">PASS</span>'
         when legacy_col_cnt <= 10 then '<span class="warn">WARN</span>'
         else '<span class="fail">FAIL</span>'
       end ||
       '</td><td>Define datatype refactor backlog and target mappings.</td></tr>'
from m
union all
select '<tr><td>Identifiers > 64 chars</td><td>' || to_char(overlength_name_cnt) || '</td><td>' ||
       case
         when overlength_name_cnt = 0 then '<span class="pass">PASS</span>'
         when overlength_name_cnt <= 25 then '<span class="warn">WARN</span>'
         else '<span class="fail">FAIL</span>'
       end ||
       '</td><td>Rename before DDL freeze for Aurora MySQL.</td></tr>'
from m
union all
select '<tr><td>Statistics freshness (30 days)</td><td>' || to_char(stale_stats_table_cnt) || ' stale table(s)</td><td>' ||
       case
         when stale_stats_table_cnt = 0 then '<span class="pass">PASS</span>'
         when stale_stats_table_cnt <= 50 then '<span class="warn">WARN</span>'
         else '<span class="fail">FAIL</span>'
       end ||
       '</td><td>Refresh source stats for better sizing and risk estimates.</td></tr>'
from m;
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>Overall Gate Decision</h2>
prompt <table>
prompt <tr><th>Decision</th><th>Interpretation</th><th>Next Step</th></tr>
with m as (
  select
    (select count(distinct owner) from all_objects where owner like upper('&&SCHEMA_FILTER')) as owner_cnt,
    (select count(*) from all_tables where owner like upper('&&SCHEMA_FILTER')) as table_cnt,
    (select count(*) from all_dependencies where owner like upper('&&SCHEMA_FILTER') and (referenced_owner is null or referenced_owner <> owner)) as cross_schema_out_cnt,
    (select count(*) from all_objects where owner like upper('&&SCHEMA_FILTER') and object_type in ('PACKAGE', 'PACKAGE BODY')) +
    (select count(*) from all_mviews where owner like upper('&&SCHEMA_FILTER')) +
    (select count(*) from all_db_links where owner like upper('&&SCHEMA_FILTER')) as hotspot_cnt,
    (select count(*) from all_tab_columns where owner like upper('&&SCHEMA_FILTER') and data_type in ('LONG', 'LONG RAW', 'BFILE', 'XMLTYPE', 'UROWID')) as legacy_col_cnt
  from dual
)
select '<tr><td>' ||
       case
         when owner_cnt = 0 or table_cnt = 0 then '<span class="fail">BLOCKED</span>'
         when legacy_col_cnt > 10 or cross_schema_out_cnt > 50 or hotspot_cnt > 20 then '<span class="warn">CONDITIONAL</span>'
         else '<span class="pass">READY_FOR_SCT_POC</span>'
       end ||
       '</td><td>' ||
       case
         when owner_cnt = 0 or table_cnt = 0 then 'Insufficient source visibility for a valid POC.'
         when legacy_col_cnt > 10 or cross_schema_out_cnt > 50 or hotspot_cnt > 20 then 'Proceed only with explicit remediation backlog and owner sign-off.'
         else 'Source has manageable risk for first SCT conversion cycle.'
       end ||
       '</td><td>' ||
       case
         when owner_cnt = 0 or table_cnt = 0 then 'Fix permissions/schema filter, rerun this report.'
         when legacy_col_cnt > 10 or cross_schema_out_cnt > 50 or hotspot_cnt > 20 then 'Run SCT in assessment mode first, then patch blockers.'
         else 'Install SCT and run schema conversion report for this POC schema.'
       end || '</td></tr>'
from m;
prompt </table>
prompt </div>

prompt </body>
prompt </html>

spool off


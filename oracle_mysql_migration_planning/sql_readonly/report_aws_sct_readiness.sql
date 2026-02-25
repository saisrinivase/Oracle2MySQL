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

spool "&&REPORT_DIR/aws_sct_readiness.html"

prompt <!DOCTYPE html>
prompt <html lang="en">
prompt <head>
prompt <meta charset="utf-8">
prompt <title>AWS SCT Readiness</title>
prompt <style>
prompt body { font-family: Arial, sans-serif; margin: 24px; background: #f7f9fc; color: #1f2937; }
prompt h1, h2 { margin: 0 0 12px 0; }
prompt .card { background: #ffffff; border: 1px solid #e5e7eb; border-radius: 10px; padding: 16px; margin-bottom: 16px; }
prompt table { border-collapse: collapse; width: 100%; }
prompt th, td { border: 1px solid #d1d5db; padding: 8px; text-align: left; vertical-align: top; }
prompt .nav { margin-bottom: 16px; }
prompt .ok { color: #166534; font-weight: 700; }
prompt .warn { color: #b45309; font-weight: 700; }
prompt .risk { color: #b91c1c; font-weight: 700; }
prompt a { color: #0f4c81; text-decoration: none; }
prompt a:hover { text-decoration: underline; }
prompt ul { margin-top: 8px; }
prompt </style>
prompt </head>
prompt <body>
prompt <h1>AWS SCT Readiness (Before Installation/Conversion)</h1>
prompt <div class="nav"><a href="source_intelligence.html">Source Intelligence</a> | <a href="schema_complexity.html">Schema Complexity</a></div>

prompt <div class="card">
prompt <h2>Source Baseline for Planning</h2>
prompt <table>
prompt <tr><th>Oracle Version</th><th>vCPUs</th><th>SGA (GB)</th><th>PGA Limit (GB)</th><th>Target</th></tr>
select '<tr><td>' ||
       replace(replace(replace(replace(replace('&&SOURCE_DB_VERSION', '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' || to_char(to_number('&&SOURCE_VCPUS')) ||
       '</td><td>' || to_char(to_number('&&SOURCE_SGA_GB')) ||
       '</td><td>' || to_char(to_number('&&SOURCE_PGA_LIMIT_GB')) ||
       '</td><td>Aurora MySQL RDS</td></tr>'
from dual;
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>Key SCT Compatibility Indicators</h2>
prompt <table>
prompt <tr><th>Indicator</th><th>Count</th><th>Readiness Signal</th></tr>
with metrics as (
  select
    (select count(*) from all_objects where owner like upper('&&SCHEMA_FILTER') and object_type in ('PACKAGE', 'PACKAGE BODY')) as package_cnt,
    (select count(*) from all_mviews where owner like upper('&&SCHEMA_FILTER')) as mview_cnt,
    (select count(*) from all_db_links where owner like upper('&&SCHEMA_FILTER')) as dblink_cnt,
    (select count(*) from all_ind_expressions where index_owner like upper('&&SCHEMA_FILTER')) as function_index_cnt,
    (select count(*) from all_tab_columns where owner like upper('&&SCHEMA_FILTER') and data_type in ('LONG', 'LONG RAW', 'BFILE', 'XMLTYPE', 'UROWID')) as legacy_col_cnt,
    (select count(*) from (
      select owner, object_name from all_objects where owner like upper('&&SCHEMA_FILTER') and length(object_name) > 64
      union all
      select owner, column_name from all_tab_columns where owner like upper('&&SCHEMA_FILTER') and length(column_name) > 64
    )) as overlength_name_cnt,
    (select count(*) from all_dependencies where owner like upper('&&SCHEMA_FILTER') and (referenced_owner is null or referenced_owner <> owner)) as cross_schema_out_cnt
  from dual
)
select '<tr><td>Packages/Package Bodies</td><td>' || to_char(package_cnt) || '</td><td>' ||
       case when package_cnt = 0 then '<span class="ok">LOW</span>' else '<span class="risk">REWRITE REQUIRED</span>' end || '</td></tr>'
from metrics
union all
select '<tr><td>Materialized Views</td><td>' || to_char(mview_cnt) || '</td><td>' ||
       case when mview_cnt = 0 then '<span class="ok">LOW</span>' else '<span class="warn">REDESIGN NEEDED</span>' end || '</td></tr>'
from metrics
union all
select '<tr><td>DB Links</td><td>' || to_char(dblink_cnt) || '</td><td>' ||
       case when dblink_cnt = 0 then '<span class="ok">LOW</span>' else '<span class="risk">INTEGRATION REWORK</span>' end || '</td></tr>'
from metrics
union all
select '<tr><td>Function-Based Index Expressions</td><td>' || to_char(function_index_cnt) || '</td><td>' ||
       case when function_index_cnt = 0 then '<span class="ok">LOW</span>' else '<span class="warn">VERIFY GENERATED COLUMNS</span>' end || '</td></tr>'
from metrics
union all
select '<tr><td>Legacy/Oracle-Specific Column Types</td><td>' || to_char(legacy_col_cnt) || '</td><td>' ||
       case when legacy_col_cnt = 0 then '<span class="ok">LOW</span>' else '<span class="risk">MAPPING HOTSPOT</span>' end || '</td></tr>'
from metrics
union all
select '<tr><td>Identifiers Over 64 Chars</td><td>' || to_char(overlength_name_cnt) || '</td><td>' ||
       case when overlength_name_cnt = 0 then '<span class="ok">LOW</span>' else '<span class="warn">RENAME REQUIRED</span>' end || '</td></tr>'
from metrics
union all
select '<tr><td>Cross-Schema Outbound Dependencies</td><td>' || to_char(cross_schema_out_cnt) || '</td><td>' ||
       case when cross_schema_out_cnt = 0 then '<span class="ok">LOW</span>' else '<span class="warn">COORDINATE OWNERS</span>' end || '</td></tr>'
from metrics;
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>Pre-SCT Checklist</h2>
prompt <ul>
prompt <li>Choose one low/medium complexity schema as the first POC slice.</li>
prompt <li>Confirm Oracle privileges for metadata extraction and (later) DMS CDC.</li>
prompt <li>Define Aurora target parameter baseline (charset/collation/timezone/sql_mode).</li>
prompt <li>Lock change windows so SCT analysis and validation do not collide with peak load.</li>
prompt <li>Document unsupported objects and expected manual remediation owners.</li>
prompt <li>Proceed to SCT install only after the above points are accepted.</li>
prompt </ul>
prompt </div>

prompt <div class="card">
prompt <h2>Execution Sequence</h2>
prompt <table>
prompt <tr><th>Step</th><th>Action</th></tr>
prompt <tr><td>1</td><td>Run source intelligence reports (this package).</td></tr>
prompt <tr><td>2</td><td>Pick POC schema and confirm dependency blast radius.</td></tr>
prompt <tr><td>3</td><td>Install AWS SCT and run conversion report for selected schema.</td></tr>
prompt <tr><td>4</td><td>Triage SCT findings and produce remediation list.</td></tr>
prompt <tr><td>5</td><td>Only then plan DMS full-load + CDC execution.</td></tr>
prompt </table>
prompt </div>

prompt </body>
prompt </html>

spool off


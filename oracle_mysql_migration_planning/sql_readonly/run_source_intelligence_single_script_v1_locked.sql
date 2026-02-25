-- LOCKED VERSION: v1.0.0 (do not edit; copy to create next version)
-- Baseline frozen for reproducible Oracle source discovery and assessment outputs.
-- Single-file Read-Only Source Intelligence Runner (SQL Developer / SQL*Plus)
--
-- Usage:
--   @run_source_intelligence_single_script_v1_locked.sql SCHEMA_FILTER REPORT_DIR SOURCE_DB_VERSION SOURCE_VCPUS SOURCE_SGA_GB SOURCE_PGA_LIMIT_GB
--
-- Example:
--   @run_source_intelligence_single_script_v1_locked.sql HR /tmp/oracle_source_intel 19c 8 350 40
--
-- Notes:
--   1) This script is read-only (no create/insert/update/delete/merge).
--   2) REPORT_DIR must already exist.

set define on
set verify off
set feedback on
set serveroutput on

define SCHEMA_FILTER='&1'
define REPORT_DIR='&2'
define SOURCE_DB_VERSION='&3'
define SOURCE_VCPUS='&4'
define SOURCE_SGA_GB='&5'
define SOURCE_PGA_LIMIT_GB='&6'

prompt
prompt === Oracle Source Intelligence (Read-Only, Single Script) ===
prompt SCHEMA_FILTER      = &&SCHEMA_FILTER
prompt REPORT_DIR         = &&REPORT_DIR
prompt SOURCE_DB_VERSION  = &&SOURCE_DB_VERSION
prompt SOURCE_VCPUS       = &&SOURCE_VCPUS
prompt SOURCE_SGA_GB      = &&SOURCE_SGA_GB
prompt SOURCE_PGA_LIMIT_GB= &&SOURCE_PGA_LIMIT_GB
prompt

set feedback off
set heading off
set pagesize 0
set linesize 32767
set trimspool on
set termout on

-- Report 1: source_intelligence.html
spool "&&REPORT_DIR/source_intelligence.html"

prompt <!DOCTYPE html>
prompt <html lang="en">
prompt <head>
prompt <meta charset="utf-8">
prompt <title>Oracle Source Intelligence</title>
prompt <style>
prompt body { font-family: Arial, sans-serif; margin: 24px; background: #f7f9fc; color: #1f2937; }
prompt h1, h2 { margin: 0 0 12px 0; }
prompt .muted { color: #6b7280; margin-bottom: 20px; }
prompt .card { background: #ffffff; border: 1px solid #e5e7eb; border-radius: 10px; padding: 16px; margin-bottom: 16px; }
prompt .grid { display: grid; grid-template-columns: repeat(auto-fit,minmax(220px,1fr)); gap: 12px; }
prompt .kpi { font-size: 28px; font-weight: 700; margin-top: 6px; }
prompt table { border-collapse: collapse; width: 100%; }
prompt th, td { border: 1px solid #d1d5db; padding: 8px; text-align: left; vertical-align: top; }
prompt a { color: #0f4c81; text-decoration: none; }
prompt a:hover { text-decoration: underline; }
prompt ul { margin-top: 8px; }
prompt </style>
prompt </head>
prompt <body>
prompt <h1>Oracle Source Intelligence (Read-Only)</h1>

select '<div class="muted">Database: <strong>' ||
       replace(replace(replace(replace(replace(nvl(sys_context('USERENV', 'DB_NAME'), '-'), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</strong> | Host: <strong>' ||
       replace(replace(replace(replace(replace(nvl(sys_context('USERENV', 'SERVER_HOST'), '-'), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</strong> | Schema Filter: <strong>' ||
       replace(replace(replace(replace(replace(upper('&&SCHEMA_FILTER'), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</strong></div>'
from dual;

prompt <div class="card">
prompt <h2>Provided Source Profile</h2>
prompt <table>
prompt <tr><th>Oracle Version</th><th>vCPUs</th><th>SGA (GB)</th><th>PGA Limit (GB)</th></tr>
select '<tr><td>' ||
       replace(replace(replace(replace(replace('&&SOURCE_DB_VERSION', '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' || to_char(to_number('&&SOURCE_VCPUS')) ||
       '</td><td>' || to_char(to_number('&&SOURCE_SGA_GB')) ||
       '</td><td>' || to_char(to_number('&&SOURCE_PGA_LIMIT_GB')) ||
       '</td></tr>'
from dual;
prompt </table>
prompt </div>

prompt <div class="grid">
prompt <div class="card"><div>Total Objects</div>
select '<div class="kpi">' || to_char(count(*)) || '</div>'
from all_objects
where owner like upper('&&SCHEMA_FILTER')
  and object_type in (
    'TABLE', 'VIEW', 'MATERIALIZED VIEW', 'INDEX', 'SEQUENCE', 'SYNONYM',
    'PROCEDURE', 'FUNCTION', 'PACKAGE', 'PACKAGE BODY', 'TRIGGER', 'TYPE', 'TYPE BODY'
  );
prompt </div>

prompt <div class="card"><div>Total Tables</div>
select '<div class="kpi">' || to_char(count(*)) || '</div>'
from all_tables
where owner like upper('&&SCHEMA_FILTER');
prompt </div>

prompt <div class="card"><div>PL/SQL Lines</div>
select '<div class="kpi">' || to_char(count(*)) || '</div>'
from all_source
where owner like upper('&&SCHEMA_FILTER')
  and type in ('PROCEDURE', 'FUNCTION', 'PACKAGE', 'PACKAGE BODY', 'TRIGGER', 'TYPE', 'TYPE BODY');
prompt </div>

prompt <div class="card"><div>Dependency Edges</div>
select '<div class="kpi">' || to_char(count(*)) || '</div>'
from (
  select 1
  from all_dependencies d
  where d.owner like upper('&&SCHEMA_FILTER')
  union all
  select 1
  from all_dependencies d
  where d.referenced_owner like upper('&&SCHEMA_FILTER')
);
prompt </div>

prompt <div class="card"><div>Cross-Schema Edges</div>
select '<div class="kpi">' || to_char(count(*)) || '</div>'
from (
  select 1
  from all_dependencies d
  where d.owner like upper('&&SCHEMA_FILTER')
    and (d.referenced_owner is null or d.referenced_owner <> d.owner)
  union all
  select 1
  from all_dependencies d
  where d.referenced_owner like upper('&&SCHEMA_FILTER')
    and d.owner <> d.referenced_owner
);
prompt </div>
prompt </div>

prompt <div class="card">
prompt <h2>Owners in Scope</h2>
prompt <table>
prompt <tr><th>Owner</th><th>Objects</th></tr>
select '<tr><td>' ||
       replace(replace(replace(replace(replace(owner, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' || to_char(cnt) || '</td></tr>'
from (
  select owner, count(*) as cnt
  from all_objects
  where owner like upper('&&SCHEMA_FILTER')
  group by owner
  order by cnt desc, owner
);
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>Reports</h2>
prompt <ul>
prompt <li><a href="discovery_summary.html">Discovery Summary</a></li>
prompt <li><a href="discovery_objects.html">Discovery Object Details</a></li>
prompt <li><a href="dependency_graph.html">Dependency Graph</a></li>
prompt <li><a href="schema_complexity.html">Schema Complexity</a></li>
prompt <li><a href="aws_sct_readiness.html">AWS SCT Readiness</a></li>
prompt </ul>
prompt </div>

prompt </body>
prompt </html>

spool off

-- Report 2: discovery_summary.html
spool "&&REPORT_DIR/discovery_summary.html"

prompt <!DOCTYPE html>
prompt <html lang="en">
prompt <head>
prompt <meta charset="utf-8">
prompt <title>Discovery Summary</title>
prompt <style>
prompt body { font-family: Arial, sans-serif; margin: 24px; background: #f7f9fc; color: #1f2937; }
prompt h1, h2 { margin: 0 0 12px 0; }
prompt .card { background: #ffffff; border: 1px solid #e5e7eb; border-radius: 10px; padding: 16px; margin-bottom: 16px; }
prompt table { border-collapse: collapse; width: 100%; }
prompt th, td { border: 1px solid #d1d5db; padding: 8px; text-align: left; }
prompt .nav { margin-bottom: 16px; }
prompt a { color: #0f4c81; text-decoration: none; }
prompt a:hover { text-decoration: underline; }
prompt </style>
prompt </head>
prompt <body>
prompt <h1>Discovery Summary</h1>
prompt <div class="nav"><a href="source_intelligence.html">Source Intelligence</a> | <a href="discovery_objects.html">Object Details</a></div>

prompt <div class="card">
prompt <h2>Object Counts by Type</h2>
prompt <table>
prompt <tr><th>Object Type</th><th>Count</th></tr>
select '<tr><td>' ||
       replace(replace(replace(replace(replace(object_type, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' || to_char(cnt) || '</td></tr>'
from (
  select object_type, count(*) as cnt
  from all_objects
  where owner like upper('&&SCHEMA_FILTER')
    and object_type in (
      'TABLE', 'VIEW', 'MATERIALIZED VIEW', 'INDEX', 'SEQUENCE', 'SYNONYM',
      'PROCEDURE', 'FUNCTION', 'PACKAGE', 'PACKAGE BODY', 'TRIGGER', 'TYPE', 'TYPE BODY'
    )
  group by object_type
  order by cnt desc, object_type
);
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>Top 25 Tables by Estimated MB</h2>
prompt <table>
prompt <tr><th>Owner</th><th>Table</th><th>Rows</th><th>Estimated MB</th><th>Partitioned</th><th>Last Analyzed</th></tr>
select '<tr><td>' ||
       replace(replace(replace(replace(replace(owner, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' ||
       replace(replace(replace(replace(replace(table_name, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' || to_char(nvl(num_rows, 0)) ||
       '</td><td>' || to_char(round((nvl(num_rows, 0) * nvl(avg_row_len, 0)) / 1024 / 1024, 2), 'FM9999999990D00') ||
       '</td><td>' || nvl(partitioned, '-') ||
       '</td><td>' || nvl(to_char(last_analyzed, 'YYYY-MM-DD HH24:MI:SS'), '-') ||
       '</td></tr>'
from (
  select owner, table_name, num_rows, avg_row_len, partitioned, last_analyzed
  from all_tables
  where owner like upper('&&SCHEMA_FILTER')
  order by (nvl(num_rows, 0) * nvl(avg_row_len, 0)) desc, owner, table_name
)
where rownum <= 25;
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>PL/SQL Footprint</h2>
prompt <table>
prompt <tr><th>Type</th><th>Object Count</th><th>Total Lines</th></tr>
select '<tr><td>' ||
       replace(replace(replace(replace(replace(type, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' || to_char(obj_cnt) ||
       '</td><td>' || to_char(line_cnt) || '</td></tr>'
from (
  select type, count(distinct owner || ':' || name || ':' || type) as obj_cnt, count(*) as line_cnt
  from all_source
  where owner like upper('&&SCHEMA_FILTER')
    and type in ('PROCEDURE', 'FUNCTION', 'PACKAGE', 'PACKAGE BODY', 'TRIGGER', 'TYPE', 'TYPE BODY')
  group by type
  order by obj_cnt desc, type
);
prompt </table>
prompt </div>

prompt </body>
prompt </html>

spool off


-- Report 3: discovery_objects.html
spool "&&REPORT_DIR/discovery_objects.html"

prompt <!DOCTYPE html>
prompt <html lang="en">
prompt <head>
prompt <meta charset="utf-8">
prompt <title>Discovery Object Details</title>
prompt <style>
prompt body { font-family: Arial, sans-serif; margin: 24px; background: #f7f9fc; color: #1f2937; }
prompt h1 { margin: 0 0 12px 0; }
prompt .nav { margin-bottom: 16px; }
prompt table { border-collapse: collapse; width: 100%; background: #ffffff; }
prompt th, td { border: 1px solid #d1d5db; padding: 8px; text-align: left; }
prompt a { color: #0f4c81; text-decoration: none; }
prompt a:hover { text-decoration: underline; }
prompt </style>
prompt </head>
prompt <body>
prompt <h1>Discovery Object Details (first 3000 rows)</h1>
prompt <div class="nav"><a href="source_intelligence.html">Source Intelligence</a> | <a href="discovery_summary.html">Discovery Summary</a></div>
prompt <table>
prompt <tr><th>Owner</th><th>Object</th><th>Type</th><th>Status</th><th>Created</th><th>Last DDL</th></tr>
select '<tr><td>' ||
       replace(replace(replace(replace(replace(owner, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' ||
       replace(replace(replace(replace(replace(object_name, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' ||
       replace(replace(replace(replace(replace(object_type, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' ||
       replace(replace(replace(replace(replace(status, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' || nvl(to_char(created, 'YYYY-MM-DD HH24:MI:SS'), '-') ||
       '</td><td>' || nvl(to_char(last_ddl_time, 'YYYY-MM-DD HH24:MI:SS'), '-') ||
       '</td></tr>'
from (
  select owner, object_name, object_type, status, created, last_ddl_time
  from all_objects
  where owner like upper('&&SCHEMA_FILTER')
    and object_type in (
      'TABLE', 'VIEW', 'MATERIALIZED VIEW', 'INDEX', 'SEQUENCE', 'SYNONYM',
      'PROCEDURE', 'FUNCTION', 'PACKAGE', 'PACKAGE BODY', 'TRIGGER', 'TYPE', 'TYPE BODY'
    )
  order by owner, object_type, object_name
)
where rownum <= 3000;
prompt </table>
prompt </body>
prompt </html>

spool off


-- Report 4: dependency_graph.html
spool "&&REPORT_DIR/dependency_graph.html"

prompt <!DOCTYPE html>
prompt <html lang="en">
prompt <head>
prompt <meta charset="utf-8">
prompt <title>Dependency Graph</title>
prompt <style>
prompt body { font-family: Arial, sans-serif; margin: 24px; background: #f7f9fc; color: #1f2937; }
prompt h1, h2 { margin: 0 0 12px 0; }
prompt .card { background: #ffffff; border: 1px solid #e5e7eb; border-radius: 10px; padding: 16px; margin-bottom: 16px; }
prompt table { border-collapse: collapse; width: 100%; }
prompt th, td { border: 1px solid #d1d5db; padding: 8px; text-align: left; vertical-align: top; }
prompt .nav { margin-bottom: 16px; }
prompt a { color: #0f4c81; text-decoration: none; }
prompt a:hover { text-decoration: underline; }
prompt </style>
prompt </head>
prompt <body>
prompt <h1>Dependency Graph</h1>
prompt <div class="nav"><a href="source_intelligence.html">Source Intelligence</a> | <a href="schema_complexity.html">Schema Complexity</a></div>

prompt <div class="card">
prompt <h2>Dependency Summary</h2>
prompt <table>
prompt <tr><th>Direction</th><th>Cross-Schema</th><th>Edges</th></tr>
with edges as (
  select d.owner as root_owner, d.name as root_name, d.type as root_type,
         'OUTBOUND' as direction, d.referenced_owner as related_owner,
         d.referenced_name as related_name, d.referenced_type as related_type,
         d.referenced_link_name as link_name,
         case when d.referenced_owner is null or d.referenced_owner <> d.owner then 'Y' else 'N' end as cross_schema
  from all_dependencies d
  where d.owner like upper('&&SCHEMA_FILTER')
  union all
  select d.referenced_owner as root_owner, d.referenced_name as root_name, d.referenced_type as root_type,
         'INBOUND' as direction, d.owner as related_owner, d.name as related_name, d.type as related_type,
         d.referenced_link_name as link_name,
         case when d.owner <> d.referenced_owner then 'Y' else 'N' end as cross_schema
  from all_dependencies d
  where d.referenced_owner like upper('&&SCHEMA_FILTER')
)
select '<tr><td>' || direction || '</td><td>' || cross_schema || '</td><td>' || to_char(cnt) || '</td></tr>'
from (
  select direction, cross_schema, count(*) as cnt
  from edges
  group by direction, cross_schema
  order by direction, cross_schema desc
);
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>Top Related Schemas</h2>
prompt <table>
prompt <tr><th>Related Owner</th><th>Edges</th></tr>
with edges as (
  select d.referenced_owner as related_owner
  from all_dependencies d
  where d.owner like upper('&&SCHEMA_FILTER')
  union all
  select d.owner as related_owner
  from all_dependencies d
  where d.referenced_owner like upper('&&SCHEMA_FILTER')
)
select '<tr><td>' ||
       replace(replace(replace(replace(replace(nvl(related_owner, '-'), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' || to_char(cnt) || '</td></tr>'
from (
  select related_owner, count(*) as cnt
  from edges
  group by related_owner
  order by cnt desc, related_owner
)
where rownum <= 25;
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>Dependency Edge Details (first 4000 rows)</h2>
prompt <table>
prompt <tr><th>Root Owner</th><th>Root Object</th><th>Type</th><th>Direction</th><th>Related Owner</th><th>Related Object</th><th>Related Type</th><th>DB Link</th><th>Cross-Schema</th></tr>
with edges as (
  select d.owner as root_owner, d.name as root_name, d.type as root_type,
         'OUTBOUND' as direction, d.referenced_owner as related_owner,
         d.referenced_name as related_name, d.referenced_type as related_type,
         d.referenced_link_name as link_name,
         case when d.referenced_owner is null or d.referenced_owner <> d.owner then 'Y' else 'N' end as cross_schema
  from all_dependencies d
  where d.owner like upper('&&SCHEMA_FILTER')
  union all
  select d.referenced_owner as root_owner, d.referenced_name as root_name, d.referenced_type as root_type,
         'INBOUND' as direction, d.owner as related_owner, d.name as related_name, d.type as related_type,
         d.referenced_link_name as link_name,
         case when d.owner <> d.referenced_owner then 'Y' else 'N' end as cross_schema
  from all_dependencies d
  where d.referenced_owner like upper('&&SCHEMA_FILTER')
)
select '<tr><td>' ||
       replace(replace(replace(replace(replace(nvl(root_owner, '-'), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' ||
       replace(replace(replace(replace(replace(nvl(root_name, '-'), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' ||
       replace(replace(replace(replace(replace(nvl(root_type, '-'), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' || direction || '</td><td>' ||
       replace(replace(replace(replace(replace(nvl(related_owner, '-'), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' ||
       replace(replace(replace(replace(replace(nvl(related_name, '-'), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' ||
       replace(replace(replace(replace(replace(nvl(related_type, '-'), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' ||
       replace(replace(replace(replace(replace(nvl(link_name, '-'), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' || cross_schema || '</td></tr>'
from (
  select root_owner, root_name, root_type, direction, related_owner, related_name, related_type, link_name, cross_schema
  from edges
  order by direction, root_owner, root_type, root_name
)
where rownum <= 4000;
prompt </table>
prompt </div>

prompt </body>
prompt </html>

spool off


-- Report 5: schema_complexity.html
spool "&&REPORT_DIR/schema_complexity.html"

prompt <!DOCTYPE html>
prompt <html lang="en">
prompt <head>
prompt <meta charset="utf-8">
prompt <title>Schema Complexity</title>
prompt <style>
prompt body { font-family: Arial, sans-serif; margin: 24px; background: #f7f9fc; color: #1f2937; }
prompt h1, h2 { margin: 0 0 12px 0; }
prompt .card { background: #ffffff; border: 1px solid #e5e7eb; border-radius: 10px; padding: 16px; margin-bottom: 16px; }
prompt table { border-collapse: collapse; width: 100%; }
prompt th, td { border: 1px solid #d1d5db; padding: 8px; text-align: left; vertical-align: top; }
prompt .nav { margin-bottom: 16px; }
prompt .low { color: #166534; font-weight: 700; }
prompt .medium { color: #b45309; font-weight: 700; }
prompt .high { color: #b91c1c; font-weight: 700; }
prompt .veryhigh { color: #7f1d1d; font-weight: 700; }
prompt a { color: #0f4c81; text-decoration: none; }
prompt a:hover { text-decoration: underline; }
prompt </style>
prompt </head>
prompt <body>
prompt <h1>Schema Complexity and POC Fit</h1>
prompt <div class="nav"><a href="source_intelligence.html">Source Intelligence</a> | <a href="dependency_graph.html">Dependency Graph</a></div>

prompt <div class="card">
prompt <h2>Complexity Summary</h2>
prompt <table>
prompt <tr><th>Owner</th><th>Score</th><th>Band</th><th>POC Recommendation</th></tr>
with owners as (
  select distinct owner
  from all_objects
  where owner like upper('&&SCHEMA_FILTER')
),
table_counts as (
  select owner, count(*) as table_count
  from all_tables
  where owner like upper('&&SCHEMA_FILTER')
  group by owner
),
view_counts as (
  select owner, count(*) as view_count
  from all_objects
  where owner like upper('&&SCHEMA_FILTER')
    and object_type = 'VIEW'
  group by owner
),
plsql_stats as (
  select owner,
         count(distinct owner || ':' || name || ':' || type) as plsql_obj_count,
         count(*) as plsql_line_count
  from all_source
  where owner like upper('&&SCHEMA_FILTER')
    and type in ('PROCEDURE', 'FUNCTION', 'PACKAGE', 'PACKAGE BODY', 'TRIGGER', 'TYPE', 'TYPE BODY')
  group by owner
),
trigger_counts as (
  select owner, count(*) as trigger_count
  from all_objects
  where owner like upper('&&SCHEMA_FILTER')
    and object_type = 'TRIGGER'
  group by owner
),
sequence_counts as (
  select owner, count(*) as sequence_count
  from all_objects
  where owner like upper('&&SCHEMA_FILTER')
    and object_type = 'SEQUENCE'
  group by owner
),
package_counts as (
  select owner, count(*) as package_count
  from all_objects
  where owner like upper('&&SCHEMA_FILTER')
    and object_type in ('PACKAGE', 'PACKAGE BODY')
  group by owner
),
mview_counts as (
  select owner, count(*) as mview_count
  from all_mviews
  where owner like upper('&&SCHEMA_FILTER')
  group by owner
),
dblink_counts as (
  select owner, count(*) as dblink_count
  from all_db_links
  where owner like upper('&&SCHEMA_FILTER')
  group by owner
),
legacy_col_counts as (
  select owner, count(*) as legacy_col_count
  from all_tab_columns
  where owner like upper('&&SCHEMA_FILTER')
    and data_type in ('LONG', 'LONG RAW', 'BFILE', 'XMLTYPE', 'UROWID')
  group by owner
),
function_index_counts as (
  select index_owner as owner, count(*) as function_index_count
  from all_ind_expressions
  where index_owner like upper('&&SCHEMA_FILTER')
  group by index_owner
),
overlength_names as (
  select owner, count(*) as overlength_count
  from (
    select owner from all_objects where owner like upper('&&SCHEMA_FILTER') and length(object_name) > 64
    union all
    select owner from all_tab_columns where owner like upper('&&SCHEMA_FILTER') and length(column_name) > 64
  )
  group by owner
),
dep_out_cross as (
  select owner, count(*) as out_cross_count
  from all_dependencies
  where owner like upper('&&SCHEMA_FILTER')
    and (referenced_owner is null or referenced_owner <> owner)
  group by owner
),
dep_inbound as (
  select referenced_owner as owner, count(*) as inbound_count
  from all_dependencies
  where referenced_owner like upper('&&SCHEMA_FILTER')
    and owner <> referenced_owner
  group by referenced_owner
),
scored as (
  select
    o.owner,
    nvl(t.table_count, 0) as table_count,
    nvl(v.view_count, 0) as view_count,
    nvl(p.plsql_obj_count, 0) as plsql_obj_count,
    nvl(p.plsql_line_count, 0) as plsql_line_count,
    nvl(tr.trigger_count, 0) as trigger_count,
    nvl(sq.sequence_count, 0) as sequence_count,
    nvl(pk.package_count, 0) as package_count,
    nvl(mv.mview_count, 0) as mview_count,
    nvl(dl.dblink_count, 0) as dblink_count,
    nvl(lg.legacy_col_count, 0) as legacy_col_count,
    nvl(fi.function_index_count, 0) as function_index_count,
    nvl(ol.overlength_count, 0) as overlength_count,
    nvl(do.out_cross_count, 0) as out_cross_count,
    nvl(di.inbound_count, 0) as inbound_count,
    (
      nvl(t.table_count, 0) * 1 +
      nvl(v.view_count, 0) * 1 +
      nvl(p.plsql_obj_count, 0) * 2 +
      nvl(tr.trigger_count, 0) * 3 +
      nvl(sq.sequence_count, 0) * 1 +
      ceil(nvl(p.plsql_line_count, 0) / 500) +
      nvl(do.out_cross_count, 0) * 3 +
      nvl(di.inbound_count, 0) * 4 +
      nvl(pk.package_count, 0) * 4 +
      nvl(mv.mview_count, 0) * 4 +
      nvl(dl.dblink_count, 0) * 5 +
      nvl(lg.legacy_col_count, 0) * 5 +
      nvl(fi.function_index_count, 0) * 2 +
      nvl(ol.overlength_count, 0) * 3
    ) as complexity_score
  from owners o
  left join table_counts t on t.owner = o.owner
  left join view_counts v on v.owner = o.owner
  left join plsql_stats p on p.owner = o.owner
  left join trigger_counts tr on tr.owner = o.owner
  left join sequence_counts sq on sq.owner = o.owner
  left join package_counts pk on pk.owner = o.owner
  left join mview_counts mv on mv.owner = o.owner
  left join dblink_counts dl on dl.owner = o.owner
  left join legacy_col_counts lg on lg.owner = o.owner
  left join function_index_counts fi on fi.owner = o.owner
  left join overlength_names ol on ol.owner = o.owner
  left join dep_out_cross do on do.owner = o.owner
  left join dep_inbound di on di.owner = o.owner
)
select '<tr><td>' ||
       replace(replace(replace(replace(replace(owner, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' || to_char(complexity_score) || '</td><td>' ||
       case
         when complexity_score <= 60 then '<span class="low">LOW</span>'
         when complexity_score <= 180 then '<span class="medium">MEDIUM</span>'
         when complexity_score <= 320 then '<span class="high">HIGH</span>'
         else '<span class="veryhigh">VERY_HIGH</span>'
       end ||
       '</td><td>' ||
       case
         when complexity_score <= 180 then 'Recommended for first POC wave.'
         when complexity_score <= 320 then 'Possible POC with scoped blast radius and remediation.'
         else 'Defer this schema; choose a smaller one for initial POC.'
       end || '</td></tr>'
from scored
order by complexity_score, owner;
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>Scoring Inputs by Owner</h2>
prompt <table>
prompt <tr><th>Owner</th><th>Tables</th><th>Views</th><th>PLSQL Objects</th><th>PLSQL Lines</th><th>Triggers</th><th>Packages</th><th>MViews</th><th>DB Links</th><th>Cross Out</th><th>Inbound</th><th>Legacy Cols</th></tr>
with owners as (
  select distinct owner
  from all_objects
  where owner like upper('&&SCHEMA_FILTER')
),
table_counts as (
  select owner, count(*) as table_count from all_tables where owner like upper('&&SCHEMA_FILTER') group by owner
),
view_counts as (
  select owner, count(*) as view_count from all_objects where owner like upper('&&SCHEMA_FILTER') and object_type = 'VIEW' group by owner
),
plsql_stats as (
  select owner, count(distinct owner || ':' || name || ':' || type) as plsql_obj_count, count(*) as plsql_line_count
  from all_source
  where owner like upper('&&SCHEMA_FILTER')
    and type in ('PROCEDURE', 'FUNCTION', 'PACKAGE', 'PACKAGE BODY', 'TRIGGER', 'TYPE', 'TYPE BODY')
  group by owner
),
trigger_counts as (
  select owner, count(*) as trigger_count from all_objects where owner like upper('&&SCHEMA_FILTER') and object_type = 'TRIGGER' group by owner
),
package_counts as (
  select owner, count(*) as package_count from all_objects where owner like upper('&&SCHEMA_FILTER') and object_type in ('PACKAGE', 'PACKAGE BODY') group by owner
),
mview_counts as (
  select owner, count(*) as mview_count from all_mviews where owner like upper('&&SCHEMA_FILTER') group by owner
),
dblink_counts as (
  select owner, count(*) as dblink_count from all_db_links where owner like upper('&&SCHEMA_FILTER') group by owner
),
dep_out_cross as (
  select owner, count(*) as out_cross_count
  from all_dependencies
  where owner like upper('&&SCHEMA_FILTER')
    and (referenced_owner is null or referenced_owner <> owner)
  group by owner
),
dep_inbound as (
  select referenced_owner as owner, count(*) as inbound_count
  from all_dependencies
  where referenced_owner like upper('&&SCHEMA_FILTER')
    and owner <> referenced_owner
  group by referenced_owner
),
legacy_col_counts as (
  select owner, count(*) as legacy_col_count
  from all_tab_columns
  where owner like upper('&&SCHEMA_FILTER')
    and data_type in ('LONG', 'LONG RAW', 'BFILE', 'XMLTYPE', 'UROWID')
  group by owner
)
select '<tr><td>' ||
       replace(replace(replace(replace(replace(o.owner, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' || to_char(nvl(t.table_count, 0)) ||
       '</td><td>' || to_char(nvl(v.view_count, 0)) ||
       '</td><td>' || to_char(nvl(p.plsql_obj_count, 0)) ||
       '</td><td>' || to_char(nvl(p.plsql_line_count, 0)) ||
       '</td><td>' || to_char(nvl(tr.trigger_count, 0)) ||
       '</td><td>' || to_char(nvl(pk.package_count, 0)) ||
       '</td><td>' || to_char(nvl(mv.mview_count, 0)) ||
       '</td><td>' || to_char(nvl(dl.dblink_count, 0)) ||
       '</td><td>' || to_char(nvl(do.out_cross_count, 0)) ||
       '</td><td>' || to_char(nvl(di.inbound_count, 0)) ||
       '</td><td>' || to_char(nvl(lg.legacy_col_count, 0)) ||
       '</td></tr>'
from owners o
left join table_counts t on t.owner = o.owner
left join view_counts v on v.owner = o.owner
left join plsql_stats p on p.owner = o.owner
left join trigger_counts tr on tr.owner = o.owner
left join package_counts pk on pk.owner = o.owner
left join mview_counts mv on mv.owner = o.owner
left join dblink_counts dl on dl.owner = o.owner
left join dep_out_cross do on do.owner = o.owner
left join dep_inbound di on di.owner = o.owner
left join legacy_col_counts lg on lg.owner = o.owner
order by o.owner;
prompt </table>
prompt </div>

prompt </body>
prompt </html>

spool off


-- Report 6: aws_sct_readiness.html
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


set feedback on
prompt
prompt Reports generated:
prompt &&REPORT_DIR/source_intelligence.html
prompt &&REPORT_DIR/discovery_summary.html
prompt &&REPORT_DIR/discovery_objects.html
prompt &&REPORT_DIR/dependency_graph.html
prompt &&REPORT_DIR/schema_complexity.html
prompt &&REPORT_DIR/aws_sct_readiness.html
prompt

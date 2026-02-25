-- Version: v2.0.0-enterprise
-- Single-file Read-Only Source Intelligence Runner (SQL Developer / SQL*Plus)
--
-- Usage:
--   @oracle2mysql_assement.sql SCHEMA_FILTER REPORT_DIR SOURCE_DB_VERSION SOURCE_VCPUS SOURCE_SGA_GB SOURCE_PGA_LIMIT_GB
--
-- Example:
--   @oracle2mysql_assement.sql HR /tmp/oracle_source_intel 19c 8 350 40
--
-- Notes:
--   1) This script is read-only (no create/insert/update/delete/merge).
--   2) REPORT_DIR must already exist.
--   3) REPORT_DIR is restricted to ALLOWED_REPORT_BASE (default /tmp/oracle_source_intel).

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
define ALLOWED_REPORT_BASE='/tmp/oracle_source_intel'

column _allowed_base_can new_value ALLOWED_REPORT_BASE noprint
column _report_dir_can new_value REPORT_DIR noprint
select regexp_replace(replace('&&ALLOWED_REPORT_BASE','\','/'), '/+$', '') as _allowed_base_can from dual;
select regexp_replace(replace('&&REPORT_DIR','\','/'), '/+$', '') as _report_dir_can from dual;

whenever sqlerror exit failure
declare
  v_allowed_base varchar2(4000) := '&&ALLOWED_REPORT_BASE';
  v_report_dir   varchar2(4000) := '&&REPORT_DIR';
begin
  if v_allowed_base is null or v_report_dir is null then
    raise_application_error(-20011, 'ALLOWED_REPORT_BASE and REPORT_DIR cannot be null.');
  end if;

  if v_report_dir <> v_allowed_base and instr(v_report_dir, v_allowed_base || '/') <> 1 then
    raise_application_error(
      -20012,
      'REPORT_DIR not allowed. Use ' || v_allowed_base || ' or a child directory under it. Given=' || v_report_dir
    );
  end if;
end;
/
whenever sqlerror continue

prompt
prompt === Oracle Source Intelligence (Read-Only, Single Script, v2 Final) ===
prompt SCHEMA_FILTER      = &&SCHEMA_FILTER
prompt REPORT_DIR         = &&REPORT_DIR
prompt ALLOWED_REPORT_BASE= &&ALLOWED_REPORT_BASE
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
prompt <li><a href="pre_migration_readiness.html">Pre-Migration Readiness</a></li>
prompt <li><a href="sct_conversion_guide.html">SCT Conversion Guide</a></li>
prompt <li><a href="datatype_mapping_backlog.html">Data Type Mapping Backlog</a></li>
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
prompt <div class="nav"><a href="source_intelligence.html">Source Intelligence</a> | <a href="schema_complexity.html">Schema Complexity</a> | <a href="pre_migration_readiness.html">Pre-Migration Readiness</a> | <a href="sct_conversion_guide.html">SCT Conversion Guide</a></div>

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


-- Report 7: pre_migration_readiness.html
spool "&&REPORT_DIR/pre_migration_readiness.html"

prompt <!DOCTYPE html>
prompt <html lang="en">
prompt <head>
prompt <meta charset="utf-8">
prompt <title>Pre-Migration Readiness</title>
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
prompt <h1>Pre-Migration Readiness</h1>
prompt <div class="nav"><a href="source_intelligence.html">Source Intelligence</a> | <a href="sct_conversion_guide.html">SCT Conversion Guide</a> | <a href="datatype_mapping_backlog.html">Data Type Mapping Backlog</a></div>

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
    (select count(*) from all_objects where owner like upper('&&SCHEMA_FILTER') and status <> 'VALID') as invalid_obj_cnt,
    (select count(*) from (
       select distinct owner || ':' || name || ':' || type as key_col
       from all_source
       where owner like upper('&&SCHEMA_FILTER')
         and upper(text) like '%EXECUTE IMMEDIATE%'
     )) as dynamic_sql_obj_cnt,
    (select count(*) from all_tab_columns where owner like upper('&&SCHEMA_FILTER') and data_type in ('LONG', 'LONG RAW', 'BFILE', 'XMLTYPE', 'UROWID', 'ROWID')) as legacy_col_cnt,
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
       '</td><td>Coordinate owners and define blast-radius controls.</td></tr>'
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
select '<tr><td>Dynamic SQL usage</td><td>' || to_char(dynamic_sql_obj_cnt) || ' object(s)</td><td>' ||
       case
         when dynamic_sql_obj_cnt = 0 then '<span class="pass">PASS</span>'
         when dynamic_sql_obj_cnt <= 15 then '<span class="warn">WARN</span>'
         else '<span class="fail">FAIL</span>'
       end ||
       '</td><td>Review for non-deterministic SQL and syntax conversion risk.</td></tr>'
from m
union all
select '<tr><td>Invalid objects</td><td>' || to_char(invalid_obj_cnt) || '</td><td>' ||
       case
         when invalid_obj_cnt = 0 then '<span class="pass">PASS</span>'
         when invalid_obj_cnt <= 20 then '<span class="warn">WARN</span>'
         else '<span class="fail">FAIL</span>'
       end ||
       '</td><td>Compile/fix invalid objects before SCT conversion output review.</td></tr>'
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
    (select count(*) from all_tab_columns where owner like upper('&&SCHEMA_FILTER') and data_type in ('LONG', 'LONG RAW', 'BFILE', 'XMLTYPE', 'UROWID', 'ROWID')) as legacy_col_cnt,
    (select count(*) from all_objects where owner like upper('&&SCHEMA_FILTER') and status <> 'VALID') as invalid_obj_cnt
  from dual
)
select '<tr><td>' ||
       case
         when owner_cnt = 0 or table_cnt = 0 then '<span class="fail">BLOCKED</span>'
         when legacy_col_cnt > 10 or cross_schema_out_cnt > 50 or hotspot_cnt > 20 or invalid_obj_cnt > 20 then '<span class="warn">CONDITIONAL</span>'
         else '<span class="pass">READY_FOR_SCT_POC</span>'
       end ||
       '</td><td>' ||
       case
         when owner_cnt = 0 or table_cnt = 0 then 'Insufficient source visibility for a valid POC.'
         when legacy_col_cnt > 10 or cross_schema_out_cnt > 50 or hotspot_cnt > 20 or invalid_obj_cnt > 20 then 'Proceed only with explicit remediation backlog and owner sign-off.'
         else 'Source has manageable risk for first SCT conversion cycle.'
       end ||
       '</td><td>' ||
       case
         when owner_cnt = 0 or table_cnt = 0 then 'Fix permissions/schema filter, rerun this report.'
         when legacy_col_cnt > 10 or cross_schema_out_cnt > 50 or hotspot_cnt > 20 or invalid_obj_cnt > 20 then 'Run SCT in assessment mode first, then patch blockers.'
         else 'Install SCT and run schema conversion report for this POC schema.'
       end || '</td></tr>'
from m;
prompt </table>
prompt </div>

prompt </body>
prompt </html>

spool off


-- Report 8: sct_conversion_guide.html
spool "&&REPORT_DIR/sct_conversion_guide.html"

prompt <!DOCTYPE html>
prompt <html lang="en">
prompt <head>
prompt <meta charset="utf-8">
prompt <title>SCT Conversion Guide</title>
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
prompt <h1>SCT Conversion Guide</h1>
prompt <div class="nav"><a href="source_intelligence.html">Source Intelligence</a> | <a href="pre_migration_readiness.html">Pre-Migration Readiness</a> | <a href="datatype_mapping_backlog.html">Data Type Mapping Backlog</a></div>

prompt <div class="card">
prompt <h2>Weighted Conversion Risk</h2>
prompt <table>
prompt <tr><th>Indicator</th><th>Count</th><th>Weight</th><th>Weighted Score</th><th>Signal</th><th>Suggested Action</th></tr>
with m as (
  select
    (select count(distinct owner) from all_objects where owner like upper('&&SCHEMA_FILTER')) as owner_cnt,
    (select count(*) from all_tables where owner like upper('&&SCHEMA_FILTER')) as table_cnt,
    (select count(*) from all_objects where owner like upper('&&SCHEMA_FILTER') and object_type in ('PACKAGE', 'PACKAGE BODY')) as package_cnt,
    (select count(*) from all_mviews where owner like upper('&&SCHEMA_FILTER')) as mview_cnt,
    (select count(*) from all_db_links where owner like upper('&&SCHEMA_FILTER')) as dblink_cnt,
    (select count(*) from all_ind_expressions where index_owner like upper('&&SCHEMA_FILTER')) as function_index_cnt,
    (select count(*) from all_tab_columns where owner like upper('&&SCHEMA_FILTER') and data_type in ('LONG', 'LONG RAW', 'BFILE', 'XMLTYPE', 'UROWID', 'ROWID')) as legacy_col_cnt,
    (select count(*) from (
      select owner, object_name from all_objects where owner like upper('&&SCHEMA_FILTER') and length(object_name) > 64
      union all
      select owner, column_name from all_tab_columns where owner like upper('&&SCHEMA_FILTER') and length(column_name) > 64
    )) as overlength_name_cnt,
    (select count(*) from all_dependencies where owner like upper('&&SCHEMA_FILTER') and (referenced_owner is null or referenced_owner <> owner)) as cross_schema_out_cnt,
    (select count(*) from all_objects where owner like upper('&&SCHEMA_FILTER') and status <> 'VALID') as invalid_obj_cnt,
    (select count(*) from all_objects where owner like upper('&&SCHEMA_FILTER') and object_type = 'TRIGGER') as trigger_cnt,
    (select count(*) from (
       select distinct owner || ':' || name || ':' || type as key_col
       from all_source
       where owner like upper('&&SCHEMA_FILTER')
         and upper(text) like '%EXECUTE IMMEDIATE%'
     )) as dynamic_sql_obj_cnt
  from dual
)
select '<tr><td>Packages / Package Bodies</td><td>' || to_char(package_cnt) || '</td><td>6</td><td>' || to_char(package_cnt * 6) || '</td><td>' ||
       case when package_cnt = 0 then '<span class="pass">LOW</span>' else '<span class="warn">MEDIUM</span>' end ||
       '</td><td>Plan package-to-procedure/function rewrite set.</td></tr>'
from m
union all
select '<tr><td>Materialized Views</td><td>' || to_char(mview_cnt) || '</td><td>6</td><td>' || to_char(mview_cnt * 6) || '</td><td>' ||
       case when mview_cnt = 0 then '<span class="pass">LOW</span>' else '<span class="warn">MEDIUM</span>' end ||
       '</td><td>Replace with scheduled table refresh/view strategy.</td></tr>'
from m
union all
select '<tr><td>DB Links</td><td>' || to_char(dblink_cnt) || '</td><td>8</td><td>' || to_char(dblink_cnt * 8) || '</td><td>' ||
       case when dblink_cnt = 0 then '<span class="pass">LOW</span>' else '<span class="fail">HIGH</span>' end ||
       '</td><td>Design external integration replacement before cutover.</td></tr>'
from m
union all
select '<tr><td>Legacy Datatype Columns</td><td>' || to_char(legacy_col_cnt) || '</td><td>8</td><td>' || to_char(legacy_col_cnt * 8) || '</td><td>' ||
       case when legacy_col_cnt = 0 then '<span class="pass">LOW</span>' else '<span class="fail">HIGH</span>' end ||
       '</td><td>Patch datatype mapping backlog before DDL freeze.</td></tr>'
from m
union all
select '<tr><td>Cross-Schema Outbound Dependencies</td><td>' || to_char(cross_schema_out_cnt) || '</td><td>3</td><td>' || to_char(cross_schema_out_cnt * 3) || '</td><td>' ||
       case
         when cross_schema_out_cnt = 0 then '<span class="pass">LOW</span>'
         when cross_schema_out_cnt <= 50 then '<span class="warn">MEDIUM</span>'
         else '<span class="fail">HIGH</span>'
       end ||
       '</td><td>Align data owners and dependency de-coupling plan.</td></tr>'
from m
union all
select '<tr><td>Function-Based Indexes</td><td>' || to_char(function_index_cnt) || '</td><td>3</td><td>' || to_char(function_index_cnt * 3) || '</td><td>' ||
       case when function_index_cnt = 0 then '<span class="pass">LOW</span>' else '<span class="warn">MEDIUM</span>' end ||
       '</td><td>Validate generated-column/index equivalence.</td></tr>'
from m
union all
select '<tr><td>Identifiers Over 64 Characters</td><td>' || to_char(overlength_name_cnt) || '</td><td>2</td><td>' || to_char(overlength_name_cnt * 2) || '</td><td>' ||
       case when overlength_name_cnt = 0 then '<span class="pass">LOW</span>' else '<span class="warn">MEDIUM</span>' end ||
       '</td><td>Rename objects/columns pre-conversion.</td></tr>'
from m
union all
select '<tr><td>Invalid Objects</td><td>' || to_char(invalid_obj_cnt) || '</td><td>2</td><td>' || to_char(invalid_obj_cnt * 2) || '</td><td>' ||
       case when invalid_obj_cnt = 0 then '<span class="pass">LOW</span>' else '<span class="warn">MEDIUM</span>' end ||
       '</td><td>Compile and fix before trusting SCT output.</td></tr>'
from m
union all
select '<tr><td>Triggers</td><td>' || to_char(trigger_cnt) || '</td><td>2</td><td>' || to_char(trigger_cnt * 2) || '</td><td>' ||
       case when trigger_cnt = 0 then '<span class="pass">LOW</span>' else '<span class="warn">MEDIUM</span>' end ||
       '</td><td>Review before/after semantics and side effects.</td></tr>'
from m
union all
select '<tr><td>Dynamic SQL Objects</td><td>' || to_char(dynamic_sql_obj_cnt) || '</td><td>4</td><td>' || to_char(dynamic_sql_obj_cnt * 4) || '</td><td>' ||
       case
         when dynamic_sql_obj_cnt = 0 then '<span class="pass">LOW</span>'
         when dynamic_sql_obj_cnt <= 15 then '<span class="warn">MEDIUM</span>'
         else '<span class="fail">HIGH</span>'
       end ||
       '</td><td>Perform manual SQL dialect review and rewrite.</td></tr>'
from m;
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>SCT Path Recommendation</h2>
prompt <table>
prompt <tr><th>Total Weighted Score</th><th>Decision</th><th>Interpretation</th><th>Immediate Next Step</th></tr>
with m as (
  select
    (select count(distinct owner) from all_objects where owner like upper('&&SCHEMA_FILTER')) as owner_cnt,
    (select count(*) from all_tables where owner like upper('&&SCHEMA_FILTER')) as table_cnt,
    (select count(*) from all_objects where owner like upper('&&SCHEMA_FILTER') and object_type in ('PACKAGE', 'PACKAGE BODY')) as package_cnt,
    (select count(*) from all_mviews where owner like upper('&&SCHEMA_FILTER')) as mview_cnt,
    (select count(*) from all_db_links where owner like upper('&&SCHEMA_FILTER')) as dblink_cnt,
    (select count(*) from all_ind_expressions where index_owner like upper('&&SCHEMA_FILTER')) as function_index_cnt,
    (select count(*) from all_tab_columns where owner like upper('&&SCHEMA_FILTER') and data_type in ('LONG', 'LONG RAW', 'BFILE', 'XMLTYPE', 'UROWID', 'ROWID')) as legacy_col_cnt,
    (select count(*) from (
      select owner, object_name from all_objects where owner like upper('&&SCHEMA_FILTER') and length(object_name) > 64
      union all
      select owner, column_name from all_tab_columns where owner like upper('&&SCHEMA_FILTER') and length(column_name) > 64
    )) as overlength_name_cnt,
    (select count(*) from all_dependencies where owner like upper('&&SCHEMA_FILTER') and (referenced_owner is null or referenced_owner <> owner)) as cross_schema_out_cnt,
    (select count(*) from all_objects where owner like upper('&&SCHEMA_FILTER') and status <> 'VALID') as invalid_obj_cnt,
    (select count(*) from all_objects where owner like upper('&&SCHEMA_FILTER') and object_type = 'TRIGGER') as trigger_cnt,
    (select count(*) from (
       select distinct owner || ':' || name || ':' || type as key_col
       from all_source
       where owner like upper('&&SCHEMA_FILTER')
         and upper(text) like '%EXECUTE IMMEDIATE%'
     )) as dynamic_sql_obj_cnt
  from dual
),
score as (
  select
    owner_cnt,
    table_cnt,
    package_cnt,
    mview_cnt,
    dblink_cnt,
    function_index_cnt,
    legacy_col_cnt,
    overlength_name_cnt,
    cross_schema_out_cnt,
    invalid_obj_cnt,
    trigger_cnt,
    dynamic_sql_obj_cnt,
    (
      package_cnt * 6 +
      mview_cnt * 6 +
      dblink_cnt * 8 +
      function_index_cnt * 3 +
      legacy_col_cnt * 8 +
      overlength_name_cnt * 2 +
      cross_schema_out_cnt * 3 +
      invalid_obj_cnt * 2 +
      trigger_cnt * 2 +
      dynamic_sql_obj_cnt * 4
    ) as total_weighted_score
  from m
)
select '<tr><td>' || to_char(total_weighted_score) || '</td><td>' ||
       case
         when owner_cnt = 0 or table_cnt = 0 then '<span class="fail">BLOCKED</span>'
         when total_weighted_score <= 120 and legacy_col_cnt <= 5 and dblink_cnt = 0 then '<span class="pass">PROCEED_WITH_SCT_CONVERSION_POC</span>'
         when total_weighted_score <= 260 then '<span class="warn">SCT_ASSESSMENT_FIRST</span>'
         else '<span class="fail">REFACTOR_BEFORE_SCT_CONVERSION</span>'
       end ||
       '</td><td>' ||
       case
         when owner_cnt = 0 or table_cnt = 0 then 'Source slice not visible or empty.'
         when total_weighted_score <= 120 and legacy_col_cnt <= 5 and dblink_cnt = 0 then 'Suitable for first SCT conversion + code review cycle.'
         when total_weighted_score <= 260 then 'Run SCT assessment report and patch high-impact blockers first.'
         else 'Risk is high; refactor schema before conversion attempts.'
       end ||
       '</td><td>' ||
       case
         when owner_cnt = 0 or table_cnt = 0 then 'Fix privileges/schema filter and rerun.'
         when total_weighted_score <= 120 and legacy_col_cnt <= 5 and dblink_cnt = 0 then 'Install SCT, run conversion, and baseline generated DDL quality.'
         when total_weighted_score <= 260 then 'Focus on datatype, DB link, package, and dynamic SQL remediation backlog.'
         else 'Split schema scope or remediate architecture hotspots before SCT conversion.'
       end || '</td></tr>'
from score;
prompt </table>
prompt </div>

prompt </body>
prompt </html>

spool off


-- Report 9: datatype_mapping_backlog.html
spool "&&REPORT_DIR/datatype_mapping_backlog.html"

prompt <!DOCTYPE html>
prompt <html lang="en">
prompt <head>
prompt <meta charset="utf-8">
prompt <title>Data Type Mapping Backlog</title>
prompt <style>
prompt body { font-family: Arial, sans-serif; margin: 24px; background: #f7f9fc; color: #1f2937; }
prompt h1, h2 { margin: 0 0 12px 0; }
prompt .card { background: #ffffff; border: 1px solid #e5e7eb; border-radius: 10px; padding: 16px; margin-bottom: 16px; }
prompt table { border-collapse: collapse; width: 100%; }
prompt th, td { border: 1px solid #d1d5db; padding: 8px; text-align: left; vertical-align: top; }
prompt .blocker { color: #b91c1c; font-weight: 700; }
prompt .high { color: #c2410c; font-weight: 700; }
prompt .medium { color: #b45309; font-weight: 700; }
prompt .low { color: #166534; font-weight: 700; }
prompt .nav { margin-bottom: 16px; }
prompt a { color: #0f4c81; text-decoration: none; }
prompt a:hover { text-decoration: underline; }
prompt </style>
prompt </head>
prompt <body>
prompt <h1>Oracle to Aurora MySQL Data Type Mapping Backlog</h1>
prompt <div class="nav"><a href="source_intelligence.html">Source Intelligence</a> | <a href="sct_conversion_guide.html">SCT Conversion Guide</a></div>

prompt <div class="card">
prompt <h2>Backlog Summary by Risk</h2>
prompt <table>
prompt <tr><th>Risk Band</th><th>Column Count</th></tr>
with cols as (
  select owner, table_name, column_name, data_type, data_length, data_precision, data_scale, char_length
  from all_tab_columns
  where owner like upper('&&SCHEMA_FILTER')
),
mapped as (
  select
    owner,
    table_name,
    column_name,
    data_type,
    data_length,
    data_precision,
    data_scale,
    char_length,
    case
      when data_type in ('LONG', 'LONG RAW', 'BFILE', 'XMLTYPE', 'UROWID', 'ROWID')
        or data_type like 'TIMESTAMP%WITH TIME ZONE%'
        or data_type like 'TIMESTAMP%WITH LOCAL TIME ZONE%'
        or data_type like 'INTERVAL YEAR%'
        or data_type like 'INTERVAL DAY%'
        then 'BLOCKER'
      when data_type in ('CLOB', 'NCLOB', 'BLOB')
        then 'HIGH'
      when data_type = 'NUMBER' and (data_precision is null or nvl(data_scale, 0) < 0)
        then 'MEDIUM'
      when data_type in ('DATE', 'RAW', 'FLOAT', 'BINARY_FLOAT', 'BINARY_DOUBLE')
        then 'MEDIUM'
      else 'LOW'
    end as risk_band
  from cols
)
select '<tr><td>' ||
       case risk_band
         when 'BLOCKER' then '<span class="blocker">BLOCKER</span>'
         when 'HIGH' then '<span class="high">HIGH</span>'
         when 'MEDIUM' then '<span class="medium">MEDIUM</span>'
         else '<span class="low">LOW</span>'
       end ||
       '</td><td>' || to_char(cnt) || '</td></tr>'
from (
  select risk_band, count(*) as cnt
  from mapped
  group by risk_band
  order by decode(risk_band, 'BLOCKER', 1, 'HIGH', 2, 'MEDIUM', 3, 'LOW', 4, 5)
);
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>Top Datatypes Requiring Mapping</h2>
prompt <table>
prompt <tr><th>Oracle Datatype</th><th>Columns</th><th>Suggested Aurora MySQL Target</th></tr>
with type_counts as (
  select
    data_type,
    count(*) as cnt,
    case
      when data_type = 'NUMBER' then 'INT/BIGINT/DECIMAL (based on precision/scale)'
      when data_type = 'DATE' then 'DATETIME(6)'
      when data_type like 'TIMESTAMP%WITH TIME ZONE%' or data_type like 'TIMESTAMP%WITH LOCAL TIME ZONE%' then 'DATETIME(6) + timezone column or VARCHAR(40)'
      when data_type like 'TIMESTAMP%' then 'DATETIME(6)'
      when data_type in ('VARCHAR2', 'NVARCHAR2') then 'VARCHAR(n)'
      when data_type in ('CHAR', 'NCHAR') then 'CHAR(n)'
      when data_type in ('CLOB', 'NCLOB') then 'LONGTEXT'
      when data_type = 'BLOB' then 'LONGBLOB'
      when data_type = 'RAW' then 'VARBINARY(n)'
      when data_type = 'LONG RAW' then 'LONGBLOB'
      when data_type = 'LONG' then 'LONGTEXT'
      when data_type = 'XMLTYPE' then 'LONGTEXT or JSON (after validation)'
      when data_type = 'BFILE' then 'External object store reference + metadata table'
      when data_type in ('FLOAT', 'BINARY_FLOAT', 'BINARY_DOUBLE') then 'DOUBLE'
      when data_type like 'INTERVAL YEAR%' or data_type like 'INTERVAL DAY%' then 'VARCHAR(50) or normalized numeric model'
      else 'Manual review'
    end as target_hint
  from all_tab_columns
  where owner like upper('&&SCHEMA_FILTER')
  group by
    data_type,
    case
      when data_type = 'NUMBER' then 'INT/BIGINT/DECIMAL (based on precision/scale)'
      when data_type = 'DATE' then 'DATETIME(6)'
      when data_type like 'TIMESTAMP%WITH TIME ZONE%' or data_type like 'TIMESTAMP%WITH LOCAL TIME ZONE%' then 'DATETIME(6) + timezone column or VARCHAR(40)'
      when data_type like 'TIMESTAMP%' then 'DATETIME(6)'
      when data_type in ('VARCHAR2', 'NVARCHAR2') then 'VARCHAR(n)'
      when data_type in ('CHAR', 'NCHAR') then 'CHAR(n)'
      when data_type in ('CLOB', 'NCLOB') then 'LONGTEXT'
      when data_type = 'BLOB' then 'LONGBLOB'
      when data_type = 'RAW' then 'VARBINARY(n)'
      when data_type = 'LONG RAW' then 'LONGBLOB'
      when data_type = 'LONG' then 'LONGTEXT'
      when data_type = 'XMLTYPE' then 'LONGTEXT or JSON (after validation)'
      when data_type = 'BFILE' then 'External object store reference + metadata table'
      when data_type in ('FLOAT', 'BINARY_FLOAT', 'BINARY_DOUBLE') then 'DOUBLE'
      when data_type like 'INTERVAL YEAR%' or data_type like 'INTERVAL DAY%' then 'VARCHAR(50) or normalized numeric model'
      else 'Manual review'
    end
)
select '<tr><td>' ||
       replace(replace(replace(replace(replace(data_type, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' || to_char(cnt) || '</td><td>' ||
       replace(replace(replace(replace(replace(target_hint, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td></tr>'
from (
  select data_type, cnt, target_hint
  from type_counts
  order by cnt desc, data_type
)
where rownum <= 30;
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>Detailed Refactor Backlog (non-LOW risk, first 5000 rows)</h2>
prompt <table>
prompt <tr><th>Owner</th><th>Table</th><th>Column</th><th>Oracle Type</th><th>Length</th><th>Precision</th><th>Scale</th><th>Risk</th><th>Suggested Target Type</th><th>Refactor Guidance</th><th>SCT Rule Override</th></tr>
with cols as (
  select
    owner,
    table_name,
    column_name,
    data_type,
    data_length,
    data_precision,
    data_scale,
    char_length
  from all_tab_columns
  where owner like upper('&&SCHEMA_FILTER')
),
mapped as (
  select
    owner,
    table_name,
    column_name,
    data_type,
    data_length,
    data_precision,
    data_scale,
    char_length,
    case
      when data_type = 'NUMBER' then
        case
          when data_precision is null then 'DECIMAL(38,10)'
          when nvl(data_scale, 0) < 0 then 'DECIMAL(' || to_char(least(data_precision + abs(data_scale), 65)) || ',0)'
          when nvl(data_scale, 0) = 0 and data_precision <= 9 then 'INT'
          when nvl(data_scale, 0) = 0 and data_precision <= 18 then 'BIGINT'
          when nvl(data_scale, 0) >= 0 then 'DECIMAL(' || to_char(least(data_precision, 65)) || ',' || to_char(least(greatest(nvl(data_scale, 0), 0), 30)) || ')'
          else 'DECIMAL(38,10)'
        end
      when data_type = 'DATE' then 'DATETIME(6)'
      when data_type like 'TIMESTAMP%WITH TIME ZONE%' or data_type like 'TIMESTAMP%WITH LOCAL TIME ZONE%' then 'VARCHAR(40)'
      when data_type like 'TIMESTAMP%' then 'DATETIME(6)'
      when data_type in ('VARCHAR2', 'NVARCHAR2') then 'VARCHAR(' || to_char(least(nvl(char_length, data_length), 65535)) || ')'
      when data_type in ('CHAR', 'NCHAR') then 'CHAR(' || to_char(least(nvl(char_length, data_length), 255)) || ')'
      when data_type in ('CLOB', 'NCLOB') then 'LONGTEXT'
      when data_type = 'BLOB' then 'LONGBLOB'
      when data_type = 'RAW' and nvl(data_length, 0) <= 255 then 'VARBINARY(' || to_char(data_length) || ')'
      when data_type = 'RAW' then 'BLOB'
      when data_type = 'LONG RAW' then 'LONGBLOB'
      when data_type = 'LONG' then 'LONGTEXT'
      when data_type = 'XMLTYPE' then 'LONGTEXT'
      when data_type = 'BFILE' then 'VARCHAR(1024)'
      when data_type in ('FLOAT', 'BINARY_FLOAT', 'BINARY_DOUBLE') then 'DOUBLE'
      when data_type in ('UROWID', 'ROWID') then 'VARCHAR(256)'
      when data_type like 'INTERVAL YEAR%' or data_type like 'INTERVAL DAY%' then 'VARCHAR(50)'
      else data_type || ' [manual review]'
    end as target_type,
    case
      when data_type in ('LONG', 'LONG RAW', 'BFILE', 'XMLTYPE', 'UROWID', 'ROWID')
        or data_type like 'TIMESTAMP%WITH TIME ZONE%'
        or data_type like 'TIMESTAMP%WITH LOCAL TIME ZONE%'
        or data_type like 'INTERVAL YEAR%'
        or data_type like 'INTERVAL DAY%'
        then 'BLOCKER'
      when data_type in ('CLOB', 'NCLOB', 'BLOB')
        then 'HIGH'
      when data_type = 'NUMBER' and (data_precision is null or nvl(data_scale, 0) < 0)
        then 'MEDIUM'
      when data_type in ('DATE', 'RAW', 'FLOAT', 'BINARY_FLOAT', 'BINARY_DOUBLE')
        then 'MEDIUM'
      else 'LOW'
    end as risk_band,
    case
      when data_type = 'LONG' then 'Replace LONG with CLOB before migration when possible.'
      when data_type = 'LONG RAW' then 'Replace LONG RAW with BLOB to avoid conversion blockers.'
      when data_type = 'BFILE' then 'Move external file handling to object storage + metadata table.'
      when data_type = 'XMLTYPE' then 'Convert to JSON/LONGTEXT model and patch XML functions.'
      when data_type in ('UROWID', 'ROWID') then 'Remove rowid dependency from application logic.'
      when data_type like 'TIMESTAMP%WITH TIME ZONE%' or data_type like 'TIMESTAMP%WITH LOCAL TIME ZONE%' then 'Model timezone offset explicitly in schema/application.'
      when data_type like 'INTERVAL YEAR%' or data_type like 'INTERVAL DAY%' then 'Convert interval semantics to numeric units or ISO text.'
      when data_type = 'NUMBER' and data_precision is null then 'Pin explicit precision/scale to avoid overflow surprises.'
      when data_type = 'NUMBER' and nvl(data_scale, 0) < 0 then 'Normalize negative scale values before conversion.'
      when data_type = 'DATE' then 'Validate time component and timezone assumptions.'
      when data_type = 'RAW' and nvl(data_length, 0) > 255 then 'Review if column should be BLOB/LONGBLOB.'
      when data_type in ('FLOAT', 'BINARY_FLOAT', 'BINARY_DOUBLE') then 'Check precision drift tolerance in downstream systems.'
      when data_type in ('CLOB', 'NCLOB', 'BLOB') then 'Validate indexing/search/access pattern redesign.'
      else 'No major datatype refactor expected.'
    end as refactor_guidance
  from cols
)
select '<tr><td>' ||
       replace(replace(replace(replace(replace(owner, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' ||
       replace(replace(replace(replace(replace(table_name, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' ||
       replace(replace(replace(replace(replace(column_name, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' ||
       replace(replace(replace(replace(replace(data_type, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' || to_char(nvl(data_length, 0)) ||
       '</td><td>' || nvl(to_char(data_precision), '-') ||
       '</td><td>' || nvl(to_char(data_scale), '-') ||
       '</td><td>' ||
       case risk_band
         when 'BLOCKER' then '<span class="blocker">BLOCKER</span>'
         when 'HIGH' then '<span class="high">HIGH</span>'
         when 'MEDIUM' then '<span class="medium">MEDIUM</span>'
         else '<span class="low">LOW</span>'
       end ||
       '</td><td>' ||
       replace(replace(replace(replace(replace(target_type, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' ||
       replace(replace(replace(replace(replace(refactor_guidance, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' ||
       case when risk_band in ('BLOCKER', 'HIGH') then 'YES' else 'REVIEW' end ||
       '</td></tr>'
from (
  select owner, table_name, column_name, data_type, data_length, data_precision, data_scale, risk_band, target_type, refactor_guidance
  from mapped
  where risk_band <> 'LOW'
  order by decode(risk_band, 'BLOCKER', 1, 'HIGH', 2, 'MEDIUM', 3, 4), owner, table_name, column_name
)
where rownum <= 5000;
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
prompt &&REPORT_DIR/pre_migration_readiness.html
prompt &&REPORT_DIR/sct_conversion_guide.html
prompt &&REPORT_DIR/datatype_mapping_backlog.html
prompt

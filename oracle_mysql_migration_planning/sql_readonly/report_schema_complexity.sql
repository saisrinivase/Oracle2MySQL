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


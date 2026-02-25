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


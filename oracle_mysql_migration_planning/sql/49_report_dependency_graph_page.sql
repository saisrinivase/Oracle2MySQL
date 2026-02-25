set define on
set verify off
set feedback off
set heading off
set pagesize 0
set linesize 32767
set trimspool on
set termout on

define RUN_ID='&1'
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
prompt <div class="nav"><a href="index.html">Main Page</a> | <a href="discover.html">Discover Summary</a></div>

prompt <div class="card">
prompt <h2>Dependency Summary</h2>
prompt <table>
prompt <tr><th>Direction</th><th>Cross-Schema</th><th>Count</th></tr>
select '<tr><td>' || omm_html_escape(direction) || '</td><td>' || omm_html_escape(is_cross_schema) || '</td><td>' || to_char(cnt) || '</td></tr>'
from (
  select direction, is_cross_schema, count(*) as cnt
  from omm_dependency_graph
  where run_id = &&RUN_ID
  group by direction, is_cross_schema
  order by direction, is_cross_schema desc
);
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>Top Related Schemas</h2>
prompt <table>
prompt <tr><th>Related Owner</th><th>Edges</th></tr>
select '<tr><td>' || omm_html_escape(nvl(related_owner, '-')) || '</td><td>' || to_char(cnt) || '</td></tr>'
from (
  select related_owner, count(*) as cnt
  from omm_dependency_graph
  where run_id = &&RUN_ID
  group by related_owner
  order by cnt desc, related_owner
)
where rownum <= 20;
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>Dependency Edge Details (first 3000 rows)</h2>
prompt <table>
prompt <tr><th>Root Owner</th><th>Root Object</th><th>Type</th><th>Direction</th><th>Related Owner</th><th>Related Object</th><th>Related Type</th><th>DB Link</th><th>Cross-Schema</th></tr>
select '<tr><td>' || omm_html_escape(root_owner) || '</td><td>' ||
       omm_html_escape(root_object_name) || '</td><td>' ||
       omm_html_escape(root_object_type) || '</td><td>' ||
       omm_html_escape(direction) || '</td><td>' ||
       omm_html_escape(nvl(related_owner, '-')) || '</td><td>' ||
       omm_html_escape(nvl(related_object_name, '-')) || '</td><td>' ||
       omm_html_escape(nvl(related_object_type, '-')) || '</td><td>' ||
       omm_html_escape(nvl(referenced_link_name, '-')) || '</td><td>' ||
       omm_html_escape(is_cross_schema) || '</td></tr>'
from (
  select root_owner, root_object_name, root_object_type, direction,
         related_owner, related_object_name, related_object_type, referenced_link_name, is_cross_schema
  from omm_dependency_graph
  where run_id = &&RUN_ID
  order by direction, root_owner, root_object_type, root_object_name
)
where rownum <= 3000;
prompt </table>
prompt </div>

prompt </body>
prompt </html>

spool off


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


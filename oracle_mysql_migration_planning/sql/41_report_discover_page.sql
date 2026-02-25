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

spool "&&REPORT_DIR/discover.html"

prompt <!DOCTYPE html>
prompt <html lang="en">
prompt <head>
prompt <meta charset="utf-8">
prompt <title>Discover Summary</title>
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
prompt <h1>Discover Summary</h1>
prompt <div class="nav"><a href="index.html">Main Page</a> | <a href="discover_objects.html">Discover Details</a></div>

prompt <div class="card">
prompt <h2>Object Counts by Type</h2>
prompt <table>
prompt <tr><th>Object Type</th><th>Count</th></tr>
select '<tr><td>' || omm_html_escape(object_type) || '</td><td>' || to_char(cnt) || '</td></tr>'
from (
  select object_type, count(*) as cnt
  from omm_discover_objects
  where run_id = &&RUN_ID
  group by object_type
  order by cnt desc, object_type
);
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>Top 25 Largest Tables by Estimated MB</h2>
prompt <table>
prompt <tr><th>Owner</th><th>Table</th><th>Rows</th><th>Estimated MB</th><th>Last Analyzed</th></tr>
select '<tr><td>' || omm_html_escape(owner) || '</td><td>' || omm_html_escape(table_name) || '</td><td>' ||
       to_char(nvl(num_rows, 0)) || '</td><td>' ||
       to_char(round((nvl(num_rows, 0) * nvl(avg_row_len, 0)) / 1024 / 1024, 2), 'FM9999999990D00') || '</td><td>' ||
       nvl(to_char(last_analyzed, 'YYYY-MM-DD HH24:MI:SS'), '-') || '</td></tr>'
from (
  select owner, table_name, num_rows, avg_row_len, last_analyzed
  from omm_discover_tables
  where run_id = &&RUN_ID
  order by (nvl(num_rows, 0) * nvl(avg_row_len, 0)) desc, owner, table_name
)
where rownum <= 25;
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>PL/SQL Inventory</h2>
prompt <table>
prompt <tr><th>Object Type</th><th>Count</th><th>Total Lines</th></tr>
select '<tr><td>' || omm_html_escape(object_type) || '</td><td>' || to_char(cnt) || '</td><td>' || to_char(lines) || '</td></tr>'
from (
  select object_type, count(*) as cnt, nvl(sum(line_count), 0) as lines
  from omm_discover_code
  where run_id = &&RUN_ID
  group by object_type
  order by cnt desc, object_type
);
prompt </table>
prompt </div>

prompt </body>
prompt </html>

spool off

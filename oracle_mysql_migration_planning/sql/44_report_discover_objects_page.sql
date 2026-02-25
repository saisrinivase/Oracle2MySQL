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

spool "&&REPORT_DIR/discover_objects.html"

prompt <!DOCTYPE html>
prompt <html lang="en">
prompt <head>
prompt <meta charset="utf-8">
prompt <title>Discover Details - Objects</title>
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
prompt <h1>Discover Details - Objects (first 1000 rows)</h1>
prompt <div class="nav"><a href="index.html">Main Page</a> | <a href="discover.html">Discover Summary</a></div>
prompt <table>
prompt <tr><th>Owner</th><th>Object Name</th><th>Type</th><th>Status</th><th>Last DDL</th></tr>
select '<tr><td>' || omm_html_escape(owner) || '</td><td>' || omm_html_escape(object_name) || '</td><td>' ||
       omm_html_escape(object_type) || '</td><td>' || omm_html_escape(nvl(status, '-')) || '</td><td>' ||
       nvl(to_char(last_ddl_time, 'YYYY-MM-DD HH24:MI:SS'), '-') || '</td></tr>'
from (
  select owner, object_name, object_type, status, last_ddl_time
  from omm_discover_objects
  where run_id = &&RUN_ID
  order by owner, object_type, object_name
)
where rownum <= 1000;
prompt </table>
prompt </body>
prompt </html>

spool off

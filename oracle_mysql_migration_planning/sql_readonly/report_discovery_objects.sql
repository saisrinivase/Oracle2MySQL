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


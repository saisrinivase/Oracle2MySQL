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

spool "&&REPORT_DIR/source_target.html"

prompt <!DOCTYPE html>
prompt <html lang="en">
prompt <head>
prompt <meta charset="utf-8">
prompt <title>Source/Target Profile</title>
prompt <style>
prompt body { font-family: Arial, sans-serif; margin: 24px; background: #f7f9fc; color: #1f2937; }
prompt h1, h2 { margin: 0 0 12px 0; }
prompt .card { background: #ffffff; border: 1px solid #e5e7eb; border-radius: 10px; padding: 16px; margin-bottom: 16px; }
prompt table { border-collapse: collapse; width: 100%; }
prompt th, td { border: 1px solid #d1d5db; padding: 8px; text-align: left; vertical-align: top; }
prompt .nav { margin-bottom: 16px; }
prompt a { color: #0f4c81; text-decoration: none; }
prompt a:hover { text-decoration: underline; }
prompt ul { margin-top: 8px; }
prompt </style>
prompt </head>
prompt <body>
prompt <h1>Source/Target Profile</h1>
prompt <div class="nav"><a href="index.html">Main Page</a> | <a href="plan.html">Plan Summary</a></div>

prompt <div class="card">
prompt <h2>Baseline Profile</h2>
prompt <table>
prompt <tr><th>Source</th><th>Source Version</th><th>Owners</th><th>Target</th><th>Target Version</th><th>Engine</th><th>Charset</th><th>Collation</th><th>Timezone</th></tr>
select '<tr><td>' || omm_html_escape(source_platform || ':' || source_db_name) || '</td><td>' ||
       omm_html_escape(source_db_version) || '</td><td>' ||
       omm_html_escape(source_owner_filter) || '</td><td>' ||
       omm_html_escape(target_platform || ':' || target_db_name) || '</td><td>' ||
       omm_html_escape(target_db_version) || '</td><td>' ||
       omm_html_escape(target_storage_engine) || '</td><td>' ||
       omm_html_escape(target_charset) || '</td><td>' ||
       omm_html_escape(target_collation) || '</td><td>' ||
       omm_html_escape(target_timezone) || '</td></tr>'
from omm_source_target_profile
where run_id = &&RUN_ID;
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>Cutover and Validation Strategy</h2>
prompt <table>
prompt <tr><th>Cutover Strategy</th><th>CDC Strategy</th><th>Validation Strategy</th><th>SQL Mode</th></tr>
select '<tr><td>' || omm_html_escape(cutover_strategy) || '</td><td>' ||
       omm_html_escape(cdc_strategy) || '</td><td>' ||
       omm_html_escape(validation_strategy) || '</td><td>' ||
       omm_html_escape(target_sql_mode) || '</td></tr>'
from omm_source_target_profile
where run_id = &&RUN_ID;
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>Best-Practice Strategy Checklist</h2>
prompt <ul>
prompt <li>Freeze source and target naming/type mapping before DDL generation.</li>
prompt <li>Use Aurora parameter groups with strict SQL mode and utf8mb4 defaults.</li>
prompt <li>Use AWS SCT for schema conversion and AWS DMS full-load + CDC for movement.</li>
prompt <li>Treat sequence, package, mview, and db-link findings as mandatory redesign items.</li>
prompt <li>Gate cutover by DMS validation, row-count parity, checksum sampling, and critical query parity.</li>
prompt <li>Rehearse failover and rollback with Aurora writer/reader endpoint switch before production cutover.</li>
prompt </ul>
prompt </div>

prompt </body>
prompt </html>

spool off

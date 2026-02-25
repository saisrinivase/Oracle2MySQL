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

spool "&&REPORT_DIR/plan_actions.html"

prompt <!DOCTYPE html>
prompt <html lang="en">
prompt <head>
prompt <meta charset="utf-8">
prompt <title>Plan Details - Actions</title>
prompt <style>
prompt body { font-family: Arial, sans-serif; margin: 24px; background: #f7f9fc; color: #1f2937; }
prompt h1 { margin: 0 0 12px 0; }
prompt .nav { margin-bottom: 16px; }
prompt table { border-collapse: collapse; width: 100%; background: #ffffff; }
prompt th, td { border: 1px solid #d1d5db; padding: 8px; text-align: left; vertical-align: top; }
prompt a { color: #0f4c81; text-decoration: none; }
prompt a:hover { text-decoration: underline; }
prompt </style>
prompt </head>
prompt <body>
prompt <h1>Plan Details - Actions (first 3000 rows)</h1>
prompt <div class="nav"><a href="index.html">Main Page</a> | <a href="plan.html">Plan Summary</a></div>
prompt <table>
prompt <tr><th>Wave</th><th>Phase</th><th>Priority</th><th>Owner</th><th>Object</th><th>Type</th><th>Action</th><th>Action Detail</th></tr>
select '<tr><td>' || to_char(wave_no) || '</td><td>' || omm_html_escape(phase) || '</td><td>' ||
       omm_html_escape(nvl(priority, '-')) || '</td><td>' ||
       omm_html_escape(nvl(owner, '-')) || '</td><td>' ||
       omm_html_escape(nvl(object_name, '-')) || '</td><td>' ||
       omm_html_escape(nvl(object_type, '-')) || '</td><td>' ||
       omm_html_escape(action_name) || '</td><td>' ||
       omm_html_escape(substr(nvl(action_detail, '-'), 1, 300)) || '</td></tr>'
from (
  select wave_no, phase, priority, owner, object_name, object_type, action_name, action_detail
  from omm_plan_actions
  where run_id = &&RUN_ID
  order by wave_no,
           case priority
             when 'HIGH' then 1
             when 'MEDIUM' then 2
             when 'LOW' then 3
             else 4
           end,
           owner,
           object_name,
           action_id
)
where rownum <= 3000;
prompt </table>
prompt </body>
prompt </html>

spool off

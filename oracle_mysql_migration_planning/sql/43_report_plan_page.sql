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

spool "&&REPORT_DIR/plan.html"

prompt <!DOCTYPE html>
prompt <html lang="en">
prompt <head>
prompt <meta charset="utf-8">
prompt <title>Plan Summary</title>
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
prompt <h1>Plan Summary</h1>
prompt <div class="nav"><a href="index.html">Main Page</a> | <a href="plan_actions.html">Plan Details</a></div>

prompt <div class="card">
prompt <h2>Actions by Wave</h2>
prompt <table>
prompt <tr><th>Wave</th><th>Action Count</th></tr>
select '<tr><td>' || to_char(wave_no) || '</td><td>' || to_char(cnt) || '</td></tr>'
from (
  select wave_no, count(*) as cnt
  from omm_plan_actions
  where run_id = &&RUN_ID
  group by wave_no
  order by wave_no
);
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>Actions by Phase</h2>
prompt <table>
prompt <tr><th>Phase</th><th>Count</th></tr>
select '<tr><td>' || omm_html_escape(phase) || '</td><td>' || to_char(cnt) || '</td></tr>'
from (
  select phase, count(*) as cnt
  from omm_plan_actions
  where run_id = &&RUN_ID
  group by phase
  order by cnt desc, phase
);
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>Top 30 High-Priority Actions</h2>
prompt <table>
prompt <tr><th>Wave</th><th>Priority</th><th>Owner</th><th>Object</th><th>Action</th></tr>
select '<tr><td>' || to_char(wave_no) || '</td><td>' || omm_html_escape(nvl(priority, '-')) || '</td><td>' ||
       omm_html_escape(nvl(owner, '-')) || '</td><td>' ||
       omm_html_escape(nvl(object_name, '-')) || '</td><td>' ||
       omm_html_escape(action_name) || '</td></tr>'
from (
  select wave_no, priority, owner, object_name, action_name
  from omm_plan_actions
  where run_id = &&RUN_ID
  order by case priority
             when 'HIGH' then 1
             when 'MEDIUM' then 2
             when 'LOW' then 3
             else 4
           end,
           wave_no,
           owner,
           object_name
)
where rownum <= 30;
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>Blueprint Mapping Confidence</h2>
prompt <table>
prompt <tr><th>Confidence</th><th>Column Count</th></tr>
select '<tr><td>' || omm_html_escape(mapping_confidence) || '</td><td>' || to_char(cnt) || '</td></tr>'
from (
  select mapping_confidence, count(*) as cnt
  from omm_target_column_blueprint
  where run_id = &&RUN_ID
  group by mapping_confidence
  order by case mapping_confidence
             when 'LOW' then 1
             when 'MEDIUM' then 2
             when 'HIGH' then 3
             else 4
           end
);
prompt </table>
prompt </div>

prompt </body>
prompt </html>

spool off

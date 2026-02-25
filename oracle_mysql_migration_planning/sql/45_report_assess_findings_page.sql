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

spool "&&REPORT_DIR/assess_findings.html"

prompt <!DOCTYPE html>
prompt <html lang="en">
prompt <head>
prompt <meta charset="utf-8">
prompt <title>Assess Details - Findings</title>
prompt <style>
prompt body { font-family: Arial, sans-serif; margin: 24px; background: #f7f9fc; color: #1f2937; }
prompt h1 { margin: 0 0 12px 0; }
prompt .nav { margin-bottom: 16px; }
prompt table { border-collapse: collapse; width: 100%; background: #ffffff; }
prompt th, td { border: 1px solid #d1d5db; padding: 8px; text-align: left; vertical-align: top; }
prompt .sev-high { color: #b91c1c; font-weight: 700; }
prompt .sev-medium { color: #b45309; font-weight: 700; }
prompt .sev-low { color: #0369a1; font-weight: 700; }
prompt a { color: #0f4c81; text-decoration: none; }
prompt a:hover { text-decoration: underline; }
prompt </style>
prompt </head>
prompt <body>
prompt <h1>Assess Details - Findings (first 2000 rows)</h1>
prompt <div class="nav"><a href="index.html">Main Page</a> | <a href="assess.html">Assess Summary</a></div>
prompt <table>
prompt <tr><th>Severity</th><th>Category</th><th>Owner</th><th>Object</th><th>Type</th><th>Issue</th><th>Recommended Action</th></tr>
select '<tr><td>' ||
       case severity
         when 'CRITICAL' then '<span class="sev-high">CRITICAL</span>'
         when 'HIGH' then '<span class="sev-high">HIGH</span>'
         when 'MEDIUM' then '<span class="sev-medium">MEDIUM</span>'
         when 'LOW' then '<span class="sev-low">LOW</span>'
         else omm_html_escape(severity)
       end ||
       '</td><td>' || omm_html_escape(category) || '</td><td>' ||
       omm_html_escape(nvl(object_owner, '-')) || '</td><td>' ||
       omm_html_escape(nvl(object_name, '-')) || '</td><td>' ||
       omm_html_escape(nvl(object_type, '-')) || '</td><td>' ||
       omm_html_escape(substr(issue_detail, 1, 300)) || '</td><td>' ||
       omm_html_escape(substr(nvl(recommended_action, '-'), 1, 300)) || '</td></tr>'
from (
  select severity, category, object_owner, object_name, object_type, issue_detail, recommended_action
  from omm_assess_findings
  where run_id = &&RUN_ID
  order by case severity
             when 'CRITICAL' then 1
             when 'HIGH' then 2
             when 'MEDIUM' then 3
             when 'LOW' then 4
             else 5
           end,
           category,
           object_owner,
           object_name
)
where rownum <= 2000;
prompt </table>
prompt </body>
prompt </html>

spool off

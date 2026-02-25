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

spool "&&REPORT_DIR/assess.html"

prompt <!DOCTYPE html>
prompt <html lang="en">
prompt <head>
prompt <meta charset="utf-8">
prompt <title>Assess Summary</title>
prompt <style>
prompt body { font-family: Arial, sans-serif; margin: 24px; background: #f7f9fc; color: #1f2937; }
prompt h1, h2 { margin: 0 0 12px 0; }
prompt .card { background: #ffffff; border: 1px solid #e5e7eb; border-radius: 10px; padding: 16px; margin-bottom: 16px; }
prompt table { border-collapse: collapse; width: 100%; }
prompt th, td { border: 1px solid #d1d5db; padding: 8px; text-align: left; }
prompt .nav { margin-bottom: 16px; }
prompt .sev-high { color: #b91c1c; font-weight: 700; }
prompt .sev-medium { color: #b45309; font-weight: 700; }
prompt .sev-low { color: #0369a1; font-weight: 700; }
prompt a { color: #0f4c81; text-decoration: none; }
prompt a:hover { text-decoration: underline; }
prompt </style>
prompt </head>
prompt <body>
prompt <h1>Assess Summary</h1>
prompt <div class="nav"><a href="index.html">Main Page</a> | <a href="assess_findings.html">Assess Details</a></div>

prompt <div class="card">
prompt <h2>Findings by Severity</h2>
prompt <table>
prompt <tr><th>Severity</th><th>Count</th></tr>
select '<tr><td>' ||
       case severity
         when 'CRITICAL' then '<span class="sev-high">CRITICAL</span>'
         when 'HIGH' then '<span class="sev-high">HIGH</span>'
         when 'MEDIUM' then '<span class="sev-medium">MEDIUM</span>'
         when 'LOW' then '<span class="sev-low">LOW</span>'
         else omm_html_escape(severity)
       end || '</td><td>' || to_char(cnt) || '</td></tr>'
from (
  select severity, count(*) as cnt
  from omm_assess_findings
  where run_id = &&RUN_ID
  group by severity
  order by case severity
             when 'CRITICAL' then 1
             when 'HIGH' then 2
             when 'MEDIUM' then 3
             when 'LOW' then 4
             else 5
           end
);
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>Top Risk Categories</h2>
prompt <table>
prompt <tr><th>Category</th><th>Count</th><th>Highest Severity</th></tr>
select '<tr><td>' || omm_html_escape(category) || '</td><td>' || to_char(cnt) || '</td><td>' || omm_html_escape(max_severity) || '</td></tr>'
from (
  select
    category,
    count(*) as cnt,
    case max(case severity
               when 'CRITICAL' then 4
               when 'HIGH' then 3
               when 'MEDIUM' then 2
               when 'LOW' then 1
               else 0
             end)
      when 4 then 'CRITICAL'
      when 3 then 'HIGH'
      when 2 then 'MEDIUM'
      when 1 then 'LOW'
      else 'UNKNOWN'
    end as max_severity
  from omm_assess_findings
  where run_id = &&RUN_ID
  group by category
  order by cnt desc, category
)
where rownum <= 20;
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>Top 25 High-Risk Findings</h2>
prompt <table>
prompt <tr><th>Owner</th><th>Object</th><th>Type</th><th>Issue</th></tr>
select '<tr><td>' || omm_html_escape(nvl(object_owner, '-')) || '</td><td>' ||
       omm_html_escape(nvl(object_name, '-')) || '</td><td>' ||
       omm_html_escape(nvl(object_type, '-')) || '</td><td>' ||
       omm_html_escape(substr(issue_detail, 1, 220)) || '</td></tr>'
from (
  select object_owner, object_name, object_type, issue_detail
  from omm_assess_findings
  where run_id = &&RUN_ID
    and severity in ('CRITICAL', 'HIGH')
  order by object_owner, object_name, issue_code
)
where rownum <= 25;
prompt </table>
prompt </div>

prompt </body>
prompt </html>

spool off

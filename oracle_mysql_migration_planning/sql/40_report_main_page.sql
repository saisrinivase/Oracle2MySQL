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

spool "&&REPORT_DIR/index.html"

prompt <!DOCTYPE html>
prompt <html lang="en">
prompt <head>
prompt <meta charset="utf-8">
prompt <title>Oracle to MySQL Migration - Main Page</title>
prompt <style>
prompt body { font-family: Arial, sans-serif; margin: 24px; background: #f7f9fc; color: #1f2937; }
prompt h1, h2 { margin: 0 0 12px 0; }
prompt .muted { color: #6b7280; margin-bottom: 24px; }
prompt .card { background: #ffffff; border: 1px solid #e5e7eb; border-radius: 10px; padding: 16px; margin-bottom: 16px; }
prompt .grid { display: grid; grid-template-columns: repeat(auto-fit,minmax(240px,1fr)); gap: 12px; }
prompt .kpi { font-size: 28px; font-weight: 700; margin-top: 6px; }
prompt a { color: #0f4c81; text-decoration: none; }
prompt a:hover { text-decoration: underline; }
prompt ul { margin-top: 8px; }
prompt </style>
prompt </head>
prompt <body>
prompt <h1>Oracle to MySQL - Stage 1/2/3 Main Report</h1>

select '<div class="muted">Run ID: <strong>' || to_char(r.run_id) ||
       '</strong> | Database: <strong>' || omm_html_escape(r.oracle_db_name) ||
       '</strong> | Host: <strong>' || omm_html_escape(r.host_name) ||
       '</strong> | Owner Filter: <strong>' || omm_html_escape(r.source_owner_filter) ||
       '</strong></div>'
from omm_runs r
where r.run_id = &&RUN_ID;

prompt <div class="grid">
prompt <div class="card">
prompt <div>Total Objects</div>
select '<div class="kpi">' || to_char(count(*)) || '</div>' from omm_discover_objects where run_id = &&RUN_ID;
prompt </div>
prompt <div class="card">
prompt <div>Total Tables</div>
select '<div class="kpi">' || to_char(count(*)) || '</div>' from omm_discover_tables where run_id = &&RUN_ID;
prompt </div>
prompt <div class="card">
prompt <div>Total Findings</div>
select '<div class="kpi">' || to_char(count(*)) || '</div>' from omm_assess_findings where run_id = &&RUN_ID;
prompt </div>
prompt <div class="card">
prompt <div>Total Plan Actions</div>
select '<div class="kpi">' || to_char(count(*)) || '</div>' from omm_plan_actions where run_id = &&RUN_ID;
prompt </div>
prompt <div class="card">
prompt <div>Blueprint Columns</div>
select '<div class="kpi">' || to_char(count(*)) || '</div>' from omm_target_column_blueprint where run_id = &&RUN_ID;
prompt </div>
prompt </div>

prompt <div class="card">
prompt <h2>Report Pages</h2>
prompt <ul>
prompt <li><a href="discover.html">Discover Summary</a></li>
prompt <li><a href="assess.html">Assess Summary</a></li>
prompt <li><a href="plan.html">Plan Summary</a></li>
prompt <li><a href="discover_objects.html">Discover Details - Objects</a></li>
prompt <li><a href="assess_findings.html">Assess Details - Findings</a></li>
prompt <li><a href="plan_actions.html">Plan Details - Actions</a></li>
prompt <li><a href="source_target.html">Source/Target Profile</a></li>
prompt <li><a href="target_blueprint.html">Target Blueprint</a></li>
prompt <li><a href="dependency_graph.html">Dependency Graph</a></li>
prompt <li><a href="schema_complexity.html">Schema Complexity</a></li>
prompt </ul>
prompt </div>

prompt <div class="card">
prompt <h2>Target Baseline</h2>
prompt <table border="1" cellpadding="6" cellspacing="0">
prompt <tr><th>Target</th><th>Version</th><th>Engine</th><th>Charset</th><th>Collation</th><th>Cutover</th></tr>
select '<tr><td>' || omm_html_escape(p.target_platform) || '</td><td>' ||
       omm_html_escape(p.target_db_version) || '</td><td>' ||
       omm_html_escape(p.target_storage_engine) || '</td><td>' ||
       omm_html_escape(p.target_charset) || '</td><td>' ||
       omm_html_escape(p.target_collation) || '</td><td>' ||
       omm_html_escape(p.cutover_strategy) || '</td></tr>'
from omm_source_target_profile p
where p.run_id = &&RUN_ID;
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>Severity Snapshot</h2>
prompt <table border="1" cellpadding="6" cellspacing="0">
prompt <tr><th>Severity</th><th>Count</th></tr>
select '<tr><td>' || omm_html_escape(severity) || '</td><td>' || to_char(cnt) || '</td></tr>'
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

prompt </body>
prompt </html>

spool off

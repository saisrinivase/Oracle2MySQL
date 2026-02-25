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

spool "&&REPORT_DIR/source_intelligence.html"

prompt <!DOCTYPE html>
prompt <html lang="en">
prompt <head>
prompt <meta charset="utf-8">
prompt <title>Oracle Source Intelligence</title>
prompt <style>
prompt body { font-family: Arial, sans-serif; margin: 24px; background: #f7f9fc; color: #1f2937; }
prompt h1, h2 { margin: 0 0 12px 0; }
prompt .muted { color: #6b7280; margin-bottom: 20px; }
prompt .card { background: #ffffff; border: 1px solid #e5e7eb; border-radius: 10px; padding: 16px; margin-bottom: 16px; }
prompt .grid { display: grid; grid-template-columns: repeat(auto-fit,minmax(220px,1fr)); gap: 12px; }
prompt .kpi { font-size: 28px; font-weight: 700; margin-top: 6px; }
prompt table { border-collapse: collapse; width: 100%; }
prompt th, td { border: 1px solid #d1d5db; padding: 8px; text-align: left; vertical-align: top; }
prompt a { color: #0f4c81; text-decoration: none; }
prompt a:hover { text-decoration: underline; }
prompt ul { margin-top: 8px; }
prompt </style>
prompt </head>
prompt <body>
prompt <h1>Oracle Source Intelligence (POC)</h1>

select '<div class="muted">Run ID: <strong>' || to_char(r.run_id) ||
       '</strong> | DB: <strong>' || omm_html_escape(r.oracle_db_name) ||
       '</strong> | Host: <strong>' || omm_html_escape(r.host_name) ||
       '</strong> | Schema Filter: <strong>' || omm_html_escape(r.source_owner_filter) ||
       '</strong></div>'
from omm_runs r
where r.run_id = &&RUN_ID;

prompt <div class="card">
prompt <h2>Source Capacity Profile</h2>
prompt <table>
prompt <tr><th>Oracle Version</th><th>vCPUs</th><th>SGA (GB)</th><th>PGA Limit (GB)</th></tr>
select '<tr><td>' || omm_html_escape(source_db_version) || '</td><td>' ||
       to_char(source_vcpus) || '</td><td>' ||
       to_char(source_sga_gb) || '</td><td>' ||
       to_char(source_pga_limit_gb) || '</td></tr>'
from omm_source_capacity_profile
where run_id = &&RUN_ID;
prompt </table>
prompt </div>

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
prompt <div>Dependency Edges</div>
select '<div class="kpi">' || to_char(count(*)) || '</div>' from omm_dependency_graph where run_id = &&RUN_ID;
prompt </div>
prompt <div class="card">
prompt <div>Complexity Entries</div>
select '<div class="kpi">' || to_char(count(*)) || '</div>' from omm_schema_complexity where run_id = &&RUN_ID;
prompt </div>
prompt </div>

prompt <div class="card">
prompt <h2>POC Candidate Summary</h2>
prompt <table>
prompt <tr><th>Schema</th><th>Complexity Band</th><th>Score</th><th>Recommendation</th></tr>
select '<tr><td>' || omm_html_escape(owner) || '</td><td>' ||
       omm_html_escape(complexity_band) || '</td><td>' ||
       to_char(complexity_score) || '</td><td>' ||
       omm_html_escape(substr(poc_recommendation, 1, 220)) || '</td></tr>'
from (
  select owner, complexity_band, complexity_score, poc_recommendation
  from omm_schema_complexity
  where run_id = &&RUN_ID
  order by complexity_score
)
where rownum <= 20;
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>Next Readouts</h2>
prompt <ul>
prompt <li><a href="discover.html">Discovery Summary</a></li>
prompt <li><a href="discover_objects.html">Discovery Object Details</a></li>
prompt <li><a href="dependency_graph.html">Dependency Graph</a></li>
prompt <li><a href="schema_complexity.html">Schema Complexity</a></li>
prompt <li><a href="aws_sct_readiness.html">AWS SCT Readiness</a></li>
prompt </ul>
prompt </div>

prompt </body>
prompt </html>

spool off


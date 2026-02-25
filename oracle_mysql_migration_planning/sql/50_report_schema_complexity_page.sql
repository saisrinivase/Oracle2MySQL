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

spool "&&REPORT_DIR/schema_complexity.html"

prompt <!DOCTYPE html>
prompt <html lang="en">
prompt <head>
prompt <meta charset="utf-8">
prompt <title>Schema Complexity</title>
prompt <style>
prompt body { font-family: Arial, sans-serif; margin: 24px; background: #f7f9fc; color: #1f2937; }
prompt h1, h2 { margin: 0 0 12px 0; }
prompt .card { background: #ffffff; border: 1px solid #e5e7eb; border-radius: 10px; padding: 16px; margin-bottom: 16px; }
prompt table { border-collapse: collapse; width: 100%; }
prompt th, td { border: 1px solid #d1d5db; padding: 8px; text-align: left; vertical-align: top; }
prompt .nav { margin-bottom: 16px; }
prompt .low { color: #166534; font-weight: 700; }
prompt .medium { color: #b45309; font-weight: 700; }
prompt .high { color: #b91c1c; font-weight: 700; }
prompt .veryhigh { color: #7f1d1d; font-weight: 700; }
prompt a { color: #0f4c81; text-decoration: none; }
prompt a:hover { text-decoration: underline; }
prompt </style>
prompt </head>
prompt <body>
prompt <h1>Schema Complexity (POC Readiness)</h1>
prompt <div class="nav"><a href="index.html">Main Page</a> | <a href="assess.html">Assess Summary</a></div>

prompt <div class="card">
prompt <h2>Complexity Summary</h2>
prompt <table>
prompt <tr><th>Owner</th><th>Score</th><th>Band</th><th>High Findings</th><th>Cross-Schema Deps</th><th>POC Recommendation</th></tr>
select '<tr><td>' || omm_html_escape(owner) || '</td><td>' ||
       to_char(complexity_score) || '</td><td>' ||
       case complexity_band
         when 'LOW' then '<span class="low">LOW</span>'
         when 'MEDIUM' then '<span class="medium">MEDIUM</span>'
         when 'HIGH' then '<span class="high">HIGH</span>'
         else '<span class="veryhigh">VERY_HIGH</span>'
       end || '</td><td>' ||
       to_char(high_findings) || '</td><td>' ||
       to_char(cross_schema_dependencies) || '</td><td>' ||
       omm_html_escape(substr(poc_recommendation, 1, 220)) || '</td></tr>'
from (
  select owner, complexity_score, complexity_band, high_findings, cross_schema_dependencies, poc_recommendation
  from omm_schema_complexity
  where run_id = &&RUN_ID
  order by complexity_score desc, owner
);
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>Metric Breakdown</h2>
prompt <table>
prompt <tr><th>Owner</th><th>Tables</th><th>Views</th><th>PLSQL Objects</th><th>PLSQL Lines</th><th>Triggers</th><th>Sequences</th><th>Total Deps</th><th>Inbound</th><th>Cross-Schema</th><th>Medium Findings</th></tr>
select '<tr><td>' || omm_html_escape(owner) || '</td><td>' ||
       to_char(table_count) || '</td><td>' ||
       to_char(view_count) || '</td><td>' ||
       to_char(plsql_object_count) || '</td><td>' ||
       to_char(plsql_lines) || '</td><td>' ||
       to_char(trigger_count) || '</td><td>' ||
       to_char(sequence_count) || '</td><td>' ||
       to_char(dependency_edges) || '</td><td>' ||
       to_char(inbound_dependencies) || '</td><td>' ||
       to_char(cross_schema_dependencies) || '</td><td>' ||
       to_char(medium_findings) || '</td></tr>'
from (
  select owner, table_count, view_count, plsql_object_count, plsql_lines, trigger_count, sequence_count,
         dependency_edges, inbound_dependencies, cross_schema_dependencies, medium_findings
  from omm_schema_complexity
  where run_id = &&RUN_ID
  order by owner
);
prompt </table>
prompt </div>

prompt </body>
prompt </html>

spool off


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

spool "&&REPORT_DIR/aws_sct_readiness.html"

prompt <!DOCTYPE html>
prompt <html lang="en">
prompt <head>
prompt <meta charset="utf-8">
prompt <title>AWS SCT Readiness</title>
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
prompt <h1>AWS SCT Readiness (Source-First)</h1>
prompt <div class="nav"><a href="source_intelligence.html">Source Intelligence</a> | <a href="dependency_graph.html">Dependency Graph</a></div>

prompt <div class="card">
prompt <h2>Profile Snapshot</h2>
prompt <table>
prompt <tr><th>Source</th><th>Target</th><th>Cutover Strategy</th><th>CDC Strategy</th></tr>
select '<tr><td>' || omm_html_escape(source_platform || ' ' || source_db_version) || '</td><td>' ||
       omm_html_escape(target_platform || ' ' || target_db_version) || '</td><td>' ||
       omm_html_escape(cutover_strategy) || '</td><td>' ||
       omm_html_escape(cdc_strategy) || '</td></tr>'
from omm_source_target_profile
where run_id = &&RUN_ID;
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>Install and Access Readiness</h2>
prompt <table>
prompt <tr><th>Area</th><th>What to Confirm Before Installing AWS SCT</th></tr>
prompt <tr><td>Network</td><td>Reachability from SCT host to Oracle source and Aurora target endpoints over required ports.</td></tr>
prompt <tr><td>Credentials</td><td>Dedicated migration users with least privilege, password policy compliance, and credential rotation plan.</td></tr>
prompt <tr><td>Oracle Features</td><td>Inventory of packages, triggers, materialized views, db links, and scheduler jobs completed.</td></tr>
prompt <tr><td>Source Load</td><td>Peak/low windows identified; heavy scans and validation scheduled in low-impact windows.</td></tr>
prompt <tr><td>LOB/Data Types</td><td>LOB tables and legacy types flagged; SCT/DMS LOB mode strategy defined.</td></tr>
prompt <tr><td>Object Naming</td><td>Objects/columns >64 chars flagged for MySQL/Aurora naming redesign.</td></tr>
prompt <tr><td>Dependency Graph</td><td>Cross-schema and inbound dependency edges reviewed for cutover blast radius.</td></tr>
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>POC Gate to Start AWS SCT</h2>
prompt <ul>
prompt <li>Chosen POC schema has LOW or MEDIUM complexity band with clear recommendation.</li>
prompt <li>Cross-schema dependency list is approved by app owners.</li>
prompt <li>High-severity blockers are understood and logged as remediation tasks.</li>
prompt <li>Source and target profile baseline is signed off (version, charset, collation, timezone, SQL mode).</li>
prompt <li>SCT output review process is defined: converted DDL, action items, and exception handling.</li>
prompt </ul>
prompt </div>

prompt <div class="card">
prompt <h2>Suggested Sequence After This Report</h2>
prompt <table>
prompt <tr><th>Step</th><th>Action</th></tr>
prompt <tr><td>1</td><td>Lock one small schema POC candidate based on complexity and dependency profile.</td></tr>
prompt <tr><td>2</td><td>Install AWS SCT on secured workstation and create Oracle/Aurora endpoints.</td></tr>
prompt <tr><td>3</td><td>Run schema conversion report and triage unsupported objects.</td></tr>
prompt <tr><td>4</td><td>Generate POC DDL and validate with application smoke tests.</td></tr>
prompt <tr><td>5</td><td>Only then proceed to AWS DMS full-load + CDC planning.</td></tr>
prompt </table>
prompt </div>

prompt </body>
prompt </html>

spool off


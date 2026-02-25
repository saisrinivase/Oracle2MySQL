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
define SOURCE_DB_VERSION='&3'
define SOURCE_VCPUS='&4'
define SOURCE_SGA_GB='&5'
define SOURCE_PGA_LIMIT_GB='&6'

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
prompt <h1>Oracle Source Intelligence (Read-Only)</h1>

select '<div class="muted">Database: <strong>' ||
       replace(replace(replace(replace(replace(nvl(sys_context('USERENV', 'DB_NAME'), '-'), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</strong> | Host: <strong>' ||
       replace(replace(replace(replace(replace(nvl(sys_context('USERENV', 'SERVER_HOST'), '-'), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</strong> | Schema Filter: <strong>' ||
       replace(replace(replace(replace(replace(upper('&&SCHEMA_FILTER'), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</strong></div>'
from dual;

prompt <div class="card">
prompt <h2>Provided Source Profile</h2>
prompt <table>
prompt <tr><th>Oracle Version</th><th>vCPUs</th><th>SGA (GB)</th><th>PGA Limit (GB)</th></tr>
select '<tr><td>' ||
       replace(replace(replace(replace(replace('&&SOURCE_DB_VERSION', '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' || to_char(to_number('&&SOURCE_VCPUS')) ||
       '</td><td>' || to_char(to_number('&&SOURCE_SGA_GB')) ||
       '</td><td>' || to_char(to_number('&&SOURCE_PGA_LIMIT_GB')) ||
       '</td></tr>'
from dual;
prompt </table>
prompt </div>

prompt <div class="grid">
prompt <div class="card"><div>Total Objects</div>
select '<div class="kpi">' || to_char(count(*)) || '</div>'
from all_objects
where owner like upper('&&SCHEMA_FILTER')
  and object_type in (
    'TABLE', 'VIEW', 'MATERIALIZED VIEW', 'INDEX', 'SEQUENCE', 'SYNONYM',
    'PROCEDURE', 'FUNCTION', 'PACKAGE', 'PACKAGE BODY', 'TRIGGER', 'TYPE', 'TYPE BODY'
  );
prompt </div>

prompt <div class="card"><div>Total Tables</div>
select '<div class="kpi">' || to_char(count(*)) || '</div>'
from all_tables
where owner like upper('&&SCHEMA_FILTER');
prompt </div>

prompt <div class="card"><div>PL/SQL Lines</div>
select '<div class="kpi">' || to_char(count(*)) || '</div>'
from all_source
where owner like upper('&&SCHEMA_FILTER')
  and type in ('PROCEDURE', 'FUNCTION', 'PACKAGE', 'PACKAGE BODY', 'TRIGGER', 'TYPE', 'TYPE BODY');
prompt </div>

prompt <div class="card"><div>Dependency Edges</div>
select '<div class="kpi">' || to_char(count(*)) || '</div>'
from (
  select 1
  from all_dependencies d
  where d.owner like upper('&&SCHEMA_FILTER')
  union all
  select 1
  from all_dependencies d
  where d.referenced_owner like upper('&&SCHEMA_FILTER')
);
prompt </div>

prompt <div class="card"><div>Cross-Schema Edges</div>
select '<div class="kpi">' || to_char(count(*)) || '</div>'
from (
  select 1
  from all_dependencies d
  where d.owner like upper('&&SCHEMA_FILTER')
    and (d.referenced_owner is null or d.referenced_owner <> d.owner)
  union all
  select 1
  from all_dependencies d
  where d.referenced_owner like upper('&&SCHEMA_FILTER')
    and d.owner <> d.referenced_owner
);
prompt </div>
prompt </div>

prompt <div class="card">
prompt <h2>Owners in Scope</h2>
prompt <table>
prompt <tr><th>Owner</th><th>Objects</th></tr>
select '<tr><td>' ||
       replace(replace(replace(replace(replace(owner, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;') ||
       '</td><td>' || to_char(cnt) || '</td></tr>'
from (
  select owner, count(*) as cnt
  from all_objects
  where owner like upper('&&SCHEMA_FILTER')
  group by owner
  order by cnt desc, owner
);
prompt </table>
prompt </div>

prompt <div class="card">
prompt <h2>Reports</h2>
prompt <ul>
prompt <li><a href="discovery_summary.html">Discovery Summary</a></li>
prompt <li><a href="discovery_objects.html">Discovery Object Details</a></li>
prompt <li><a href="dependency_graph.html">Dependency Graph</a></li>
prompt <li><a href="schema_complexity.html">Schema Complexity</a></li>
prompt <li><a href="aws_sct_readiness.html">AWS SCT Readiness</a></li>
prompt </ul>
prompt </div>

prompt </body>
prompt </html>

spool off

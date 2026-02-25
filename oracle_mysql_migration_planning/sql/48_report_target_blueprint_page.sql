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

spool "&&REPORT_DIR/target_blueprint.html"

prompt <!DOCTYPE html>
prompt <html lang="en">
prompt <head>
prompt <meta charset="utf-8">
prompt <title>Target Blueprint</title>
prompt <style>
prompt body { font-family: Arial, sans-serif; margin: 24px; background: #f7f9fc; color: #1f2937; }
prompt h1, h2 { margin: 0 0 12px 0; }
prompt .card { background: #ffffff; border: 1px solid #e5e7eb; border-radius: 10px; padding: 16px; margin-bottom: 16px; }
prompt table { border-collapse: collapse; width: 100%; }
prompt th, td { border: 1px solid #d1d5db; padding: 8px; text-align: left; vertical-align: top; }
prompt .nav { margin-bottom: 16px; }
prompt .low { color: #b91c1c; font-weight: 700; }
prompt .medium { color: #b45309; font-weight: 700; }
prompt .high { color: #166534; font-weight: 700; }
prompt a { color: #0f4c81; text-decoration: none; }
prompt a:hover { text-decoration: underline; }
prompt </style>
prompt </head>
prompt <body>
prompt <h1>Target Blueprint (Oracle to MySQL Column Mapping)</h1>
prompt <div class="nav"><a href="index.html">Main Page</a> | <a href="source_target.html">Source/Target Profile</a></div>

prompt <div class="card">
prompt <h2>Mapping Confidence Summary</h2>
prompt <table>
prompt <tr><th>Confidence</th><th>Count</th></tr>
select '<tr><td>' ||
       case mapping_confidence
         when 'LOW' then '<span class="low">LOW</span>'
         when 'MEDIUM' then '<span class="medium">MEDIUM</span>'
         when 'HIGH' then '<span class="high">HIGH</span>'
         else omm_html_escape(mapping_confidence)
       end ||
       '</td><td>' || to_char(cnt) || '</td></tr>'
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

prompt <div class="card">
prompt <h2>Column Mapping Details (first 2500 rows)</h2>
prompt <table>
prompt <tr><th>Owner</th><th>Table</th><th>Column</th><th>Oracle Type</th><th>MySQL Type</th><th>Nullability</th><th>Confidence</th><th>Note</th></tr>
select '<tr><td>' || omm_html_escape(source_owner) || '</td><td>' ||
       omm_html_escape(source_table_name) || '</td><td>' ||
       omm_html_escape(source_column_name) || '</td><td>' ||
       omm_html_escape(oracle_data_type) || '</td><td>' ||
       omm_html_escape(mysql_data_type) || '</td><td>' ||
       omm_html_escape(mysql_nullability) || '</td><td>' ||
       omm_html_escape(mapping_confidence) || '</td><td>' ||
       omm_html_escape(substr(mapping_note, 1, 220)) || '</td></tr>'
from (
  select source_owner, source_table_name, source_column_name, oracle_data_type,
         mysql_data_type, mysql_nullability, mapping_confidence, mapping_note
  from omm_target_column_blueprint
  where run_id = &&RUN_ID
  order by case mapping_confidence
             when 'LOW' then 1
             when 'MEDIUM' then 2
             when 'HIGH' then 3
             else 4
           end,
           source_owner,
           source_table_name,
           source_column_name
)
where rownum <= 2500;
prompt </table>
prompt </div>

prompt </body>
prompt </html>

spool off


set define on
set verify off
set feedback on

define RUN_ID='&1'
define OWNER_FILTER='&2'

prompt Running schema complexity assessment...
prompt RUN_ID       = &&RUN_ID
prompt OWNER_FILTER = &&OWNER_FILTER

delete from omm_schema_complexity where run_id = &&RUN_ID;
delete from omm_assess_findings
 where run_id = &&RUN_ID
   and issue_code = 'SCHEMA_COMPLEXITY_BAND';

with base_owners as (
  select distinct o.owner
  from omm_discover_objects o
  where o.run_id = &&RUN_ID
    and o.owner like upper('&&OWNER_FILTER')
),
table_counts as (
  select owner, count(*) as table_count
  from omm_discover_tables
  where run_id = &&RUN_ID
  group by owner
),
view_counts as (
  select owner, count(*) as view_count
  from omm_discover_objects
  where run_id = &&RUN_ID
    and object_type = 'VIEW'
  group by owner
),
plsql_counts as (
  select owner, count(*) as plsql_object_count, nvl(sum(line_count), 0) as plsql_lines
  from omm_discover_code
  where run_id = &&RUN_ID
  group by owner
),
trigger_counts as (
  select owner, count(*) as trigger_count
  from omm_discover_objects
  where run_id = &&RUN_ID
    and object_type = 'TRIGGER'
  group by owner
),
sequence_counts as (
  select owner, count(*) as sequence_count
  from omm_discover_objects
  where run_id = &&RUN_ID
    and object_type = 'SEQUENCE'
  group by owner
),
dep_counts as (
  select root_owner as owner,
         count(*) as dependency_edges,
         sum(case when is_cross_schema = 'Y' then 1 else 0 end) as cross_schema_dependencies,
         sum(case when direction = 'INBOUND' then 1 else 0 end) as inbound_dependencies
  from omm_dependency_graph
  where run_id = &&RUN_ID
  group by root_owner
),
finding_counts as (
  select object_owner as owner,
         sum(case when severity in ('CRITICAL', 'HIGH') then 1 else 0 end) as high_findings,
         sum(case when severity = 'MEDIUM' then 1 else 0 end) as medium_findings
  from omm_assess_findings
  where run_id = &&RUN_ID
  group by object_owner
),
scored as (
  select
    bo.owner,
    nvl(tc.table_count, 0) as table_count,
    nvl(vc.view_count, 0) as view_count,
    nvl(pc.plsql_object_count, 0) as plsql_object_count,
    nvl(pc.plsql_lines, 0) as plsql_lines,
    nvl(tr.trigger_count, 0) as trigger_count,
    nvl(sc.sequence_count, 0) as sequence_count,
    nvl(dc.dependency_edges, 0) as dependency_edges,
    nvl(dc.cross_schema_dependencies, 0) as cross_schema_dependencies,
    nvl(dc.inbound_dependencies, 0) as inbound_dependencies,
    nvl(fc.high_findings, 0) as high_findings,
    nvl(fc.medium_findings, 0) as medium_findings,
    (
      nvl(tc.table_count, 0) * 1 +
      nvl(vc.view_count, 0) * 1 +
      nvl(pc.plsql_object_count, 0) * 2 +
      nvl(tr.trigger_count, 0) * 3 +
      nvl(sc.sequence_count, 0) * 1 +
      ceil(nvl(pc.plsql_lines, 0) / 500) +
      nvl(dc.cross_schema_dependencies, 0) * 3 +
      nvl(dc.inbound_dependencies, 0) * 4 +
      nvl(fc.high_findings, 0) * 5 +
      nvl(fc.medium_findings, 0) * 2
    ) as complexity_score
  from base_owners bo
  left join table_counts tc on tc.owner = bo.owner
  left join view_counts vc on vc.owner = bo.owner
  left join plsql_counts pc on pc.owner = bo.owner
  left join trigger_counts tr on tr.owner = bo.owner
  left join sequence_counts sc on sc.owner = bo.owner
  left join dep_counts dc on dc.owner = bo.owner
  left join finding_counts fc on fc.owner = bo.owner
)
insert into omm_schema_complexity (
  run_id, owner, table_count, view_count, plsql_object_count, plsql_lines,
  trigger_count, sequence_count, dependency_edges, cross_schema_dependencies,
  inbound_dependencies, high_findings, medium_findings, complexity_score,
  complexity_band, poc_recommendation
)
select
  &&RUN_ID,
  s.owner,
  s.table_count,
  s.view_count,
  s.plsql_object_count,
  s.plsql_lines,
  s.trigger_count,
  s.sequence_count,
  s.dependency_edges,
  s.cross_schema_dependencies,
  s.inbound_dependencies,
  s.high_findings,
  s.medium_findings,
  s.complexity_score,
  case
    when s.complexity_score <= 40 then 'LOW'
    when s.complexity_score <= 120 then 'MEDIUM'
    when s.complexity_score <= 250 then 'HIGH'
    else 'VERY_HIGH'
  end as complexity_band,
  case
    when s.complexity_score <= 120 and s.high_findings <= 5 then
      'Recommended as POC candidate for initial Oracle-to-Aurora migration wave.'
    when s.complexity_score <= 250 then
      'Possible POC with controlled scope; requires remediation backlog first.'
    else
      'Not recommended for first POC wave; defer after low/medium complexity schema.'
  end as poc_recommendation
from scored s;

insert into omm_assess_findings (
  finding_id, run_id, severity, category, object_owner, object_name, object_type,
  issue_code, issue_detail, recommended_action
)
select
  omm_finding_seq.nextval,
  &&RUN_ID,
  case complexity_band
    when 'VERY_HIGH' then 'HIGH'
    when 'HIGH' then 'MEDIUM'
    else 'LOW'
  end as severity,
  'SCHEMA_COMPLEXITY',
  owner,
  owner,
  'SCHEMA',
  'SCHEMA_COMPLEXITY_BAND',
  'Complexity band=' || complexity_band || ', score=' || to_char(complexity_score) ||
  ', high_findings=' || to_char(high_findings) || ', cross_schema_deps=' || to_char(cross_schema_dependencies),
  poc_recommendation
from omm_schema_complexity
where run_id = &&RUN_ID;

commit;

prompt Schema complexity assessment complete.


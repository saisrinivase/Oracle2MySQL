set define on
set verify off
set feedback on

define RUN_ID='&1'

prompt Running PLAN stage...
prompt RUN_ID = &&RUN_ID

delete from omm_plan_actions where run_id = &&RUN_ID;

insert into omm_plan_actions (
  action_id, run_id, wave_no, phase, priority, owner, object_name, object_type, action_name, action_detail
)
values (
  omm_action_seq.nextval,
  &&RUN_ID,
  0,
  'FOUNDATION',
  'HIGH',
  null,
  null,
  null,
  'Baseline target MySQL platform',
  'Finalize Aurora MySQL engine/version, charset=utf8mb4, collation, timezone, HA/backup settings before object conversion.'
);

insert into omm_plan_actions (
  action_id, run_id, wave_no, phase, priority, owner, object_name, object_type, action_name, action_detail
)
values (
  omm_action_seq.nextval,
  &&RUN_ID,
  0,
  'FOUNDATION',
  'HIGH',
  null,
  null,
  null,
  'Define migration quality gates',
  'Agree row-count parity, checksum sampling, functional UAT, and performance thresholds for go/no-go.'
);

insert into omm_plan_actions (
  action_id, run_id, wave_no, phase, priority, owner, object_name, object_type, action_name, action_detail
)
values (
  omm_action_seq.nextval,
  &&RUN_ID,
  0,
  'FOUNDATION',
  'MEDIUM',
  null,
  null,
  null,
  'Prepare naming and type-mapping standards',
  'Lock Oracle-to-MySQL datatype mappings, identifier length policy, and schema naming conventions.'
);

insert into omm_plan_actions (
  action_id, run_id, wave_no, phase, priority, owner, object_name, object_type, action_name, action_detail
)
values (
  omm_action_seq.nextval,
  &&RUN_ID,
  0,
  'FOUNDATION',
  'HIGH',
  null,
  null,
  null,
  'Provision Aurora RDS baseline',
  'Create Aurora MySQL cluster with writer/reader endpoints, Multi-AZ subnet group, KMS encryption, backups, and parameter groups.'
);

insert into omm_plan_actions (
  action_id, run_id, wave_no, phase, priority, owner, object_name, object_type, action_name, action_detail
)
values (
  omm_action_seq.nextval,
  &&RUN_ID,
  0,
  'FOUNDATION',
  'HIGH',
  null,
  null,
  null,
  'Prepare Oracle for CDC extraction',
  'Ensure ARCHIVELOG, supplemental logging, redo retention, and required replication privileges for AWS DMS CDC.'
);

insert into omm_plan_actions (
  action_id, run_id, wave_no, phase, priority, owner, object_name, object_type, action_name, action_detail
)
values (
  omm_action_seq.nextval,
  &&RUN_ID,
  0,
  'FOUNDATION',
  'HIGH',
  null,
  null,
  null,
  'Set up AWS SCT and DMS migration tasks',
  'Use AWS SCT for schema conversion and AWS DMS full-load + CDC tasks with table mapping, LOB mode, and validation enabled.'
);

insert into omm_plan_actions (
  action_id, run_id, wave_no, phase, priority, owner, object_name, object_type, action_name, action_detail
)
select
  omm_action_seq.nextval,
  &&RUN_ID,
  0,
  'FOUNDATION',
  'HIGH',
  null,
  null,
  null,
  'Approve source-target baseline profile',
  'Source=' || p.source_platform || ' ' || p.source_db_version ||
  ', Target=' || p.target_platform || ' ' || p.target_db_version ||
  ', Engine=' || p.target_storage_engine || ', Charset=' || p.target_charset ||
  ', Collation=' || p.target_collation || ', Cutover=' || p.cutover_strategy || '.'
from omm_source_target_profile p
where p.run_id = &&RUN_ID;

with object_risk as (
  select
    f.object_owner,
    f.object_name,
    f.object_type,
    max(
      case f.severity
        when 'CRITICAL' then 4
        when 'HIGH' then 3
        when 'MEDIUM' then 2
        when 'LOW' then 1
        else 0
      end
    ) as risk_score
  from omm_assess_findings f
  where f.run_id = &&RUN_ID
    and f.object_name is not null
  group by f.object_owner, f.object_name, f.object_type
)
insert into omm_plan_actions (
  action_id, run_id, wave_no, phase, priority, owner, object_name, object_type, action_name, action_detail
)
select
  omm_action_seq.nextval,
  &&RUN_ID,
  1,
  'LOW_RISK_CONVERSION',
  case
    when nvl(t.num_rows, 0) > 10000000 then 'MEDIUM'
    else 'LOW'
  end as priority,
  t.owner,
  t.table_name,
  'TABLE',
  'Convert and load low-risk table',
  'Generate Aurora MySQL DDL and perform initial load for table with no medium/high blockers.'
from omm_discover_tables t
left join object_risk r
  on r.object_owner = t.owner
 and r.object_name = t.table_name
 and r.object_type = 'TABLE'
where t.run_id = &&RUN_ID
  and nvl(r.risk_score, 0) <= 1;

with object_risk as (
  select
    f.object_owner,
    f.object_name,
    f.object_type,
    max(
      case f.severity
        when 'CRITICAL' then 4
        when 'HIGH' then 3
        when 'MEDIUM' then 2
        when 'LOW' then 1
        else 0
      end
    ) as risk_score
  from omm_assess_findings f
  where f.run_id = &&RUN_ID
    and f.object_name is not null
  group by f.object_owner, f.object_name, f.object_type
)
insert into omm_plan_actions (
  action_id, run_id, wave_no, phase, priority, owner, object_name, object_type, action_name, action_detail
)
select
  omm_action_seq.nextval,
  &&RUN_ID,
  2,
  'MEDIUM_RISK_REMEDIATION',
  'MEDIUM',
  r.object_owner,
  r.object_name,
  r.object_type,
  'Remediate medium-risk compatibility issue',
  'Apply targeted conversion rules and validate object behavior in Aurora integration testing.'
from object_risk r
where r.risk_score = 2;

with object_risk as (
  select
    f.object_owner,
    f.object_name,
    f.object_type,
    max(
      case f.severity
        when 'CRITICAL' then 4
        when 'HIGH' then 3
        when 'MEDIUM' then 2
        when 'LOW' then 1
        else 0
      end
    ) as risk_score
  from omm_assess_findings f
  where f.run_id = &&RUN_ID
    and f.object_name is not null
  group by f.object_owner, f.object_name, f.object_type
)
insert into omm_plan_actions (
  action_id, run_id, wave_no, phase, priority, owner, object_name, object_type, action_name, action_detail
)
select
  omm_action_seq.nextval,
  &&RUN_ID,
  3,
  'HIGH_RISK_REDESIGN',
  'HIGH',
  r.object_owner,
  r.object_name,
  r.object_type,
  'Redesign high-risk object before migration',
  'Re-architect object and dependent flows; require design sign-off before cutover planning.'
from object_risk r
where r.risk_score >= 3;

insert into omm_plan_actions (
  action_id, run_id, wave_no, phase, priority, owner, object_name, object_type, action_name, action_detail
)
select
  omm_action_seq.nextval,
  &&RUN_ID,
  case
    when b.mapping_confidence = 'LOW' then 3
    else 2
  end as wave_no,
  'DATATYPE_BLUEPRINT_REVIEW',
  case
    when b.mapping_confidence = 'LOW' then 'HIGH'
    else 'MEDIUM'
  end as priority,
  b.source_owner,
  b.source_table_name || '.' || b.source_column_name,
  'COLUMN',
  'Review datatype mapping before target DDL freeze',
  'Proposed MySQL type=' || b.mysql_data_type || '. ' || b.mapping_note
from omm_target_column_blueprint b
where b.run_id = &&RUN_ID
  and b.mapping_confidence in ('LOW', 'MEDIUM');

insert into omm_plan_actions (
  action_id, run_id, wave_no, phase, priority, owner, object_name, object_type, action_name, action_detail
)
select
  omm_action_seq.nextval,
  &&RUN_ID,
  case
    when max(case when severity in ('CRITICAL', 'HIGH') then 1 else 0 end) = 1 then 3
    else 2
  end as wave_no,
  'CATEGORY_REMEDIATION',
  case
    when max(case when severity in ('CRITICAL', 'HIGH') then 1 else 0 end) = 1 then 'HIGH'
    else 'MEDIUM'
  end as priority,
  null,
  null,
  null,
  'Category remediation: ' || category,
  'Findings in category "' || category || '": ' || to_char(count(*)) || '. Address this category with reusable migration patterns.'
from omm_assess_findings
where run_id = &&RUN_ID
group by category;

commit;

prompt PLAN stage complete.

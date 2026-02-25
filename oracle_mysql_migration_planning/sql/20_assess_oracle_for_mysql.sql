set define on
set verify off
set feedback on

define RUN_ID='&1'

prompt Running ASSESS stage...
prompt RUN_ID = &&RUN_ID

delete from omm_assess_findings where run_id = &&RUN_ID;

insert into omm_assess_findings (
  finding_id, run_id, severity, category, object_owner, object_name, object_type,
  issue_code, issue_detail, recommended_action
)
select
  omm_finding_seq.nextval,
  &&RUN_ID,
  'HIGH',
  'PLSQL_REWRITE',
  o.owner,
  o.object_name,
  o.object_type,
  'PLSQL_PACKAGE',
  'Package and package body logic has no direct MySQL package equivalent.',
  'Rewrite package contracts into application services or independent stored routines.'
from omm_discover_objects o
where o.run_id = &&RUN_ID
  and o.object_type in ('PACKAGE', 'PACKAGE BODY');

insert into omm_assess_findings (
  finding_id, run_id, severity, category, object_owner, object_name, object_type,
  issue_code, issue_detail, recommended_action
)
select
  omm_finding_seq.nextval,
  &&RUN_ID,
  'MEDIUM',
  'TRIGGER_COMPAT',
  o.owner,
  o.object_name,
  o.object_type,
  'TRIGGER_BEHAVIOR',
  'Trigger timing/ordering and SQL dialect must be reviewed for MySQL compatibility.',
  'Validate trigger ordering, mutating-table behavior, and SQL syntax in MySQL 8.'
from omm_discover_objects o
where o.run_id = &&RUN_ID
  and o.object_type = 'TRIGGER';

insert into omm_assess_findings (
  finding_id, run_id, severity, category, object_owner, object_name, object_type,
  issue_code, issue_detail, recommended_action
)
select
  omm_finding_seq.nextval,
  &&RUN_ID,
  'HIGH',
  'MVIEW_REDESIGN',
  m.owner,
  m.mview_name,
  'MATERIALIZED VIEW',
  'MVIEW_FEATURE_GAP',
  'Oracle materialized view semantics do not map 1:1 to native MySQL features.',
  'Replace with physical tables + refresh jobs or app-managed cache strategy.'
from omm_discover_mviews m
where m.run_id = &&RUN_ID;

insert into omm_assess_findings (
  finding_id, run_id, severity, category, object_owner, object_name, object_type,
  issue_code, issue_detail, recommended_action
)
select
  omm_finding_seq.nextval,
  &&RUN_ID,
  'HIGH',
  'DB_LINK_DEPENDENCY',
  d.owner,
  d.db_link,
  'DB_LINK',
  'REMOTE_DB_LINK',
  'Database links create cross-database runtime coupling not directly portable to MySQL.',
  'Move remote calls to integration services or ETL workflows.'
from omm_discover_db_links d
where d.run_id = &&RUN_ID;

insert into omm_assess_findings (
  finding_id, run_id, severity, category, object_owner, object_name, object_type,
  issue_code, issue_detail, recommended_action
)
select
  omm_finding_seq.nextval,
  &&RUN_ID,
  'MEDIUM',
  'INDEX_FUNCTION',
  e.index_owner,
  e.index_name,
  'INDEX',
  'FUNCTION_BASED_INDEX',
  'Function-based index expression found: ' || substr(e.column_expression, 1, 300),
  'Confirm expression determinism and rewrite using generated columns when required.'
from omm_discover_index_expr e
where e.run_id = &&RUN_ID;

insert into omm_assess_findings (
  finding_id, run_id, severity, category, object_owner, object_name, object_type,
  issue_code, issue_detail, recommended_action
)
select
  omm_finding_seq.nextval,
  &&RUN_ID,
  'MEDIUM',
  'DATATYPE_MAPPING',
  c.owner,
  c.table_name || '.' || c.column_name,
  'COLUMN',
  'NUMBER_NO_PRECISION',
  'NUMBER without explicit precision/scale can create non-deterministic MySQL mapping.',
  'Profile actual values and pin exact DECIMAL precision/scale.'
from omm_discover_columns c
where c.run_id = &&RUN_ID
  and c.data_type = 'NUMBER'
  and c.data_precision is null;

insert into omm_assess_findings (
  finding_id, run_id, severity, category, object_owner, object_name, object_type,
  issue_code, issue_detail, recommended_action
)
select
  omm_finding_seq.nextval,
  &&RUN_ID,
  'HIGH',
  'DATATYPE_MAPPING',
  c.owner,
  c.table_name || '.' || c.column_name,
  'COLUMN',
  'LEGACY_TYPE',
  'Column uses Oracle-specific or legacy type: ' || c.data_type,
  'Redesign this column type before migration.'
from omm_discover_columns c
where c.run_id = &&RUN_ID
  and c.data_type in ('LONG', 'LONG RAW', 'UROWID', 'BFILE', 'XMLTYPE');

insert into omm_assess_findings (
  finding_id, run_id, severity, category, object_owner, object_name, object_type,
  issue_code, issue_detail, recommended_action
)
select
  omm_finding_seq.nextval,
  &&RUN_ID,
  'LOW',
  'DATETIME_SEMANTICS',
  c.owner,
  c.table_name || '.' || c.column_name,
  'COLUMN',
  'DATE_SEMANTICS',
  'Oracle DATE includes time; review MySQL DATE/DATETIME/TIMESTAMP mapping.',
  'Define explicit mapping and timezone handling rules.'
from omm_discover_columns c
where c.run_id = &&RUN_ID
  and c.data_type = 'DATE';

insert into omm_assess_findings (
  finding_id, run_id, severity, category, object_owner, object_name, object_type,
  issue_code, issue_detail, recommended_action
)
select
  omm_finding_seq.nextval,
  &&RUN_ID,
  'MEDIUM',
  'DATATYPE_MAPPING',
  c.owner,
  c.table_name || '.' || c.column_name,
  'COLUMN',
  'LOB_REVIEW',
  'LOB column found: ' || c.data_type,
  'Validate storage engine, max packet size, and application streaming behavior.'
from omm_discover_columns c
where c.run_id = &&RUN_ID
  and c.data_type in ('CLOB', 'NCLOB', 'BLOB');

insert into omm_assess_findings (
  finding_id, run_id, severity, category, object_owner, object_name, object_type,
  issue_code, issue_detail, recommended_action
)
select
  omm_finding_seq.nextval,
  &&RUN_ID,
  'HIGH',
  'IDENTIFIER_LENGTH',
  o.owner,
  o.object_name,
  o.object_type,
  'NAME_GT_64',
  'Object name length exceeds MySQL 64-character identifier limit.',
  'Rename object and update dependent code paths.'
from omm_discover_objects o
where o.run_id = &&RUN_ID
  and length(o.object_name) > 64;

insert into omm_assess_findings (
  finding_id, run_id, severity, category, object_owner, object_name, object_type,
  issue_code, issue_detail, recommended_action
)
select
  omm_finding_seq.nextval,
  &&RUN_ID,
  'HIGH',
  'IDENTIFIER_LENGTH',
  c.owner,
  c.table_name || '.' || c.column_name,
  'COLUMN',
  'NAME_GT_64',
  'Column name length exceeds MySQL 64-character identifier limit.',
  'Rename column and adjust application queries and ETL.'
from omm_discover_columns c
where c.run_id = &&RUN_ID
  and length(c.column_name) > 64;

insert into omm_assess_findings (
  finding_id, run_id, severity, category, object_owner, object_name, object_type,
  issue_code, issue_detail, recommended_action
)
select
  omm_finding_seq.nextval,
  &&RUN_ID,
  'MEDIUM',
  'SYNONYM_USAGE',
  o.owner,
  o.object_name,
  o.object_type,
  'SYNONYM_REMAP',
  'Synonym usage found; MySQL object resolution differs.',
  'Replace synonyms with explicit schema-qualified references or compatibility views.'
from omm_discover_objects o
where o.run_id = &&RUN_ID
  and o.object_type = 'SYNONYM';

insert into omm_assess_findings (
  finding_id, run_id, severity, category, object_owner, object_name, object_type,
  issue_code, issue_detail, recommended_action
)
select
  omm_finding_seq.nextval,
  &&RUN_ID,
  'MEDIUM',
  'SEQUENCE_USAGE',
  o.owner,
  o.object_name,
  o.object_type,
  'SEQUENCE_REMAP',
  'Oracle sequence discovered.',
  'Map to AUTO_INCREMENT or dedicated sequence-emulation strategy.'
from omm_discover_objects o
where o.run_id = &&RUN_ID
  and o.object_type = 'SEQUENCE';

insert into omm_assess_findings (
  finding_id, run_id, severity, category, object_owner, object_name, object_type,
  issue_code, issue_detail, recommended_action
)
select
  omm_finding_seq.nextval,
  &&RUN_ID,
  'MEDIUM',
  'PARTITIONING',
  t.owner,
  t.table_name,
  'TABLE',
  'PARTITION_REVIEW',
  'Partitioned table requires explicit MySQL partition redesign and key checks.',
  'Validate partition key, prune behavior, and maintenance operations in MySQL.'
from omm_discover_tables t
where t.run_id = &&RUN_ID
  and t.partitioned = 'YES';

insert into omm_assess_findings (
  finding_id, run_id, severity, category, object_owner, object_name, object_type,
  issue_code, issue_detail, recommended_action
)
select
  omm_finding_seq.nextval,
  &&RUN_ID,
  'MEDIUM',
  'IOT_REDESIGN',
  t.owner,
  t.table_name,
  'TABLE',
  'IOT_TABLE',
  'Index-organized table detected.',
  'Redesign clustered access pattern using InnoDB primary key layout.'
from omm_discover_tables t
where t.run_id = &&RUN_ID
  and t.iot_type is not null;

insert into omm_assess_findings (
  finding_id, run_id, severity, category, object_owner, object_name, object_type,
  issue_code, issue_detail, recommended_action
)
select
  omm_finding_seq.nextval,
  &&RUN_ID,
  'MEDIUM',
  'SCHEDULER_JOBS',
  j.owner,
  j.job_name,
  'SCHEDULER_JOB',
  'JOB_REPLATFORM',
  'Oracle scheduler job found.',
  'Move scheduling to external orchestrator, MySQL events, or platform scheduler.'
from omm_discover_scheduler_jobs j
where j.run_id = &&RUN_ID;

commit;

prompt ASSESS stage complete.


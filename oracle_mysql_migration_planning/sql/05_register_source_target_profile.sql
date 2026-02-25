set define on
set verify off
set feedback on

define RUN_ID='&1'

prompt Registering SOURCE/TARGET profile (best-practice defaults)...
prompt RUN_ID = &&RUN_ID

delete from omm_source_target_profile where run_id = &&RUN_ID;

insert into omm_source_target_profile (
  run_id,
  source_platform,
  source_db_name,
  source_db_version,
  source_owner_filter,
  target_platform,
  target_db_name,
  target_db_version,
  target_storage_engine,
  target_charset,
  target_collation,
  target_timezone,
  target_sql_mode,
  cutover_strategy,
  cdc_strategy,
  validation_strategy,
  created_at
)
select
  r.run_id,
  'ORACLE',
  r.oracle_db_name,
  to_char(dbms_db_version.version) || '.' || to_char(dbms_db_version.release),
  r.source_owner_filter,
  'AURORA_MYSQL_RDS',
  'aurora_mysql_rds_cluster',
  '8.0.mysql_aurora.3',
  'Aurora MySQL (InnoDB-compatible)',
  'utf8mb4',
  'utf8mb4_0900_ai_ci',
  'UTC',
  'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION',
  'AWS_DMS_CDC_CUTOVER',
  'AWS DMS full-load + CDC from Oracle redo/archivelogs',
  'DMS validation + row-count + checksum-sampling + critical-query parity + performance-gate',
  systimestamp
from omm_runs r
where r.run_id = &&RUN_ID;

commit;

prompt SOURCE/TARGET profile registered.

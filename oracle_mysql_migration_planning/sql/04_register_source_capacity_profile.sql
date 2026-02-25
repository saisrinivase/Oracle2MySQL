set define on
set verify off
set feedback on

define RUN_ID='&1'
define SOURCE_DB_VERSION='&2'
define SOURCE_VCPUS='&3'
define SOURCE_SGA_GB='&4'
define SOURCE_PGA_LIMIT_GB='&5'

prompt Registering source capacity profile...
prompt RUN_ID              = &&RUN_ID
prompt SOURCE_DB_VERSION   = &&SOURCE_DB_VERSION
prompt SOURCE_VCPUS        = &&SOURCE_VCPUS
prompt SOURCE_SGA_GB       = &&SOURCE_SGA_GB
prompt SOURCE_PGA_LIMIT_GB = &&SOURCE_PGA_LIMIT_GB

delete from omm_source_capacity_profile where run_id = &&RUN_ID;

insert into omm_source_capacity_profile (
  run_id,
  source_db_version,
  source_vcpus,
  source_sga_gb,
  source_pga_limit_gb,
  captured_at,
  notes
)
values (
  &&RUN_ID,
  '&&SOURCE_DB_VERSION',
  to_number('&&SOURCE_VCPUS'),
  to_number('&&SOURCE_SGA_GB'),
  to_number('&&SOURCE_PGA_LIMIT_GB'),
  systimestamp,
  'POC source baseline for complexity and dependency assessment'
);

commit;

prompt Source capacity profile registered.


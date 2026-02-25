-- Usage:
--   sqlplus user/password@db @00_run_poc_discover_assess.sql SCHEMA_NAME REPORT_DIR SOURCE_DB_VERSION SOURCE_VCPUS SOURCE_SGA_GB SOURCE_PGA_LIMIT_GB
-- Example:
--   sqlplus app_user/secret@ORCL @00_run_poc_discover_assess.sql HR /tmp/oracle_poc_report 19c 8 350 40

set define on
set verify off
set feedback on
set serveroutput on

define SCHEMA_NAME='&1'
define REPORT_DIR='&2'
define SOURCE_DB_VERSION='&3'
define SOURCE_VCPUS='&4'
define SOURCE_SGA_GB='&5'
define SOURCE_PGA_LIMIT_GB='&6'

prompt
prompt === Oracle -> Aurora MySQL POC Discovery + Assessment ===
prompt SCHEMA_NAME         = &&SCHEMA_NAME
prompt REPORT_DIR          = &&REPORT_DIR
prompt SOURCE_DB_VERSION   = &&SOURCE_DB_VERSION
prompt SOURCE_VCPUS        = &&SOURCE_VCPUS
prompt SOURCE_SGA_GB       = &&SOURCE_SGA_GB
prompt SOURCE_PGA_LIMIT_GB = &&SOURCE_PGA_LIMIT_GB
prompt

@01_create_repo_objects.sql

column run_id_col new_value RUN_ID noprint
select omm_run_seq.nextval as run_id_col from dual;

insert into omm_runs (
  run_id,
  run_started_at,
  oracle_db_name,
  host_name,
  source_owner_filter,
  notes
)
values (
  &&RUN_ID,
  systimestamp,
  sys_context('USERENV', 'DB_NAME'),
  sys_context('USERENV', 'SERVER_HOST'),
  upper('&&SCHEMA_NAME'),
  'POC schema discovery + dependency graph + assessment'
);

commit;

@04_register_source_capacity_profile.sql &&RUN_ID &&SOURCE_DB_VERSION &&SOURCE_VCPUS &&SOURCE_SGA_GB &&SOURCE_PGA_LIMIT_GB
@05_register_source_target_profile.sql &&RUN_ID
@10_discover_source_oracle.sql &&RUN_ID &&SCHEMA_NAME
@11_discover_full_dependencies.sql &&RUN_ID &&SCHEMA_NAME
@20_assess_oracle_for_mysql.sql &&RUN_ID
@22_assess_schema_complexity.sql &&RUN_ID &&SCHEMA_NAME
@31_generate_mysql_target_blueprint.sql &&RUN_ID
@30_build_mysql_migration_plan.sql &&RUN_ID

host mkdir -p "&&REPORT_DIR"

@40_report_main_page.sql &&RUN_ID &&REPORT_DIR
@41_report_discover_page.sql &&RUN_ID &&REPORT_DIR
@42_report_assess_page.sql &&RUN_ID &&REPORT_DIR
@43_report_plan_page.sql &&RUN_ID &&REPORT_DIR
@44_report_discover_objects_page.sql &&RUN_ID &&REPORT_DIR
@45_report_assess_findings_page.sql &&RUN_ID &&REPORT_DIR
@46_report_plan_actions_page.sql &&RUN_ID &&REPORT_DIR
@47_report_source_target_page.sql &&RUN_ID &&REPORT_DIR
@48_report_target_blueprint_page.sql &&RUN_ID &&REPORT_DIR
@49_report_dependency_graph_page.sql &&RUN_ID &&REPORT_DIR
@50_report_schema_complexity_page.sql &&RUN_ID &&REPORT_DIR

update omm_runs
   set run_completed_at = systimestamp
 where run_id = &&RUN_ID;

commit;

prompt
prompt POC run completed.
prompt Run ID         : &&RUN_ID
prompt Main report    : &&REPORT_DIR/index.html
prompt Dependency page: &&REPORT_DIR/dependency_graph.html
prompt Complexity page: &&REPORT_DIR/schema_complexity.html
prompt


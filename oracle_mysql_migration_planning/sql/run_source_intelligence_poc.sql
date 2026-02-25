-- Purpose:
--   Source-first Oracle understanding for POC schema before migration assessment/planning.
--
-- Usage:
--   sqlplus user/password@db @run_source_intelligence_poc.sql SCHEMA_NAME REPORT_DIR SOURCE_DB_VERSION SOURCE_VCPUS SOURCE_SGA_GB SOURCE_PGA_LIMIT_GB
--
-- Example:
--   sqlplus app_user/secret@ORCL @run_source_intelligence_poc.sql HR /tmp/oracle_source_intelligence 19c 8 350 40

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
prompt === Oracle Source Intelligence (POC) ===
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
  'Source-first POC: inventory + dependencies + complexity + SCT readiness'
);

commit;

@04_register_source_capacity_profile.sql &&RUN_ID &&SOURCE_DB_VERSION &&SOURCE_VCPUS &&SOURCE_SGA_GB &&SOURCE_PGA_LIMIT_GB
@05_register_source_target_profile.sql &&RUN_ID
@10_discover_source_oracle.sql &&RUN_ID &&SCHEMA_NAME
@11_discover_full_dependencies.sql &&RUN_ID &&SCHEMA_NAME
@22_assess_schema_complexity.sql &&RUN_ID &&SCHEMA_NAME

host mkdir -p "&&REPORT_DIR"

@51_report_source_intelligence_overview.sql &&RUN_ID &&REPORT_DIR
@41_report_discover_page.sql &&RUN_ID &&REPORT_DIR
@44_report_discover_objects_page.sql &&RUN_ID &&REPORT_DIR
@49_report_dependency_graph_page.sql &&RUN_ID &&REPORT_DIR
@50_report_schema_complexity_page.sql &&RUN_ID &&REPORT_DIR
@52_report_aws_sct_readiness.sql &&RUN_ID &&REPORT_DIR

update omm_runs
   set run_completed_at = systimestamp
 where run_id = &&RUN_ID;

commit;

prompt
prompt Source intelligence run completed.
prompt Run ID         : &&RUN_ID
prompt Overview       : &&REPORT_DIR/source_intelligence.html
prompt Discovery      : &&REPORT_DIR/discover.html
prompt Dependencies   : &&REPORT_DIR/dependency_graph.html
prompt Complexity     : &&REPORT_DIR/schema_complexity.html
prompt AWS SCT Readiness: &&REPORT_DIR/aws_sct_readiness.html
prompt


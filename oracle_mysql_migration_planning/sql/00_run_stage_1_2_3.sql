-- Usage:
--   sqlplus user/password@db @00_run_stage_1_2_3.sql OWNER_FILTER REPORT_DIR
-- Example:
--   sqlplus app_user/secret@ORCL @00_run_stage_1_2_3.sql APP_% /tmp/oracle_mysql_report

set define on
set verify off
set feedback on
set serveroutput on

define OWNER_FILTER='&1'
define REPORT_DIR='&2'

prompt
prompt === Oracle -> MySQL Stage 1/2/3 Toolkit ===
prompt OWNER_FILTER = &&OWNER_FILTER
prompt REPORT_DIR   = &&REPORT_DIR
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
  upper('&&OWNER_FILTER'),
  'Stage 1/2/3: Discover + Assess + Plan'
);

commit;

@05_register_source_target_profile.sql &&RUN_ID
@10_discover_source_oracle.sql &&RUN_ID &&OWNER_FILTER
@11_discover_full_dependencies.sql &&RUN_ID &&OWNER_FILTER
@20_assess_oracle_for_mysql.sql &&RUN_ID
@22_assess_schema_complexity.sql &&RUN_ID &&OWNER_FILTER
@31_generate_mysql_target_blueprint.sql &&RUN_ID
@30_build_mysql_migration_plan.sql &&RUN_ID

-- SQL*Plus host command used only to ensure report folder exists.
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
prompt Run completed.
prompt Run ID       : &&RUN_ID
prompt Main report  : &&REPORT_DIR/index.html
prompt Discover page: &&REPORT_DIR/discover.html
prompt Assess page  : &&REPORT_DIR/assess.html
prompt Plan page    : &&REPORT_DIR/plan.html
prompt Profile page : &&REPORT_DIR/source_target.html
prompt Blueprint    : &&REPORT_DIR/target_blueprint.html
prompt Dependencies : &&REPORT_DIR/dependency_graph.html
prompt Complexity   : &&REPORT_DIR/schema_complexity.html
prompt

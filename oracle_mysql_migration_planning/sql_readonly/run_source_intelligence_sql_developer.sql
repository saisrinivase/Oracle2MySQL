-- Read-only Source Intelligence Runner (SQL Developer / SQL*Plus)
--
-- Usage:
--   @run_source_intelligence_sql_developer.sql SCHEMA_FILTER REPORT_DIR SOURCE_DB_VERSION SOURCE_VCPUS SOURCE_SGA_GB SOURCE_PGA_LIMIT_GB
--
-- Example:
--   @run_source_intelligence_sql_developer.sql HR /tmp/oracle_source_intel 19c 8 350 40
--
-- Important:
--   REPORT_DIR must already exist.

set define on
set verify off
set feedback on
set serveroutput on

define SCHEMA_FILTER='&1'
define REPORT_DIR='&2'
define SOURCE_DB_VERSION='&3'
define SOURCE_VCPUS='&4'
define SOURCE_SGA_GB='&5'
define SOURCE_PGA_LIMIT_GB='&6'

prompt
prompt === Oracle Source Intelligence (Read-Only) ===
prompt SCHEMA_FILTER      = &&SCHEMA_FILTER
prompt REPORT_DIR         = &&REPORT_DIR
prompt SOURCE_DB_VERSION  = &&SOURCE_DB_VERSION
prompt SOURCE_VCPUS       = &&SOURCE_VCPUS
prompt SOURCE_SGA_GB      = &&SOURCE_SGA_GB
prompt SOURCE_PGA_LIMIT_GB= &&SOURCE_PGA_LIMIT_GB
prompt

@report_source_intelligence.sql &&SCHEMA_FILTER &&REPORT_DIR &&SOURCE_DB_VERSION &&SOURCE_VCPUS &&SOURCE_SGA_GB &&SOURCE_PGA_LIMIT_GB
@report_discovery_summary.sql &&SCHEMA_FILTER &&REPORT_DIR
@report_discovery_objects.sql &&SCHEMA_FILTER &&REPORT_DIR
@report_dependency_graph.sql &&SCHEMA_FILTER &&REPORT_DIR
@report_schema_complexity.sql &&SCHEMA_FILTER &&REPORT_DIR
@report_aws_sct_readiness.sql &&SCHEMA_FILTER &&REPORT_DIR &&SOURCE_DB_VERSION &&SOURCE_VCPUS &&SOURCE_SGA_GB &&SOURCE_PGA_LIMIT_GB

prompt
prompt Reports generated:
prompt &&REPORT_DIR/source_intelligence.html
prompt &&REPORT_DIR/discovery_summary.html
prompt &&REPORT_DIR/discovery_objects.html
prompt &&REPORT_DIR/dependency_graph.html
prompt &&REPORT_DIR/schema_complexity.html
prompt &&REPORT_DIR/aws_sct_readiness.html
prompt


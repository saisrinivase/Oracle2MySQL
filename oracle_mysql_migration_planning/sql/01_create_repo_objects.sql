set define on
set verify off
set feedback on

prompt Creating repository objects (idempotent)...

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate q'[
    create table omm_runs (
      run_id              number primary key,
      run_started_at      timestamp not null,
      run_completed_at    timestamp,
      oracle_db_name      varchar2(128),
      host_name           varchar2(256),
      source_owner_filter varchar2(256),
      notes               varchar2(4000)
    )
  ]';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate q'[
    create table omm_discover_objects (
      run_id         number not null,
      owner          varchar2(128) not null,
      object_name    varchar2(128) not null,
      object_type    varchar2(30) not null,
      status         varchar2(30),
      created        date,
      last_ddl_time  date
    )
  ]';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate q'[
    create table omm_discover_tables (
      run_id         number not null,
      owner          varchar2(128) not null,
      table_name     varchar2(128) not null,
      num_rows       number,
      blocks         number,
      avg_row_len    number,
      partitioned    varchar2(3),
      temporary      varchar2(1),
      compression    varchar2(16),
      iot_type       varchar2(12),
      last_analyzed  date
    )
  ]';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate q'[
    create table omm_discover_columns (
      run_id          number not null,
      owner           varchar2(128) not null,
      table_name      varchar2(128) not null,
      column_name     varchar2(128) not null,
      data_type       varchar2(128),
      data_length     number,
      data_precision  number,
      data_scale      number,
      nullable        varchar2(1),
      char_used       varchar2(1)
    )
  ]';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate q'[
    create table omm_discover_code (
      run_id      number not null,
      owner       varchar2(128) not null,
      object_name varchar2(128) not null,
      object_type varchar2(30) not null,
      line_count  number
    )
  ]';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate q'[
    create table omm_discover_dependencies (
      run_id               number not null,
      owner                varchar2(128) not null,
      name                 varchar2(128) not null,
      type                 varchar2(30) not null,
      referenced_owner     varchar2(128),
      referenced_name      varchar2(128),
      referenced_type      varchar2(30),
      referenced_link_name varchar2(128)
    )
  ]';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate q'[
    create table omm_discover_db_links (
      run_id   number not null,
      owner    varchar2(128) not null,
      db_link  varchar2(128) not null,
      username varchar2(128),
      host     varchar2(4000)
    )
  ]';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate q'[
    create table omm_discover_scheduler_jobs (
      run_id         number not null,
      owner          varchar2(128) not null,
      job_name       varchar2(128) not null,
      enabled        varchar2(5),
      state          varchar2(15),
      program_name   varchar2(128),
      schedule_type  varchar2(20)
    )
  ]';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate q'[
    create table omm_discover_mviews (
      run_id             number not null,
      owner              varchar2(128) not null,
      mview_name         varchar2(128) not null,
      refresh_mode       varchar2(6),
      refresh_method     varchar2(1),
      build_mode         varchar2(7),
      last_refresh_type  varchar2(18),
      last_refresh_date  date
    )
  ]';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate q'[
    create table omm_discover_index_expr (
      run_id             number not null,
      index_owner        varchar2(128) not null,
      index_name         varchar2(128) not null,
      table_owner        varchar2(128),
      table_name         varchar2(128),
      column_expression  varchar2(4000)
    )
  ]';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate q'[
    create table omm_assess_findings (
      finding_id          number primary key,
      run_id              number not null,
      severity            varchar2(10) not null,
      category            varchar2(64) not null,
      object_owner        varchar2(128),
      object_name         varchar2(128),
      object_type         varchar2(30),
      issue_code          varchar2(64) not null,
      issue_detail        varchar2(4000) not null,
      recommended_action  varchar2(4000)
    )
  ]';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate q'[
    create table omm_plan_actions (
      action_id      number primary key,
      run_id         number not null,
      wave_no        number not null,
      phase          varchar2(64) not null,
      priority       varchar2(10),
      owner          varchar2(128),
      object_name    varchar2(128),
      object_type    varchar2(30),
      action_name    varchar2(256) not null,
      action_detail  varchar2(4000)
    )
  ]';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate q'[
    create table omm_source_capacity_profile (
      run_id               number primary key,
      source_db_version    varchar2(32) not null,
      source_vcpus         number,
      source_sga_gb        number,
      source_pga_limit_gb  number,
      captured_at          timestamp not null,
      notes                varchar2(4000)
    )
  ]';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate q'[
    create table omm_dependency_graph (
      run_id                 number not null,
      root_owner             varchar2(128) not null,
      root_object_name       varchar2(128) not null,
      root_object_type       varchar2(30) not null,
      direction              varchar2(16) not null,
      related_owner          varchar2(128),
      related_object_name    varchar2(128),
      related_object_type    varchar2(30),
      referenced_link_name   varchar2(128),
      is_cross_schema        varchar2(1) not null
    )
  ]';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate q'[
    create table omm_schema_complexity (
      run_id                     number not null,
      owner                      varchar2(128) not null,
      table_count                number,
      view_count                 number,
      plsql_object_count         number,
      plsql_lines                number,
      trigger_count              number,
      sequence_count             number,
      dependency_edges           number,
      cross_schema_dependencies  number,
      inbound_dependencies       number,
      high_findings              number,
      medium_findings            number,
      complexity_score           number,
      complexity_band            varchar2(16),
      poc_recommendation         varchar2(4000)
    )
  ]';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate q'[
    create table omm_source_target_profile (
      run_id                 number primary key,
      source_platform        varchar2(32) not null,
      source_db_name         varchar2(128) not null,
      source_db_version      varchar2(32),
      source_owner_filter    varchar2(256),
      target_platform        varchar2(32) not null,
      target_db_name         varchar2(128) not null,
      target_db_version      varchar2(32) not null,
      target_storage_engine  varchar2(32) not null,
      target_charset         varchar2(32) not null,
      target_collation       varchar2(64) not null,
      target_timezone        varchar2(64) not null,
      target_sql_mode        varchar2(4000),
      cutover_strategy       varchar2(64) not null,
      cdc_strategy           varchar2(128),
      validation_strategy    varchar2(128),
      created_at             timestamp not null
    )
  ]';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate q'[
    create table omm_target_column_blueprint (
      run_id                   number not null,
      source_owner             varchar2(128) not null,
      source_table_name        varchar2(128) not null,
      source_column_name       varchar2(128) not null,
      oracle_data_type         varchar2(128),
      oracle_data_length       number,
      oracle_data_precision    number,
      oracle_data_scale        number,
      oracle_nullable          varchar2(1),
      mysql_data_type          varchar2(128),
      mysql_nullability        varchar2(8),
      mysql_column_definition  varchar2(4000),
      mapping_confidence       varchar2(10),
      mapping_note             varchar2(4000)
    )
  ]';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate 'create sequence omm_run_seq start with 1 increment by 1 nocache';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate 'create sequence omm_finding_seq start with 1 increment by 1 nocache';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate 'create sequence omm_action_seq start with 1 increment by 1 nocache';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate 'create index omm_idx_discover_objects_run on omm_discover_objects(run_id)';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate 'create index omm_idx_discover_tables_run on omm_discover_tables(run_id)';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate 'create index omm_idx_discover_columns_run on omm_discover_columns(run_id)';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate 'create index omm_idx_assess_findings_run on omm_assess_findings(run_id)';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate 'create index omm_idx_plan_actions_run on omm_plan_actions(run_id)';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate 'create index omm_idx_blueprint_run on omm_target_column_blueprint(run_id)';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate 'create index omm_idx_dep_graph_run on omm_dependency_graph(run_id)';
exception
  when e_exists then null;
end;
/

declare
  e_exists exception;
  pragma exception_init(e_exists, -955);
begin
  execute immediate 'create index omm_idx_schema_complexity_run on omm_schema_complexity(run_id)';
exception
  when e_exists then null;
end;
/

create or replace function omm_html_escape(p_text in varchar2)
  return varchar2
  deterministic
is
  l_text varchar2(32767);
begin
  l_text := nvl(p_text, '');
  l_text := replace(l_text, '&', '&amp;');
  l_text := replace(l_text, '<', '&lt;');
  l_text := replace(l_text, '>', '&gt;');
  l_text := replace(l_text, '"', '&quot;');
  l_text := replace(l_text, '''', '&#39;');
  return l_text;
end;
/

prompt Repository objects ready.

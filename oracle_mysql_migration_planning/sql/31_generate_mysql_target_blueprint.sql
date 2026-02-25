set define on
set verify off
set feedback on

define RUN_ID='&1'

prompt Building TARGET blueprint (Oracle columns -> MySQL column definitions)...
prompt RUN_ID = &&RUN_ID

delete from omm_target_column_blueprint where run_id = &&RUN_ID;

with mapped_columns as (
  select
    c.run_id,
    c.owner as source_owner,
    c.table_name as source_table_name,
    c.column_name as source_column_name,
    c.data_type as oracle_data_type,
    c.data_length as oracle_data_length,
    c.data_precision as oracle_data_precision,
    c.data_scale as oracle_data_scale,
    c.nullable as oracle_nullable,
    case
      when c.data_type = 'NUMBER' and c.data_precision is null then 'DECIMAL(38,10)'
      when c.data_type = 'NUMBER' and nvl(c.data_scale, 0) = 0 and c.data_precision between 1 and 9 then 'INT'
      when c.data_type = 'NUMBER' and nvl(c.data_scale, 0) = 0 and c.data_precision between 10 and 18 then 'BIGINT'
      when c.data_type = 'NUMBER' then
        'DECIMAL(' || to_char(least(nvl(c.data_precision, 38), 65)) || ',' ||
        to_char(least(greatest(nvl(c.data_scale, 0), 0), 30)) || ')'
      when c.data_type in ('VARCHAR2', 'NVARCHAR2') then
        'VARCHAR(' || to_char(least(greatest(nvl(c.data_length, 1), 1), 16383)) || ')'
      when c.data_type in ('CHAR', 'NCHAR') then
        'CHAR(' || to_char(least(greatest(nvl(c.data_length, 1), 1), 255)) || ')'
      when c.data_type = 'DATE' then 'DATETIME'
      when c.data_type like 'TIMESTAMP%' then 'DATETIME(6)'
      when c.data_type in ('CLOB', 'NCLOB', 'LONG', 'XMLTYPE') then 'LONGTEXT'
      when c.data_type in ('BLOB', 'LONG RAW', 'BFILE') then 'LONGBLOB'
      when c.data_type = 'RAW' then
        case
          when nvl(c.data_length, 0) between 1 and 65535 then
            'VARBINARY(' || to_char(c.data_length) || ')'
          else
            'LONGBLOB'
        end
      when c.data_type in ('FLOAT', 'BINARY_FLOAT', 'BINARY_DOUBLE') then 'DOUBLE'
      else 'TEXT'
    end as mysql_data_type,
    case
      when c.nullable = 'N' then 'NOT NULL'
      else 'NULL'
    end as mysql_nullability,
    case
      when c.data_type in ('LONG', 'LONG RAW', 'BFILE', 'XMLTYPE') then 'LOW'
      when c.data_type = 'NUMBER' and c.data_precision is null then 'MEDIUM'
      else 'HIGH'
    end as mapping_confidence,
    case
      when c.data_type = 'NUMBER' and c.data_precision is null then
        'NUMBER precision/scale undefined; verify value ranges before final DDL.'
      when c.data_type in ('LONG', 'LONG RAW', 'BFILE') then
        'Legacy Oracle type; redesign recommended before production cutover.'
      when c.data_type = 'XMLTYPE' then
        'XMLTYPE mapped to LONGTEXT; validate parser/query behavior in app layer.'
      when c.data_type = 'DATE' then
        'Oracle DATE includes time; ensure application semantics align with DATETIME.'
      else
        'Direct mapping candidate under baseline target profile.'
    end as mapping_note
  from omm_discover_columns c
  where c.run_id = &&RUN_ID
)
insert into omm_target_column_blueprint (
  run_id,
  source_owner,
  source_table_name,
  source_column_name,
  oracle_data_type,
  oracle_data_length,
  oracle_data_precision,
  oracle_data_scale,
  oracle_nullable,
  mysql_data_type,
  mysql_nullability,
  mysql_column_definition,
  mapping_confidence,
  mapping_note
)
select
  m.run_id,
  m.source_owner,
  m.source_table_name,
  m.source_column_name,
  m.oracle_data_type,
  m.oracle_data_length,
  m.oracle_data_precision,
  m.oracle_data_scale,
  m.oracle_nullable,
  m.mysql_data_type,
  m.mysql_nullability,
  '`' || lower(m.source_column_name) || '` ' || m.mysql_data_type || ' ' || m.mysql_nullability,
  m.mapping_confidence,
  m.mapping_note
from mapped_columns m;

commit;

prompt TARGET blueprint build complete.


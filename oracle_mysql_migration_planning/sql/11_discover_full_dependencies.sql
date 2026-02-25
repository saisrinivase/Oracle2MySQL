set define on
set verify off
set feedback on

define RUN_ID='&1'
define OWNER_FILTER='&2'

prompt Running full dependency graph discovery...
prompt RUN_ID       = &&RUN_ID
prompt OWNER_FILTER = &&OWNER_FILTER

delete from omm_dependency_graph where run_id = &&RUN_ID;

-- Outbound dependencies from the selected schema(s) to any referenced object.
insert into omm_dependency_graph (
  run_id, root_owner, root_object_name, root_object_type, direction,
  related_owner, related_object_name, related_object_type, referenced_link_name, is_cross_schema
)
select
  &&RUN_ID,
  d.owner as root_owner,
  d.name as root_object_name,
  d.type as root_object_type,
  'OUTBOUND' as direction,
  d.referenced_owner as related_owner,
  d.referenced_name as related_object_name,
  d.referenced_type as related_object_type,
  d.referenced_link_name,
  case
    when d.referenced_owner is null then 'Y'
    when d.referenced_owner <> d.owner then 'Y'
    else 'N'
  end as is_cross_schema
from omm_discover_dependencies d
where d.run_id = &&RUN_ID
  and d.owner like upper('&&OWNER_FILTER');

-- Inbound dependencies from other schemas into the selected schema(s).
insert into omm_dependency_graph (
  run_id, root_owner, root_object_name, root_object_type, direction,
  related_owner, related_object_name, related_object_type, referenced_link_name, is_cross_schema
)
select
  &&RUN_ID,
  d.referenced_owner as root_owner,
  d.referenced_name as root_object_name,
  d.referenced_type as root_object_type,
  'INBOUND' as direction,
  d.owner as related_owner,
  d.name as related_object_name,
  d.type as related_object_type,
  d.referenced_link_name,
  case
    when d.owner <> d.referenced_owner then 'Y'
    else 'N'
  end as is_cross_schema
from all_dependencies d
where d.referenced_owner like upper('&&OWNER_FILTER')
  and d.owner not in (
    'SYS', 'SYSTEM', 'XDB', 'MDSYS', 'CTXSYS', 'OUTLN',
    'ORDSYS', 'DBSNMP', 'GSMADMIN_INTERNAL'
  );

commit;

prompt Full dependency graph discovery complete.


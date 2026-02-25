# Oracle to MySQL Assessment (Final)

This repository is intentionally cleaned to one final runnable script:

- `oracle_mysql_migration_planning/sql_readonly/oracle2mysql_assement.sql`

## SQL Developer Usage
1. Connect to Oracle source in SQL Developer.
2. Open SQL Worksheet.
3. Set working folder to:
   - `<repo_root>/oracle_mysql_migration_planning/sql_readonly`
4. Create report output folder:
```bash
mkdir -p /tmp/oracle_source_intel/poc_hr
chmod 700 /tmp/oracle_source_intel
chmod 700 /tmp/oracle_source_intel/poc_hr
```
5. Run using `F5`:
```sql
@oracle2mysql_assement.sql HR /tmp/oracle_source_intel/poc_hr 19c 8 350 40
```

## Parameters
```sql
@oracle2mysql_assement.sql <SCHEMA_FILTER> <REPORT_DIR> <SOURCE_DB_VERSION> <SOURCE_VCPUS> <SOURCE_SGA_GB> <SOURCE_PGA_LIMIT_GB>
```

Example:
```sql
@oracle2mysql_assement.sql APP_% /tmp/oracle_source_intel/app_poc 19c 8 350 40
```

## Important
- `REPORT_DIR` must be `/tmp/oracle_source_intel` or a child path.
- Script is read-only (`SELECT` + `SPOOL` only).

## Sample Reports (In Git)
Open this file for a quick preview:
- `oracle_mysql_migration_planning/sql_readonly/samples/final_preview/source_intelligence.html`

Included sample pages:
- `pre_migration_readiness.html`
- `sct_conversion_guide.html`
- `datatype_mapping_backlog.html`

# Oracle to Aurora MySQL Migration Toolkit

This repository contains SQL-first discovery and assessment scripts for migrating Oracle 19c workloads to Aurora MySQL, with a focus on source-system understanding before SCT conversion.

## Who Can Use This
Anyone with:
- Oracle SQL Developer
- Access to an Oracle source database (with metadata read privileges)
- A local clone of this repository

## Repository Layout
- `oracle_mysql_migration_planning/sql_readonly`: read-only HTML report generators for SQL Developer
- `oracle_mysql_migration_planning/sql`: modular stage-based scripts (discover, assess, plan)
- `oracle_mysql_migration_planning/smoke_test`: optional Docker-based smoke test assets
- `oracle_mysql_migration_planning/STRATEGY_SOURCE_FIRST_AWS_SCT.md`: high-level migration strategy

## Recommended Path
Use the read-only single script first:
- `oracle_mysql_migration_planning/sql_readonly/run_source_intelligence_single_script_v2_enterprise.sql`

Use locked baseline when you need reproducibility:
- `oracle_mysql_migration_planning/sql_readonly/run_source_intelligence_single_script_v1_locked.sql`

## Detailed Steps (SQL Developer)
1. Clone repo and identify `<repo_root>` (folder where this repo is located).
2. Open SQL Developer and connect to Oracle source.
3. Open SQL Worksheet.
4. Set SQL Developer working directory to:
   - `<repo_root>/oracle_mysql_migration_planning/sql_readonly`
5. Create secure report directory on your machine:
   - `mkdir -p /tmp/oracle_source_intel/poc_hr`
   - `chmod 700 /tmp/oracle_source_intel`
   - `chmod 700 /tmp/oracle_source_intel/poc_hr`
6. Run with `F5` (Run Script):

```sql
@run_source_intelligence_single_script_v2_enterprise.sql HR /tmp/oracle_source_intel/poc_hr 19c 8 350 40
```

7. Open generated main report:
   - `/tmp/oracle_source_intel/poc_hr/source_intelligence.html`
8. Review enterprise gating reports:
   - `enterprise_prereq_gate.html`
   - `sct_decision_matrix.html`
   - `datatype_refactor_backlog.html`
9. Decide SCT next action:
   - `READY_FOR_SCT_POC`: proceed with SCT conversion cycle
   - `SCT_ASSESSMENT_FIRST`: run SCT assessment before conversion
   - `REFACTOR_BEFORE_SCT_CONVERSION`: patch blockers first

## Parameter Template
Use this command format for any schema:

```sql
@run_source_intelligence_single_script_v2_enterprise.sql <schema_filter> <report_dir_under_/tmp/oracle_source_intel> <oracle_version> <vcpus> <sga_gb> <pga_limit_gb>
```

Example:
```sql
@run_source_intelligence_single_script_v2_enterprise.sql APP_% /tmp/oracle_source_intel/app_poc 19c 8 350 40
```

## Security Controls in v2
- `REPORT_DIR` is restricted by allowlist in script:
  - default base: `/tmp/oracle_source_intel`
  - allowed: base path or subdirectories under it
- Script exits before writing files if path is outside allowlist.
- Script does not create directories.

## Sample Reports (No Oracle Needed)
Start at:
- `<repo_root>/oracle_mysql_migration_planning/sql_readonly/samples/v2_enterprise_poc/source_intelligence.html`

These files are mock outputs for format preview only.

## Versioning
- Lock metadata and checksums:
  - `oracle_mysql_migration_planning/sql_readonly/VERSION_LOCK.md`

## Git Push Basics
1. `git status`
2. `git add .`
3. `git commit -m "message"`
4. `git push`

For this repo, `origin` is configured as:
- `https://github.com/saisrinivase/Oracle2MySQL.git`

# Read-Only Oracle Source Intelligence (SQL Developer)

This package generates Oracle source discovery and assessment HTML reports without changing schema objects or table data.

Detailed execution runbook:
- `RUNBOOK.md`

Audience:
- Any engineer/DBA using SQL Developer with Oracle metadata access.

## Safety Guarantees
- No `CREATE`
- No `INSERT`
- No `UPDATE`
- No `DELETE`
- No `MERGE`
- No script chaining (`@` / `@@`) inside single-script versions

All versions are `SELECT` + `SPOOL` only.

## Version Strategy
- `run_source_intelligence_single_script_v1_locked.sql`
  - Frozen baseline.
  - Do not edit.
  - Lock metadata is in `VERSION_LOCK.md`.
- `oracle2mysql_assement.sql`
  - Enhancement track for enterprise-grade reporting.
  - Includes SCT decisioning and datatype refactor backlog outputs.
- `run_source_intelligence_single_script_v2_enterprise.sql`
  - Backward-compatible alias of the same v2 logic.

## Run from SQL Developer (Single Script)
1. Open SQL Worksheet connected to source Oracle.
2. Set script path to this folder:
   - `<repo_root>/oracle_mysql_migration_planning/sql_readonly`
3. Ensure output folder exists under allowed base path (default allowlist: `/tmp/oracle_source_intel`).
4. Run with `F5` (Run Script):

```sql
@oracle2mysql_assement.sql YOUR_SCHEMA /tmp/oracle_source_intel 19c 8 350 40
```

Wildcard schema filters are supported (example: `APP_%`).

## REPORT_DIR Security Guard (v2)
- `v2` enforces `REPORT_DIR` to be:
  - exactly `/tmp/oracle_source_intel`, or
  - a child path under it (example: `/tmp/oracle_source_intel/poc_hr`)
- If a path outside this base is provided, script exits with an error before any report is written.
- The script does not create directories. Create the folder beforehand.

Example:
```bash
mkdir -p /tmp/oracle_source_intel/poc_hr
chmod 700 /tmp/oracle_source_intel
chmod 700 /tmp/oracle_source_intel/poc_hr
```

If you need a different base path, update one line in `oracle2mysql_assement.sql`:
```sql
define ALLOWED_REPORT_BASE='/your/approved/base/path'
```

## Baseline Reproducibility Run (Locked v1)
```sql
@run_source_intelligence_single_script_v1_locked.sql YOUR_SCHEMA /tmp/oracle_source_intel 19c 8 350 40
```

## v2 Enterprise Reports Generated
- `source_intelligence.html`
- `discovery_summary.html`
- `discovery_objects.html`
- `dependency_graph.html`
- `schema_complexity.html`
- `aws_sct_readiness.html`
- `enterprise_prereq_gate.html`
- `sct_decision_matrix.html`
- `datatype_refactor_backlog.html`

## What v2 Covers
- Source inventory and dependency discovery
- Complexity scoring for POC schema selection
- Pre-SCT prerequisite gate and go/no-go signals
- SCT usage path recommendation (`assessment first` vs `conversion POC`)
- Datatype mapping hotspots and refactor backlog candidates

## What v2 Does Not Cover
- Actual schema conversion execution
- Data migration execution (DMS full load/CDC)
- Application SQL rewrite automation
- Runtime performance tuning on Aurora MySQL

These reports are for pre-migration planning and remediation prioritization.

## Sample Reports (No Oracle Needed)
Sample HTML output bundle is available at:

- `<repo_root>/oracle_mysql_migration_planning/sql_readonly/samples/v2_enterprise_poc/source_intelligence.html`

From that page, open linked sample pages for all report types:
- discovery summary
- object details
- dependency graph
- schema complexity
- SCT readiness
- enterprise prerequisite gate
- SCT decision matrix
- datatype refactor backlog

These are illustrative mock outputs for layout/review only, not live database results.

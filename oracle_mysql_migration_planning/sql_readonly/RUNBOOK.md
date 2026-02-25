# SQL Developer Runbook (v2 Enterprise)

This runbook is for executing the read-only Oracle source intelligence workflow and generating enterprise-grade HTML reports.

## Inputs You Must Provide
- `SCHEMA_FILTER` (example: `HR`, `APP_%`)
- `REPORT_DIR` (must be `/tmp/oracle_source_intel` or child path)
- `SOURCE_DB_VERSION` (example: `19c`)
- `SOURCE_VCPUS` (example: `8`)
- `SOURCE_SGA_GB` (example: `350`)
- `SOURCE_PGA_LIMIT_GB` (example: `40`)

## Step-by-Step Execution
1. Create output path:
```bash
mkdir -p /tmp/oracle_source_intel/poc_hr
chmod 700 /tmp/oracle_source_intel
chmod 700 /tmp/oracle_source_intel/poc_hr
```

2. Open SQL Developer worksheet connected to source Oracle.

3. Run:
```sql
@run_source_intelligence_single_script_v2_enterprise.sql HR /tmp/oracle_source_intel/poc_hr 19c 8 350 40
```

4. Validate run completion in SQL output:
- Confirm all report file paths are printed at the end.
- Confirm there is no `ORA-20012` (path-allowlist violation).

5. Open the main report:
- `/tmp/oracle_source_intel/poc_hr/source_intelligence.html`

6. Open decision reports:
- `/tmp/oracle_source_intel/poc_hr/enterprise_prereq_gate.html`
- `/tmp/oracle_source_intel/poc_hr/sct_decision_matrix.html`
- `/tmp/oracle_source_intel/poc_hr/datatype_refactor_backlog.html`

## Interpretation Guide
- `enterprise_prereq_gate.html`:
  - `BLOCKED`: fix visibility/critical prerequisites first
  - `CONDITIONAL`: proceed only with remediation backlog
  - `READY_FOR_SCT_POC`: proceed to SCT conversion POC
- `sct_decision_matrix.html`:
  - risk-scored guidance for assessment-first vs conversion-first
- `datatype_refactor_backlog.html`:
  - column-level mapping hot spots and manual refactor candidates

## Troubleshooting
- Error: `REPORT_DIR not allowed`:
  - use `/tmp/oracle_source_intel` or a child path
  - or update `ALLOWED_REPORT_BASE` in script intentionally
- Empty report sections:
  - verify schema filter and metadata privileges
- Missing pages:
  - confirm target directory exists and is writable

## Locked Baseline (v1)
For reproducible baseline output:
```sql
@run_source_intelligence_single_script_v1_locked.sql HR /tmp/oracle_source_intel/poc_hr 19c 8 350 40
```

Do not edit v1; create new version files for enhancements.


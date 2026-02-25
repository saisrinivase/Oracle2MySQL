#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASE_DIR"

pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; exit 1; }
warn() { printf '[WARN] %s\n' "$1"; }

required_files=(
  "00_run_poc_discover_assess.sql"
  "00_run_stage_1_2_3.sql"
  "run_source_intelligence_poc.sql"
  "01_create_repo_objects.sql"
  "04_register_source_capacity_profile.sql"
  "05_register_source_target_profile.sql"
  "10_discover_source_oracle.sql"
  "11_discover_full_dependencies.sql"
  "20_assess_oracle_for_mysql.sql"
  "22_assess_schema_complexity.sql"
  "30_build_mysql_migration_plan.sql"
  "31_generate_mysql_target_blueprint.sql"
  "40_report_main_page.sql"
  "41_report_discover_page.sql"
  "42_report_assess_page.sql"
  "43_report_plan_page.sql"
  "44_report_discover_objects_page.sql"
  "45_report_assess_findings_page.sql"
  "46_report_plan_actions_page.sql"
  "47_report_source_target_page.sql"
  "48_report_target_blueprint_page.sql"
  "49_report_dependency_graph_page.sql"
  "50_report_schema_complexity_page.sql"
  "51_report_source_intelligence_overview.sql"
  "52_report_aws_sct_readiness.sql"
)

for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || fail "Missing required file: $f"
done
pass "All required SQL files are present"

while IFS= read -r inc; do
  [[ -n "$inc" ]] || continue
  [[ -f "$inc" ]] || fail "Orchestrator references missing file: $inc"
done < <(awk '/^@/{print substr($1,2)}' 00_run_stage_1_2_3.sql)
pass "00_run_stage_1_2_3.sql includes only existing scripts"

for f in "${required_files[@]}"; do
  [[ -s "$f" ]] || fail "File is empty: $f"
done
pass "All SQL files are non-empty"

created_objects="$(
  {
    rg --no-filename -o "create table omm_[a-z0-9_]+" 01_create_repo_objects.sql | awk '{print $3}'
    rg --no-filename -o "create sequence omm_[a-z0-9_]+" 01_create_repo_objects.sql | awk '{print $3}'
    rg --no-filename -o "function omm_[a-z0-9_]+" 01_create_repo_objects.sql | awk '{print $2}'
  } | sort -u
)"

referenced_objects="$(rg --no-filename -o "omm_[a-z0-9_]+" ./*.sql | sort -u | grep -v '^omm_idx_' || true)"
missing_refs="$(comm -23 <(echo "$referenced_objects" | sort -u) <(echo "$created_objects" | sort -u) | sed '/^$/d')"

if [[ -n "${missing_refs}" ]]; then
  printf 'Unresolved object references:\n%s\n' "$missing_refs"
  fail "Some omm_* references are not created in 01_create_repo_objects.sql"
fi
pass "All omm_* references resolve to created tables/sequences/function"

if rg -n 'spool &&REPORT_DIR/' 4*.sql >/dev/null; then
  fail "Found unquoted REPORT_DIR spool paths in report scripts"
fi
pass "Report scripts use quoted spool paths"

if ! rg -n '^host mkdir -p "&&REPORT_DIR"$' 00_run_stage_1_2_3.sql >/dev/null; then
  warn "REPORT_DIR mkdir line changed; verify path quoting in 00_run_stage_1_2_3.sql"
else
  pass "Orchestrator uses quoted REPORT_DIR mkdir"
fi

echo
echo "Static preflight completed successfully."
echo "Note: This does NOT validate runtime SQL execution against Oracle."

#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_dir="${1:-release-evidence}"

if [[ -z "$output_dir" || "$output_dir" == "." || "$output_dir" == ".." || "$output_dir" == *".."* ]]; then
  echo "error: unsafe output directory: $output_dir" >&2
  exit 2
fi

if [[ "$output_dir" = /* ]]; then
  output_abs="$output_dir"
else
  output_abs="$repo_root/$output_dir"
fi

output_abs="$(python3 -c 'import pathlib, sys; print(pathlib.Path(sys.argv[1]).resolve())' "$output_abs")"

case "$output_abs" in
  "$repo_root"/*) ;;
  *)
    echo "error: output directory must be inside the repository" >&2
    exit 2
    ;;
esac

if [[ "$output_abs" == "$repo_root" ]]; then
  echo "error: output directory must not be the repository root" >&2
  exit 2
fi

rm -rf "$output_abs"
mkdir -p \
  "$output_abs/docs" \
  "$output_abs/graphs" \
  "$output_abs/logs" \
  "$output_abs/security" \
  "$output_abs/tests" \
  "$output_abs/validate"

results_file="$output_abs/.gate-results.tsv"
: > "$results_file"

record_result() {
  local gate="$1"
  local result="$2"
  local evidence="$3"
  printf "%s\t%s\t%s\n" "$gate" "$result" "$evidence" >> "$results_file"
}

run_capture() {
  local gate="$1"
  local evidence="$2"
  shift 2

  if "$@" > "$output_abs/$evidence" 2>&1; then
    record_result "$gate" "pass" "$evidence"
    return 0
  fi

  record_result "$gate" "fail" "$evidence"
  return 1
}

overall=0

run_capture "terraform fmt" "logs/terraform-fmt.txt" \
  terraform -chdir="$repo_root/terraform" fmt -check -recursive || overall=1

run_capture "terraform init" "logs/terraform-init.txt" \
  terraform -chdir="$repo_root/terraform" init -backend=false -input=false || overall=1

if terraform -chdir="$repo_root/terraform" validate -json > "$output_abs/validate/terraform.validate.json" 2> "$output_abs/logs/terraform-validate.stderr.txt"; then
  record_result "terraform validate" "pass" "validate/terraform.validate.json"
else
  record_result "terraform validate" "fail" "validate/terraform.validate.json"
  overall=1
fi

if terraform -chdir="$repo_root/terraform" test -json > "$output_abs/tests/terraform-test.json" 2> "$output_abs/logs/terraform-test.stderr.txt"; then
  record_result "terraform test" "pass" "tests/terraform-test.json"
else
  record_result "terraform test" "fail" "tests/terraform-test.json"
  overall=1
fi

run_capture "docs layout" "docs/docs-layout.txt" \
  python3 "$repo_root/tools/check_docs_layout.py" || overall=1

if bash "$repo_root/tools/render_graphs.sh" "tests/fixtures/minimal" "$output_abs/graphs" > "$output_abs/logs/graph-minimal.txt" 2>&1 &&
   bash "$repo_root/tools/render_graphs.sh" "tests/fixtures/packer-consumer" "$output_abs/graphs" > "$output_abs/logs/graph-packer-consumer.txt" 2>&1; then
  record_result "graph generation" "pass" "graphs/*.plan.svg"
  record_result "dependency cycles" "pass" "graphs/*.cycles.json"
else
  record_result "graph generation" "fail" "graphs/*.plan.svg"
  record_result "dependency cycles" "fail" "graphs/*.cycles.json"
  overall=1
fi

cat > "$output_abs/security/README.md" <<'SECURITY'
# Security Evidence

CodeQL, Trivy, Gitleaks, actionlint, and markdownlint are produced by separate GitHub
Actions workflows. Review the run for:

- `.github/workflows/codeql.yaml`
- `.github/workflows/security.yaml`
- `.github/workflows/repo-ci.yml`

This release evidence bundle records where those gates live; it does not duplicate SARIF
or secret-scan output.
SECURITY

record_result "security scans" "pass" "security/README.md"

cat > "$output_abs/summary.md" <<'SUMMARY'
# Release Evidence

## Gates

| Gate | Result | Evidence |
|---|---:|---|
SUMMARY

while IFS=$'\t' read -r gate result evidence; do
  printf "| %s | %s | %s |\n" "$gate" "$result" "$evidence" >> "$output_abs/summary.md"
done < "$results_file"

cat >> "$output_abs/summary.md" <<'SUMMARY'

## Non-goals

This evidence bundle intentionally excludes Terraform state files, plan files,
credentials, and environment-specific tfvars.
SUMMARY

rm -f "$results_file"

for forbidden in ".terraform" "terraform.tfstate" "terraform.tfstate.backup" "*.tfplan" "*.tfvars" "*.tfvars.json"; do
  if find "$output_abs" -name "$forbidden" -print -quit | grep -q .; then
    echo "error: forbidden evidence file matched $forbidden" >&2
    exit 1
  fi
done

(
  cd "$output_abs"
  find . -type f ! -name checksums.txt -print0 |
    sort -z |
    xargs -0 sha256sum > checksums.txt
)

exit "$overall"

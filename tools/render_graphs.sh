#!/usr/bin/env bash
set -euo pipefail

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: required command '$1' not found" >&2
    exit 2
  fi
}

usage() {
  echo "usage: tools/render_graphs.sh [fixture] [output_dir]" >&2
}

require_command terraform
require_command dot
require_command python3

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ "$#" -eq 0 ]; then
  fixtures=("tests/fixtures/minimal" "tests/fixtures/packer-consumer")
  output_dir="$repo_root/artifacts/graphs"
elif [ "$#" -eq 1 ]; then
  fixtures=("$1")
  output_dir="$repo_root/artifacts/graphs"
elif [ "$#" -eq 2 ]; then
  fixtures=("$1")
  output_dir="$2"
else
  usage
  exit 2
fi

if [[ "$output_dir" != /* ]]; then
  output_dir="$repo_root/$output_dir"
fi
mkdir -p "$output_dir"
output_abs="$(cd "$output_dir" && pwd)"

for fixture in "${fixtures[@]}"; do
  if [[ "$fixture" = /* ]]; then
    fixture_abs="$(cd "$fixture" && pwd)"
  else
    fixture_abs="$(cd "$repo_root/$fixture" && pwd)"
  fi
  name="$(basename "$fixture")"
  tf_data_dir="$repo_root/artifacts/.terraform-data/$name"
  lock_file="$fixture_abs/.terraform.lock.hcl"
  had_lock=0

  if [ -f "$lock_file" ]; then
    had_lock=1
  fi

  mkdir -p "$tf_data_dir"

  echo "Rendering Terraform graph for $fixture"
  TF_DATA_DIR="$tf_data_dir" terraform -chdir="$fixture_abs" init -backend=false -input=false
  TF_DATA_DIR="$tf_data_dir" terraform -chdir="$fixture_abs" validate -json > "$output_abs/$name.validate.json"
  TF_DATA_DIR="$tf_data_dir" terraform -chdir="$fixture_abs" graph -type=plan -draw-cycles > "$output_abs/$name.plan.dot"

  dot -Tsvg "$output_abs/$name.plan.dot" -o "$output_abs/$name.plan.svg"
  python3 "$repo_root/tools/tf_graph_cycles.py" "$output_abs/$name.plan.dot" > "$output_abs/$name.cycles.json"
  python3 "$repo_root/tools/tf_graph_summary.py" "$output_abs/$name.plan.dot" "$fixture" > "$output_abs/$name.summary.json"

  if [ "$had_lock" -eq 0 ]; then
    rm -f "$lock_file"
  fi
done

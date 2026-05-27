#!/usr/bin/env bash
set -euo pipefail

die() {
  echo "::error::$*" >&2
  exit 1
}

tfvars_file="${1:-}"
consumer_prefix="${2:-../../consumer}"

if [[ -z "${tfvars_file}" ]]; then
  exit 0
fi

if [[ "${tfvars_file}" == *$'\n'* || "${tfvars_file}" == *$'\r'* ]]; then
  die "tfvars_file must be a single relative path"
fi
if [[ "${tfvars_file}" == /* ]]; then
  die "tfvars_file must be relative to the consumer checkout: ${tfvars_file}"
fi
if [[ "${tfvars_file}" == "." || "${tfvars_file}" == ".." || "${tfvars_file}" == ../* || "${tfvars_file}" == */../* || "${tfvars_file}" == */.. ]]; then
  die "tfvars_file must not contain path traversal: ${tfvars_file}"
fi

printf '%s\n' "-var-file=${consumer_prefix%/}/${tfvars_file}"

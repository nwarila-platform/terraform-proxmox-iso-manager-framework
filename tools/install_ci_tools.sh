#!/usr/bin/env bash
# Install the pinned Linux CI tools used by `make ci`.

set -euo pipefail

require_var() {
  local name="$1"
  if [ -z "${!name:-}" ]; then
    echo "error: required env var ${name} is not set" >&2
    exit 2
  fi
}

verify_sha256() {
  local file="$1"
  local expected="$2"
  local actual
  actual="$(sha256sum "$file" | awk '{print $1}')"
  if [ "$actual" != "$expected" ]; then
    echo "error: sha256 mismatch for $file" >&2
    echo "  expected: $expected" >&2
    echo "  actual:   $actual" >&2
    exit 1
  fi
}

install_tflint() {
  local zip="tflint_linux_amd64.zip"
  local base="https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}"
  curl --fail --silent --show-error --location -o "${workdir}/${zip}" "${base}/${zip}"
  curl --fail --silent --show-error --location -o "${workdir}/tflint_checksums.txt" "${base}/checksums.txt"

  local expected
  expected="$(awk -v f="${zip}" '$2 == f {print $1}' "${workdir}/tflint_checksums.txt")"
  if [ -z "$expected" ]; then
    echo "error: ${zip} not found in tflint checksums.txt" >&2
    exit 1
  fi

  verify_sha256 "${workdir}/${zip}" "$expected"
  unzip -q -o "${workdir}/${zip}" -d "${workdir}/tflint"
  install -m 0755 "${workdir}/tflint/tflint" "${bindir}/tflint"
  "${bindir}/tflint" --version
}

install_terraform_docs() {
  local tarball="terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz"
  local base="https://github.com/terraform-docs/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}"
  curl --fail --silent --show-error --location -o "${workdir}/${tarball}" "${base}/${tarball}"
  curl --fail --silent --show-error --location -o "${workdir}/terraform-docs.sha256sum" "${base}/terraform-docs-v${TERRAFORM_DOCS_VERSION}.sha256sum"

  local expected
  expected="$(awk -v f="${tarball}" '$2 == f {print $1}' "${workdir}/terraform-docs.sha256sum")"
  if [ -z "$expected" ]; then
    echo "error: ${tarball} not found in terraform-docs sha256sum file" >&2
    exit 1
  fi

  verify_sha256 "${workdir}/${tarball}" "$expected"
  tar -xzf "${workdir}/${tarball}" -C "${workdir}"
  install -m 0755 "${workdir}/terraform-docs" "${bindir}/terraform-docs"
  "${bindir}/terraform-docs" version
}

install_opa() {
  local bin="opa_linux_amd64_static"
  local base="https://github.com/open-policy-agent/opa/releases/download/v${OPA_VERSION}"
  curl --fail --silent --show-error --location -o "${workdir}/${bin}" "${base}/${bin}"
  curl --fail --silent --show-error --location -o "${workdir}/${bin}.sha256" "${base}/${bin}.sha256"

  local expected
  expected="$(awk '{print $1}' "${workdir}/${bin}.sha256")"
  if [ -z "$expected" ]; then
    echo "error: OPA sha256 file is empty" >&2
    exit 1
  fi

  verify_sha256 "${workdir}/${bin}" "$expected"
  install -m 0755 "${workdir}/${bin}" "${bindir}/opa"
  "${bindir}/opa" version
}

require_var TFLINT_VERSION
require_var TERRAFORM_DOCS_VERSION
require_var OPA_VERSION

bindir="${HOME}/.local/bin"
mkdir -p "$bindir"
if [ -n "${GITHUB_PATH:-}" ]; then
  echo "$bindir" >> "$GITHUB_PATH"
else
  export PATH="${bindir}:$PATH"
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

install_tflint
install_terraform_docs
install_opa

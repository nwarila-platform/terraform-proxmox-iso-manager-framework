#!/usr/bin/env bash
# Install pinned CI tools (tflint, terraform-docs, opa) on a Linux x86_64 runner.
#
# Versions are passed via env vars so Renovate can update them in one place
# (.github/workflows/pr-validation.yaml). Each binary's tarball/zip is verified
# against the upstream-published SHA-256 checksum file from the same release.
#
# This is a release-page-of-record verification, not a third-party attestation:
# it catches mirror/transport tampering, not a compromised upstream release.
# Stronger supply-chain controls would require a separate attestation source.

set -euo pipefail

require_var() {
  local name="$1"
  local value="${!name:-}"
  if [ -z "$value" ]; then
    echo "error: required env var $name is not set" >&2
    exit 2
  fi
}

require_var TFLINT_VERSION
require_var TERRAFORM_DOCS_VERSION
require_var OPA_VERSION

bindir="${HOME}/.local/bin"
mkdir -p "$bindir"
echo "$bindir" >> "${GITHUB_PATH:-/dev/stderr}"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

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
  local v="$TFLINT_VERSION"
  local zip="tflint_linux_amd64.zip"
  local base="https://github.com/terraform-linters/tflint/releases/download/v${v}"
  curl --fail --silent --show-error --location -o "${workdir}/${zip}" "${base}/${zip}"
  curl --fail --silent --show-error --location -o "${workdir}/checksums.txt" "${base}/checksums.txt"
  local expected
  expected="$(awk -v f="${zip}" '$2 == f {print $1}' "${workdir}/checksums.txt")"
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
  local v="$TERRAFORM_DOCS_VERSION"
  local tar="terraform-docs-v${v}-linux-amd64.tar.gz"
  local base="https://github.com/terraform-docs/terraform-docs/releases/download/v${v}"
  curl --fail --silent --show-error --location -o "${workdir}/${tar}" "${base}/${tar}"
  curl --fail --silent --show-error --location -o "${workdir}/terraform-docs.sha256sum" "${base}/terraform-docs-v${v}.sha256sum"
  local expected
  expected="$(awk -v f="${tar}" '$2 == f {print $1}' "${workdir}/terraform-docs.sha256sum")"
  if [ -z "$expected" ]; then
    echo "error: ${tar} not found in terraform-docs sha256sum file" >&2
    exit 1
  fi
  verify_sha256 "${workdir}/${tar}" "$expected"
  tar -xzf "${workdir}/${tar}" -C "${workdir}"
  install -m 0755 "${workdir}/terraform-docs" "${bindir}/terraform-docs"
  "${bindir}/terraform-docs" version
}

install_opa() {
  local v="$OPA_VERSION"
  local bin="opa_linux_amd64_static"
  local base="https://github.com/open-policy-agent/opa/releases/download/v${v}"
  curl --fail --silent --show-error --location -o "${workdir}/${bin}" "${base}/${bin}"
  curl --fail --silent --show-error --location -o "${workdir}/${bin}.sha256" "${base}/${bin}.sha256"
  local expected
  expected="$(awk '{print $1}' "${workdir}/${bin}.sha256")"
  if [ -z "$expected" ]; then
    echo "error: opa sha256 file is empty" >&2
    exit 1
  fi
  verify_sha256 "${workdir}/${bin}" "$expected"
  install -m 0755 "${workdir}/${bin}" "${bindir}/opa"
  "${bindir}/opa" version
}

install_tflint
install_terraform_docs
install_opa

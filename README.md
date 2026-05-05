# terraform-proxmox-iso-manager-framework

[![Repo CI](https://img.shields.io/github/actions/workflow/status/nwarila-platform/terraform-proxmox-iso-manager-framework/repo-ci.yml?branch=main&label=Repo%20CI)](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/actions/workflows/repo-ci.yml)
[![Terraform Tests](https://img.shields.io/github/actions/workflow/status/nwarila-platform/terraform-proxmox-iso-manager-framework/pr-validation.yaml?branch=main&label=Terraform%20Tests)](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/actions/workflows/pr-validation.yaml)
[![Security Scan](https://img.shields.io/github/actions/workflow/status/nwarila-platform/terraform-proxmox-iso-manager-framework/security.yaml?branch=main&label=Security)](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/actions/workflows/security.yaml)
[![CodeQL](https://img.shields.io/github/actions/workflow/status/nwarila-platform/terraform-proxmox-iso-manager-framework/codeql.yaml?branch=main&label=CodeQL)](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/actions/workflows/codeql.yaml)
[![Latest Release](https://img.shields.io/github/v/release/nwarila-platform/terraform-proxmox-iso-manager-framework?label=Release)](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/releases)
[![Renovate](https://img.shields.io/badge/Renovate-enabled-1A1F6C?logo=renovatebot&logoColor=white)](https://docs.renovatebot.com/)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-FE5196?logo=conventionalcommits&logoColor=white)](https://conventionalcommits.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Terraform child module for one job: make the exact installer ISO a Packer template
build needs available on Proxmox VE storage.

The module turns a Git-tracked ISO pin (`url`, `sha256`, `filename`) into a verified
Proxmox ISO path such as `cephFS:iso/Rocky-9.6-x86_64-dvd.iso`. Per-OS Packer
template repositories import this module so ISO selection is reviewed in Git, applied
through Terraform, and consumed by Packer without manual Proxmox console work.

## What This Demonstrates

This repository treats a small Terraform child module like a production platform
component:

- exact Terraform/provider pinning
- mock-based Terraform tests
- SHA-verified ISO lifecycle
- explicit threat model
- runnable consumer examples validated in CI
- release automation
- security scanning and secret scanning
- ADR-backed design decisions

## What It Does

- Downloads exactly one installer ISO to a target Proxmox VE datastore.
- Verifies the downloaded file with the pinned SHA-256 digest.
- Returns the Proxmox `iso_file` path expected by Packer's `proxmox-iso` builder.
- Fails closed when a same-named unmanaged ISO already exists, unless explicit adoption
  is requested with `overwrite_unmanaged = true`.
- Centralizes ISO lifecycle behavior for Packer template repos such as
  [`secure-rockylinux9-template`](https://github.com/nwarila-platform/secure-rockylinux9-template)
  and future OS template builds.

## Operational Flow

```text
consumer template repo
  iso_pin = { url, sha256, filename }
        |
        v
terraform apply
        |
        v
this module
  - validates the pin
  - downloads through the Proxmox API
  - verifies SHA-256
        |
        v
Proxmox VE storage
  <storage>:iso/<filename>
        |
        v
module.iso.iso_path
  passed to Packer as iso_file
```

The consumer repo remains the long-lived audit trail. Proxmox stores the short-lived
build input; Git stores the reviewed pin that says which ISO should exist.

## Usage

```hcl
terraform {
  required_version = "= 1.15.1"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "= 0.105.0"
    }
  }
}

provider "proxmox" {
  endpoint = "https://proxmox.example.test:8006/"
  # Configure credentials per the bpg/proxmox provider documentation.
}

module "iso" {
  source = "git::https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework.git//terraform?ref=v1.0.1"

  family = "rocky9"
  iso_pin = {
    url      = "https://dl.rockylinux.org/pub/rocky/9.6/isos/x86_64/Rocky-9.6-x86_64-dvd.iso"
    sha256   = "8ff2a47e2f3bfe442617fceb7ef289b7b1d2d0502089dbbd505d5368b2b3a90f"
    filename = "Rocky-9.6-x86_64-dvd.iso"
  }
  node    = "tcnhq-prxmx01"
  storage = "cephFS"
}

output "iso_file" {
  value = module.iso.iso_path
}
```

After the first `terraform apply`, the ISO is present on Proxmox at
`cephFS:iso/Rocky-9.6-x86_64-dvd.iso` and SHA-256 verified. Subsequent applies with the
same pin are no-ops for Terraform-managed files. Bumping any field of `iso_pin` triggers
a fresh download on the next apply.

## Consumer Contract

- Import the module from the `//terraform` subdirectory.
- Pin the module to a release tag, not a branch.
- Run Terraform `= 1.15.1` and `bpg/proxmox = 0.105.0` exactly.
- Use non-tokenized ISO URLs. Query strings and fragments are rejected so signed URLs do
  not leak through outputs, plans, or state.
- Keep the ISO pin in the consumer repo so ISO changes are reviewed like code.
- Leave `overwrite_unmanaged = false` during normal operation.

## Examples

- [Minimal module call](examples/minimal/)
- [Packer consumer fixture](examples/packer-consumer/)
- [Adoption and recovery fixture](examples/adoption-recovery/)
- [Failure case notes](examples/failure-cases/)

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `family` | `string` | required | Template family discriminator (e.g. `rocky9`). Provenance-only: echoed back through the `family` output but not consumed by any resource. Must match `[a-z0-9._-]+`. |
| `iso_pin` | `object({ url, sha256, filename })` | required | Pin specifying exactly which ISO to manage. `url` must be a non-tokenized HTTPS URL with host and path, and no whitespace, query string, or fragment; `sha256` must be a 64-character lowercase hex digest; `filename` must end in `.iso`. |
| `node` | `string` | required | Proxmox node name on which the download is performed. Must match `[A-Za-z0-9._-]+`. |
| `storage` | `string` | required | Proxmox storage datastore (e.g. `cephFS`, `local`). Must have ISO content type enabled and match `[A-Za-z0-9._-]+`. |
| `upload_timeout` | `number` | `3600` | Timeout in seconds for the Proxmox download-url operation. Must be between 60 and 86400. |
| `overwrite` | `bool` | `false` | Allow provider-managed replacement when the managed file size changes. Leave false for pinned ISO inputs. |
| `overwrite_unmanaged` | `bool` | `false` | Delete and replace a same-named unmanaged file during deliberate adoption or recovery. |

## Outputs

| Name | Type | Description |
|---|---|---|
| `iso_id` | `string` | Proxmox file ID `<datastore>:<volume_id>`. Canonical identifier the provider uses. |
| `iso_path` | `string` | `<storage>:iso/<filename>`. Pass directly into Packer's `iso_file`. |
| `iso_sha256` | `string` | Echoed back from input. Useful for provenance recording. |
| `iso_url` | `string` | Non-tokenized upstream URL. Useful for provenance recording. |
| `iso_filename` | `string` | On-disk filename. |
| `family` | `string` | Echoed back for downstream labels and provenance. |
| `node` | `string` | Where the download was performed. |
| `storage` | `string` | Datastore the ISO landed on. |

## Documentation

- [Use from a Packer template repo](docs/how-to/use-from-a-packer-template.md)
- [Develop this module](docs/how-to/develop-this-module.md)
- [Architecture](docs/architecture.md)
- [Testing strategy](docs/testing-strategy.md)
- [Release gates](docs/release-gates.md)
- [Terraform reference](docs/reference/terraform.md)
- [Threat model](docs/explanation/threat-model.md)
- [Decision records](docs/decision-records/README.md)

Repository community-health files such as `CONTRIBUTING.md`, `SECURITY.md`, issue
templates, and the pull request template are inherited from the
[`nwarila-platform/.github`](https://github.com/nwarila-platform/.github) repository.

## Engineering Quality

This repo is intentionally small, but it is treated like production infrastructure:

- Exact Terraform and provider pins, documented by org ADR-0005.
- Validation tests for accepted and rejected input contracts.
- CI gates for Terraform format/validate/test, example validation, workflow linting,
  markdown linting, CodeQL, Trivy, and Gitleaks.
- Release Please automation for SemVer tags and GitHub releases.
- Renovate-managed dependency update flow for Terraform, GitHub Actions, Docker action
  images, and the CI Terraform version input.

Terraform modules do not produce a meaningful line-coverage percentage. The test signal
for this repo is the `Terraform Tests` badge, backed by `terraform test`; the security
signal is split across Security Scan (Trivy + Gitleaks) and CodeQL.

## Provider Requirements

| Provider | Version | Why |
|---|---|---|
| `terraform` | `= 1.15.1` | Validation blocks plus ergonomic `regex`/`can`. Exact-pinned per [org ADR-0005](docs/decision-records/org/0005-pin-terraform-and-provider-versions-exactly.md); consumers must run Terraform 1.15.1 exactly. |
| `bpg/proxmox` | `= 0.105.0` | `proxmox_download_file` resource with checksum and checksum_algorithm. Exact-pinned per the same ADR. |

Both Terraform and the provider are pinned exactly with the `=` operator. This is
intentional: every consumer runs the exact version the module was tested against.
`terraform init` fails fast on any other version. Use `tfenv` or `asdf` to manage
per-project Terraform versions if needed.

## Security

See the repository's [Security Policy](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/security/policy)
for vulnerability disclosure and reporting instructions. The policy is inherited from
the organization's special `.github` repository.

The integrity of the upstream ISO source is not in this module's threat model. The
consumer is responsible for sourcing trustworthy SHA-256 values from upstream
distribution channels.

## License

[MIT](LICENSE).

# terraform-proxmox-iso-manager-framework

[![Repo CI](https://img.shields.io/github/actions/workflow/status/nwarila-platform/terraform-proxmox-iso-manager-framework/repo-ci.yml?branch=main&label=Repo%20CI)](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/actions/workflows/repo-ci.yml)
[![Terraform Tests](https://img.shields.io/github/actions/workflow/status/nwarila-platform/terraform-proxmox-iso-manager-framework/pr-validation.yaml?branch=main&label=Terraform%20Tests)](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/actions/workflows/pr-validation.yaml)
[![Security Scan](https://img.shields.io/github/actions/workflow/status/nwarila-platform/terraform-proxmox-iso-manager-framework/security.yaml?branch=main&label=Security)](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/actions/workflows/security.yaml)
[![CodeQL](https://img.shields.io/github/actions/workflow/status/nwarila-platform/terraform-proxmox-iso-manager-framework/codeql.yaml?branch=main&label=CodeQL)](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/actions/workflows/codeql.yaml)
[![Latest Release](https://img.shields.io/github/v/release/nwarila-platform/terraform-proxmox-iso-manager-framework?label=Release)](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/releases)
[![Renovate](https://img.shields.io/badge/Renovate-enabled-1A1F6C?logo=renovatebot&logoColor=white)](https://docs.renovatebot.com/)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-FE5196?logo=conventionalcommits&logoColor=white)](https://conventionalcommits.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Terraform child module for one job: manage one Proxmox VE installer ISO from a
Git-tracked pin containing `url`, `sha256`, and `filename`.

The module turns that pin into a SHA-verified Proxmox ISO path such as
`cephFS:iso/Rocky-9.6-x86_64-dvd.iso`, which Packer template repositories can consume as
`iso_file`.

## What this demonstrates

This repository treats a small Terraform child module like a production platform
component:

- exact Terraform and provider pinning
- SHA-verified ISO lifecycle management
- fail-closed unmanaged-file behavior
- mock-based Terraform tests
- explicit threat model
- Diataxis documentation structure
- ADR-backed design decisions
- dependency graph generation
- dependency cycle detection
- CI security scanning
- release evidence artifacts

## Evidence

| Evidence | Location |
|---|---|
| Architecture | [docs/explanation/architecture.md](docs/explanation/architecture.md) |
| Threat model | [docs/explanation/threat-model.md](docs/explanation/threat-model.md) |
| Terraform reference | [docs/reference/terraform.md](docs/reference/terraform.md) |
| Testing strategy | [docs/explanation/testing-strategy.md](docs/explanation/testing-strategy.md) |
| Release gates | [docs/reference/release-gates.md](docs/reference/release-gates.md) |
| Dependency graph validation | [docs/explanation/dependency-graph-validation.md](docs/explanation/dependency-graph-validation.md) |
| Graph artifacts | [docs/reference/graph-artifacts.md](docs/reference/graph-artifacts.md) |
| Runnable examples | [examples/](examples/) |
| CI workflows | [.github/workflows/](.github/workflows/) |

## Usage

```hcl
provider "proxmox" {
  endpoint = "https://proxmox.example.test:8006/"
  # Configure credentials in the root consumer, not in this child module.
}

module "iso" {
  source = "git::https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework.git//terraform?ref=<release-tag>"

  family = "rocky9"

  iso_pin = {
    url      = "https://dl.rockylinux.org/pub/rocky/9.6/isos/x86_64/Rocky-9.6-x86_64-dvd.iso"
    sha256   = "8ff2a47e2f3bfe442617fceb7ef289b7b1d2d0502089dbbd505d5368b2b3a90f"
    filename = "Rocky-9.6-x86_64-dvd.iso"
  }

  node    = "pve-node-01"
  storage = "cephFS"
}

output "iso_file" {
  value = module.iso.iso_path
}

output "iso_checksum" {
  value = "sha256:${module.iso.iso_sha256}"
}
```

Consumers must pin the module to a release tag and import the `//terraform` subdirectory.
The exact Terraform and provider pins live in [`terraform/versions.tf`](terraform/versions.tf).
The module rejects tokenized, malformed, or credential-bearing ISO URLs because Terraform
state and outputs are not safe places for bearer tokens.

## Examples

- [Minimal module call](examples/minimal/) - complete copyable Terraform root
- [Packer consumer handoff](examples/packer-consumer/) - overlay for Packer-facing outputs
- [Adoption and recovery path](examples/adoption-recovery/) - dangerous single-argument overlay
- [Dependency-cycle failure case](examples/failure-cases/dependency-cycle/) - educational negative case

## Local verification

```bash
make ci
make graph
```

Generated release evidence is published by CI. The repo intentionally does not commit
Terraform state, plan files, credentials, provider caches, or environment-specific tfvars.

## Documentation

Start with [docs/README.md](docs/README.md) for the Diataxis index and
[docs/decision-records/README.md](docs/decision-records/README.md) for ADRs.

## Security

The integrity of the upstream ISO source is outside this module's threat model. Consumers
are responsible for sourcing trustworthy SHA-256 values from upstream distribution
channels. Vulnerability reporting is inherited from the organization's
[Security Policy](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/security/policy).

## License

[MIT](LICENSE).

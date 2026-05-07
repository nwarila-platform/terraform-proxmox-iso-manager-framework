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
- typed inputs with validation coverage
- mock-based Terraform tests with no live Proxmox dependency
- SHA-verified ISO lifecycle management
- fail-closed unmanaged-file behavior
- explicit threat model and module invariants
- Diataxis documentation structure
- ADR-backed design decisions
- Terraform graph generation and dependency-cycle detection
- OPA policy tests as part of `make ci`
- CI security scanning
- release evidence artifacts

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

  node    = "tcnhq-prxmx01"
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

| Example | Purpose |
| --- | --- |
| [`examples/minimal/`](examples/minimal/) | Smallest valid module call |
| [`examples/packer-consumer/`](examples/packer-consumer/) | Consumer-shaped output for Packer variables |
| [`examples/adoption-recovery/`](examples/adoption-recovery/) | Explicit unmanaged-file adoption path |
| [`examples/failure-cases/`](examples/failure-cases/) | Documented invalid configurations |

## Local Validation

Run the same core gates used by CI:

```bash
make ci
```

Run graph validation when Terraform dependency shape, graph tooling, fixtures, or release
evidence changes:

```bash
make graph
```

The CI target checks Terraform formatting, initialization, validation, tests, TFLint,
generated Terraform docs drift, documentation layout, and OPA policy tests.

## Quality Controls

| Control | Evidence |
| --- | --- |
| Terraform format, init, validate, test, TFLint, docs drift, docs layout, and OPA policy tests | `PR Validation` workflow running `make ci` |
| Markdown linting and workflow linting | `Repo CI` workflow |
| GitHub Actions static analysis | `CodeQL Analysis` workflow |
| Filesystem, IaC, and secret scanning | `Security Scan` workflow |
| Terraform graph generation and dependency-cycle detection | `Terraform Graph Regression` workflow and `make graph` |
| Release PRs, changelog, and tags | `Release Please` workflow |
| Release evidence artifact | `Release Evidence` workflow |
| Dependency update PRs | Renovate |

## Documentation

- [Use from a Packer template repo](docs/how-to/use-from-a-packer-template.md)
- [Develop this module](docs/how-to/develop-this-module.md)
- [Generate Terraform graphs](docs/how-to/generate-terraform-graphs.md)
- [Review release evidence](docs/how-to/review-release-evidence.md)
- [Adopt this template](docs/how-to/adopt-this-template.md)
- [Architecture](docs/explanation/architecture.md)
- [Testing strategy](docs/explanation/testing-strategy.md)
- [Dependency graph validation](docs/explanation/dependency-graph-validation.md)
- [Threat model](docs/explanation/threat-model.md)
- [Terraform reference](docs/reference/terraform.md)
- [Release gates](docs/reference/release-gates.md)
- [Graph artifacts](docs/reference/graph-artifacts.md)
- [Module invariants](docs/reference/invariants.md)
- [Golden template contract](docs/reference/golden-template-contract.md)
- [Decision records](docs/decision-records/README.md)

## Security

The integrity of the upstream ISO source is outside this module's threat model. Consumers
are responsible for sourcing trustworthy SHA-256 values from upstream distribution
channels. See [`SECURITY.md`](SECURITY.md) and
[`docs/explanation/threat-model.md`](docs/explanation/threat-model.md) for the boundary
and reporting flow.

Repository-specific contribution and security policy files live in this repository.
Organization-wide defaults may still be inherited from `nwarila-platform/.github` where
GitHub supports inherited community-health files.

## License

[MIT](LICENSE).

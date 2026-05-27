# Golden Terraform Template Contract

This contract defines the minimum standard for Terraform module repositories derived from this repository.

## Required root files

| Path | Purpose |
| --- | --- |
| `README.md` | Entry point, usage, quality controls, documentation links |
| `LICENSE` | Repository license |
| `CONTRIBUTING.md` | Local validation and contribution rules |
| `SECURITY.md` | Vulnerability scope and reporting |
| `Makefile` | Canonical local validation interface |
| `.editorconfig` | Basic editor consistency |
| `.gitignore` | Exclude local Terraform and runtime artifacts |
| `.gitattributes` | Repository text handling |
| `.terraform-docs.yml` | Generated Terraform reference configuration |
| `release-please-config.json` | Release automation configuration |
| `.release-please-manifest.json` | Release Please manifest |

## Required GitHub files

| Path | Purpose |
| --- | --- |
| `.github/CODEOWNERS` | Ownership for high-risk paths |
| `.github/PULL_REQUEST_TEMPLATE.md` | PR validation and risk evidence |
| `.github/renovate.json5` | Dependency update policy |
| `.github/workflows/pr-validation.yaml` | Terraform, docs, lint, and policy gates |
| `.github/workflows/repo-ci.yml` | Repository linting |
| `.github/workflows/security.yaml` | Filesystem, IaC, and secret scanning |
| `.github/workflows/codeql.yaml` | GitHub Actions static analysis |
| `.github/workflows/graph-regression.yml` | Terraform graph evidence |
| `.github/workflows/release-please.yaml` | Release PR and tag automation |
| `.github/workflows/release-evidence.yml` | Release evidence artifact generation |
| `.github/workflows/org-adr-sync.yaml` | Mirrored organization ADR check, when org ADRs are present |

## Required Terraform layout

| Path | Purpose |
| --- | --- |
| `terraform/versions.tf` | Terraform and provider pins |
| `terraform/variables.tf` | Typed inputs and validation |
| `terraform/locals.tf` | Normalized internal values |
| `terraform/resources.tf` | Managed resources |
| `terraform/outputs.tf` | Stable outputs |
| `terraform/tests/` | Terraform native tests |

## Required examples and fixtures

| Path | Purpose |
| --- | --- |
| `examples/minimal/` | Smallest valid module call |
| `examples/packer-consumer/` | Downstream consumer shape |
| `examples/adoption-recovery/` | Explicit adoption or recovery path |
| `examples/failure-cases/` | Documented invalid configurations |
| `tests/fixtures/` | Graph/test fixtures, when used by repository tooling |

## Required policy and tooling paths

| Path | Purpose |
| --- | --- |
| `tools/` | Repository validation and release-evidence helpers |
| `policies/opa/` | OPA policy checks, when policy checks are part of `make ci` |

## Required documentation

| Path | Purpose |
| --- | --- |
| `docs/README.md` | Documentation index |
| `docs/explanation/architecture.md` | Module boundary and flow |
| `docs/explanation/testing-strategy.md` | What tests do and do not cover |
| `docs/explanation/threat-model.md` | Security boundary |
| `docs/explanation/dependency-graph-validation.md` | Graph validation rationale |
| `docs/reference/terraform.md` | Generated Terraform reference with manual notes |
| `docs/reference/release-gates.md` | CI/CD and release gate map |
| `docs/reference/graph-artifacts.md` | Graph artifact reference |
| `docs/reference/invariants.md` | Non-negotiable module rules |
| `docs/reference/golden-template-contract.md` | Template standard |
| `docs/how-to/develop-this-module.md` | Local development workflow |
| `docs/how-to/use-from-a-packer-template.md` | Consumer usage workflow |
| `docs/how-to/generate-terraform-graphs.md` | Graph generation workflow |
| `docs/how-to/review-release-evidence.md` | Release evidence review workflow |
| `docs/how-to/adopt-this-template.md` | Template adoption checklist |
| `docs/decision-records/` | Architecture decision records |

## Required CI behavior

Pull requests must prove:

- Terraform formatting is canonical.
- The module initializes without a backend.
- The module validates.
- Terraform tests pass without a live Proxmox cluster.
- TFLint passes.
- Generated Terraform reference docs are current.
- Documentation layout checks pass.
- OPA policy tests pass when OPA policies are present.
- Markdown and workflow linting pass.
- Security and secret scans pass.
- Terraform graph evidence renders successfully when graph workflow runs.
- GitHub Actions workflows use least-privilege permissions.
- GitHub Actions are pinned to full commit SHAs.

## Release behavior

Releases must be produced by Release Please from Conventional Commits. Release evidence must not include Terraform state, plans, `.terraform/`, `tfvars`, provider caches, credentials, tokens, signed URLs, or private infrastructure values.

## Exceptions

Exceptions require one of:

- A repository-specific ADR.
- A documented issue linked from the pull request.
- A short rationale in the pull request explaining why the template rule does not apply.

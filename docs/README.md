# Documentation

This directory follows the [Diataxis](https://diataxis.fr) documentation framework per
[org ADR-0002](decision-records/org/0002-adopt-diataxis-documentation-framework.md).

## Quadrants

| Quadrant | Documents | When to read |
|---|---|---|
| Tutorials | None currently shipped | This single-purpose module does not currently need a learning path. |
| How-to | [Develop this module](how-to/develop-this-module.md), [Use from a Packer template](how-to/use-from-a-packer-template.md), [Generate Terraform graphs](how-to/generate-terraform-graphs.md), [Review release evidence](how-to/review-release-evidence.md), [Adopt this template](how-to/adopt-this-template.md) | You have a specific task to complete. |
| Reference | [Terraform reference](reference/terraform.md), [Release gates](reference/release-gates.md), [Graph artifacts](reference/graph-artifacts.md), [Module invariants](reference/invariants.md), [Golden template contract](reference/golden-template-contract.md), [Production readiness handoff](reference/production-readiness-handoff.md) | You need exact facts, schemas, gates, inputs, outputs, or current handoff state. |
| Explanation | [Architecture](explanation/architecture.md), [Threat model](explanation/threat-model.md), [Testing strategy](explanation/testing-strategy.md), [Dependency graph validation](explanation/dependency-graph-validation.md) | You want rationale, boundaries, or design context. |

Tutorials are not currently shipped. Consumers of a narrow Terraform child module
typically need reference and task-oriented guides more than a structured tutorial.

## Architecture Decision Records

ADRs live in [`decision-records/`](decision-records/), with organization-wide mirrors
under [`decision-records/org/`](decision-records/org/) and repository-specific decisions
under [`decision-records/repo/`](decision-records/repo/). ADRs are governed by
[org ADR-0001](decision-records/org/0001-use-architecture-decision-records.md) and are
not Diataxis quadrant documents.

## Local Development

Repository-specific contribution, security, pull-request-template, and ownership files
live in this repository. Organization-wide defaults may still be inherited from
`nwarila-platform/.github` where GitHub supports inherited community-health files.
Repository-specific contributor notes live in
[`how-to/develop-this-module.md`](how-to/develop-this-module.md).

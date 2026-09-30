# ADR-0004: Consume NWarila/terraform-framework-template as Golden Standard

| Field          | Value                                   |
| -------------- | --------------------------------------- |
| Status         | Accepted                                |
| Date           | 2026-05-27                              |
| Authors        | Nick Warila (@NWarila)                  |
| Decision-maker | Nick Warila (sole portfolio maintainer) |
| Consulted      | None.                                   |
| Informed       | None.                                   |
| Reversibility  | Medium                                  |
| Review-by      | N/A (Accepted)                          |

## TL;DR

This repository consumes `NWarila/terraform-framework-template` as the
canonical golden standard for Terraform module repositories under `nwarila`
and `nwarila-platform`. Namespace governance reusables are owned by and called
from `nwarila-platform/.github`; the framework template owns the type-specific
reusables (`reusable-release-evidence`, `reusable-terraform-deploy`). Workflow
callers reference each reusable from its owning repo by SHA. Baseline drift is
detected by the canonical `NWarila/drift-gate` action against the template's
published `baseline-manifest.json`. Local CI runs `make ci` natively without a
cross-repo round-trip.

## Context and Problem Statement

This repository is used by approximately a dozen Packer projects that depend
on it for ISO management. It is also a recruiter-facing artifact and the
proving ground for the rigor that should apply to every Terraform repository
under `nwarila` and `nwarila-platform`.

Without a single source of rigor, each Terraform repository drifts: CI gates
diverge, OPA rules vary, contract checks become wishful prose, and the
"golden standard" exists only by convention.

`NWarila/terraform-framework-template` is that single source for
Terraform-specific rigor. Following the namespace-local control-plane decision,
the six **namespace governance** reusables (`reusable-codeql.yaml`,
`reusable-iac-security.yaml`, `reusable-scorecard.yaml`,
`reusable-release-please.yaml`, `reusable-auto-merge.yaml`, and
`reusable-repo-hygiene.yaml`) are owned by and called from
`nwarila-platform/.github`; the framework template owns only the
**type-specific** reusables (`reusable-release-evidence.yaml`,
`reusable-terraform-deploy.yaml`) plus a `baseline-manifest.json` enumerating
files that consumers must mirror byte-for-byte.

This ADR settles whether this repository consumes that template (and loses
direct ownership of the consumed surfaces) or remains independent.

## Decision Drivers

1. Rigor must apply without exception across every Terraform framework.
2. Drift must be detectable mechanically, not policed by review.
3. Updates to the standard must propagate to every consumer with bounded
   manual effort (Renovate-managed SHA bumps).
4. Cross-org consumption must work without a shared PAT or secret.
5. Local development (`make ci`) must remain runnable without a network
   round-trip to the template.

## Decision Outcome

Chosen option: consume `NWarila/terraform-framework-template` by SHA.

Mechanics:

- Each consumer-side workflow is a thin caller that invokes a corresponding
  `reusable-*.yaml` from its owning repo at a SHA pin. The namespace callers —
  `codeql.yaml`, `scorecard.yaml`, `security.yaml`, `auto-merge.yaml`,
  `repo-hygiene.yaml`, and `release.yaml`'s release-please job — target
  `nwarila-platform/.github`; `release.yaml`'s evidence job targets
  `NWarila/terraform-framework-template` (the type-specific
  `reusable-release-evidence`). Namespace pins are reviewed together, and
  template pins are grouped by the local Renovate config.
- `release.yaml` follows the canonical task-dispatch pattern: on push to
  `main` (gated by repo variable `RELEASE_PLEASE_ON_PUSH=true`) it calls
  `reusable-release-please`; on `release.published` (or explicit
  `workflow_dispatch` with `task=release-evidence`) it calls
  `reusable-release-evidence` with `repo_type=framework`. This replaces
  the previous split where `release-please.yaml` invoked
  `release-please-action` natively and explicitly dispatched a separate
  `release-evidence.yaml`.
- `ci.yaml` runs `make ci` natively on `ubuntu-24.04` after installing
  pinned CI tools via `tools/install_ci_tools.sh`. The same `make ci` runs
  locally without any network round-trip to the template.
- `template-sync.yaml` calls the canonical `NWarila/drift-gate` composite
  action against `NWarila/terraform-framework-template@<SHA>` with
  `manifest: baseline-manifest.json`. It reports byte-level drift via
  GitHub Check Run annotations. Detection-only; it does not open sync PRs.
- `org-adr-sync.yaml` verifies that this repo's `docs/decision-records/org/`
  mirror is byte-identical to `nwarila-platform/.github` at a pinned SHA.
- `policies/opa/iso_manager.rego` retains rules specific to the ISO manager
  domain (HTTPS-only URLs, `overwrite_unmanaged` restrictions,
  `checksum_algorithm = "sha256"`, `verify = true`). Namespace repository
  hygiene rules run through this repo's `repo-hygiene.yaml` caller of
  `nwarila-platform/.github`.

## Consequences

### Positive

- Template SHA bumps propagate template-owned reusable and baseline updates;
  namespace reusable pins stay aligned with `nwarila-platform/.github`.
- `template-sync.yaml` mechanically surfaces baseline drift against the
  template's manifest. Failures land as inline check-run annotations.
- `auto-merge.yaml` enables hands-off Renovate PR merging when CI is green.
- New Terraform repositories adopt the standard by copying caller workflows,
  the `Makefile`, and `tools/install_ci_tools.sh`, then pointing pins at the
  template's current `main`.

### Negative

- This repository depends on `NWarila/terraform-framework-template` being
  available at the pinned SHA. A force-deletion or rewrite of the template's
  `main` would break this repository's CI until the pin is updated.
- The template manifest is intentionally slim. At the source currently pinned
  by `template-sync.yaml` (`dbf383819632c8bc1bbb9bbaef1cff2deccd0157`), it
  publishes 11 `byte_identical` entries and 9 `scaffold_starter` entries. This
  consumer mirrors the enforced entries; the old bulk-backfill plan is
  obsolete.
- Updates to the template's reusable interface (new required input) require
  updating the consumer's caller manually. Renovate does not auto-edit
  caller `with:` blocks.

### Neutral

- The template is a public repository under `NWarila`; this repository is
  under `nwarila-platform`. Cross-org `workflow_call` works because the
  template is public; access does not require allowlisting.

## Confirmation

- `template-sync.yaml` runs `NWarila/drift-gate` against the template's
  `baseline-manifest.json` on a weekly schedule and on `workflow_dispatch`,
  reporting drift via check-run annotations.
- `ci.yaml` runs `make ci` on every PR; the same gates run locally via
  `make ci`.
- The template SHA appears in template-owned caller workflow references, and
  namespace governance callers pin `nwarila-platform/.github` by full commit
  SHA; pin freshness is observable through review of the workflow diffs.

## Related ADRs

- [ADR-0002: Use repo-local Renovate baseline](0002-use-repo-local-renovate-baseline.md)
  - the Renovate configuration that groups the
  `terraform-framework-template` SHA bumps.

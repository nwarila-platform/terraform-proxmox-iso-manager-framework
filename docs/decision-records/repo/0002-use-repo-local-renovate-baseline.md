# ADR-0002: Use a Repo-Local Renovate Baseline Until Org Preset Exists

| Field          | Value                                    |
| -------------- | ---------------------------------------- |
| Status         | Accepted                                 |
| Date           | 2026-05-05                               |
| Authors        | Nick Warila (@NWarila)                   |
| Decision-maker | Nick Warila (sole portfolio maintainer)  |
| Consulted      | None.                                    |
| Informed       | None.                                    |
| Reversibility  | High                                     |
| Review-by      | N/A (Accepted)                           |

## TL;DR

This repository keeps the effective Renovate policy directly in `.github/renovate.json5`
instead of extending `github>nwarila-platform/.github`. The org-wide ADR-0004 pattern is
still the desired end-state, but the special `.github` repository does not currently publish
the shared Renovate preset. A local baseline is safer than a config that looks centralized
but cannot be resolved by Renovate.

## Context and Problem Statement

Org ADR-0004 standardizes Renovate and expects adopting repositories to inherit a shared
baseline from `nwarila-platform/.github`. During this repository review, the public special
`.github` repository did not contain the referenced `.github/renovate.json5` preset. Keeping
`extends: ["github>nwarila-platform/.github"]` here made dependency automation depend on a
missing artifact.

## Decision Drivers

1. Dependency automation must be operational, not aspirational.
2. The repo must preserve SHA-pinned GitHub Actions and exact-pinned Terraform/provider
   behavior while the org preset is unavailable.
3. The migration back to an org preset should be a small config-only change when the preset
   exists.

## Considered Options

1. Keep extending the missing org preset.
2. Inline the required Renovate behavior in this repo.
3. Disable Renovate until the org preset exists.

## Decision Outcome

Chosen option: **Option 2, inline the required Renovate behavior locally.**

The local config extends Renovate's recommended baseline, enables a dependency dashboard,
uses semantic commits, runs weekly, pins GitHub Actions by digest, and uses Terraform
`rangeStrategy: "pin"`. It also enables a narrowly scoped `custom.regex` manager for the
`terraform_version` input in `.github/workflows/pr-validation.yaml`, keeping the CI
Terraform binary aligned with the exact module constraint in `terraform/versions.tf`.

## Pros and Cons of the Options

### Option 1: Keep extending the missing org preset

- **Good, because** it matches org ADR-0004 literally.
- **Bad, because** Renovate cannot apply a preset that is not published.

### Option 2: Inline the baseline locally (chosen)

- **Good, because** dependency automation is self-contained and auditable in this repo.
- **Good, because** the local behavior preserves the important org controls.
- **Bad, because** common Renovate behavior can drift from other repositories until the org
  preset exists.

### Option 3: Disable Renovate

- **Good, because** it avoids config drift.
- **Bad, because** pinned dependencies silently age.

## Confirmation

Adherence is confirmed by reviewing `.github/renovate.json5` for:

1. `github-actions` package rules with `pinDigests: true`.
2. Terraform package rules with `rangeStrategy: "pin"`.
3. `custom.regex` coverage for the `hashicorp/setup-terraform` `terraform_version` input.
4. A weekly schedule and dependency dashboard.

When `nwarila-platform/.github` publishes a working shared preset, this ADR may be superseded
and the local config can return to `extends: ["github>nwarila-platform/.github"]`.

## Consequences

### Positive

- Dependency updates remain operational today.
- Recruiter-facing automation no longer points at a missing org artifact.

### Negative

- This repo temporarily carries Renovate policy that ADR-0004 expected to be centralized.

### Neutral

- The decision is easy to reverse once the shared preset exists.

## Assumptions

1. The org shared preset will be created later or intentionally abandoned.
2. Renovate continues to support package-rule based digest pinning for GitHub Actions.

## Supersedes

None.

## Superseded by

None (current).

## Implementing PRs

Pending. This ADR ships with the config change that inlines `.github/renovate.json5`.

## Related ADRs

- [ADR-0004 (org)](../org/0004-use-renovate-for-dependency-updates.md) — establishes the
  desired shared-baseline pattern.

## Compliance Notes

| Framework              | Control / Practice ID                           | Potential Evidence Contribution                                              |
| ---------------------- | ----------------------------------------------- | ---------------------------------------------------------------------------- |
| NIST SP 800-53 Rev. 5  | SI-2 (Flaw Remediation)                         | Renovate continues to provide automated dependency-update visibility.         |
| NIST SP 800-218 (SSDF) | PW.4 (Reuse Existing, Well-Secured Software)    | Local digest pinning and exact Terraform pins keep reused components tracked. |

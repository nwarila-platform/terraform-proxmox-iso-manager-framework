# ADR-0001: Place Module HCL in a `terraform/` Subdirectory

| Field          | Value                                    |
| -------------- | ---------------------------------------- |
| Status         | Accepted                                 |
| Date           | 2026-05-05                               |
| Authors        | Nick Warila (@NWarila)                   |
| Decision-maker | Nick Warila (sole portfolio maintainer)  |
| Consulted      | None.                                    |
| Informed       | None.                                    |
| Reversibility  | Low                                      |
| Review-by      | N/A (Accepted)                           |

## TL;DR

Module HCL for `terraform-proxmox-iso-manager-framework` lives under a top-level `terraform/` subdirectory rather than at the repository root. Consumers import the module via the git double-slash path syntax: `source = "git::<repo>//terraform?ref=vX.Y.Z"`. The repository root is reserved for governance, documentation, tooling, and release automation. This matches the layout convention used across other Terraform repositories in `nwarila-platform` and keeps the root visually uncluttered, at the cost of one extra path segment in every consumer's `source =` URL.

## Context and Problem Statement

This repository is a reusable Terraform child module imported by per-OS Packer template repositories (e.g. `secure-rockylinux9-template`) via the `module "iso" { source = ... }` block. The Terraform community has settled on two conventional layouts for module repositories:

1. **Root layout.** All `.tf` files at the repository root. This is the Terraform Registry convention — registries auto-detect modules expecting HCL at the root, and consumers pin via `source = "git::<repo>?ref=vX.Y.Z"` with no path component.
2. **Subdirectory layout.** Module HCL under `terraform/` (or `module/`, `src/`). The repository root holds only governance, documentation, and tooling. Consumers must use the git double-slash path syntax: `source = "git::<repo>//terraform?ref=vX.Y.Z"`.

The `nwarila-platform` portfolio has converged on the subdirectory layout for Terraform repositories, including `proxmox-terraform-framework`. The convergence is structural rather than semantic — the sibling `proxmox-terraform-framework` is a *root* module (it owns `backend.tf` and `providers.tf` and is applied directly), not a child module imported via `source =` like this repo. The two repos share the directory layout but not the architectural role.

The decision surfaced during initial bootstrap. The first commit placed `.tf` at the root; commit `e58c576 refactor: split main.tf into locals.tf + resources.tf to match nwarila-platform convention` then moved them under `terraform/` without updating the README or CI workflow in lockstep, leaving the repository in a half-finished state. This ADR records the chosen direction and forces dependent corrections.

## Decision Drivers

The following forces shaped this decision:

1. **Cross-repo consistency.** Contributors moving between `nwarila-platform` repositories should encounter a uniform layout. A reader skimming the repository root should see governance and tooling files, not module HCL.
2. **Tooling targetability.** Pre-commit hooks, CI working directories, terraform-docs scans, and tflint configurations have a single, predictable target directory rather than scanning the whole repository for `*.tf`.
3. **Consumer ergonomics.** The cost of an extra `//terraform` path segment in every consumer's `source =` URL is real but small. It is paid once per consumer and is mechanically discoverable.
4. **Forward extensibility.** A subdirectory leaves room for adjacent directories (`examples/`, `tests/`, additional Terraform configurations) without coupling them to the module's git source path.

## Considered Options

1. **Root layout (`.tf` at the repository root).** The Terraform Registry convention. Consumers pin via `source = "git::<repo>?ref=vX.Y.Z"` with no path component.
2. **Subdirectory layout (`terraform/`).** All HCL under `terraform/`. Consumers pin via `source = "git::<repo>//terraform?ref=vX.Y.Z"`.
3. **Hybrid layout (`.tf` at root, sub-modules under `modules/`).** Root HCL plus a `modules/` directory for additional sibling modules.
4. **Symlink `terraform/` → repo root (or vice versa).** A filesystem symlink papers over the choice.

## Decision Outcome

Chosen option: **Option 2, subdirectory layout under `terraform/`.**

Module HCL lives under `terraform/`. Specifically:

- All `.tf` files for this module reside in `/terraform/`. No `.tf` files live at the repository root.
- Consumers pin via `source = "git::https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework.git//terraform?ref=vX.Y.Z"`. The `//terraform` path component is non-optional; without it, `terraform init` resolves the repository root and fails to find any module configuration.
- The CI workflow (`.github/workflows/ci.yaml`) runs `terraform fmt -check -recursive .`, `terraform init -backend=false`, and `terraform validate` with `working-directory: terraform`. The path filter that triggers the workflow is scoped to `terraform/**`.
- The repository root is reserved for repository-specific governance (`README.md`, `CHANGELOG.md`, `LICENSE`), tooling (`.editorconfig`, `.gitignore`, `.gitattributes`, `.markdownlint-cli2.jsonc`), release automation (`release-please-config.json`, `.release-please-manifest.json`), and `.github/` workflow/config files that cannot be inherited. Generic community-health files are inherited from `nwarila-platform/.github`.
- Architectural decisions live at `docs/decision-records/{org,repo}/` per [ADR-0001 (org)](../org/0001-use-architecture-decision-records.md).

## Pros and Cons of the Options

### Option 1: Root layout

- **Good, because** it is the Terraform Registry convention; if this module is ever published to the registry the layout already matches.
- **Good, because** consumers pin with the simplest possible `source =` URL — no path component.
- **Good, because** error messages and stack traces show short paths (`locals.tf:5` rather than `terraform/locals.tf:5`).
- **Bad, because** it diverges from the `nwarila-platform` convergence pattern; contributors moving between repos must context-switch.
- **Bad, because** the repository root mixes governance, tooling, and module HCL, which is visually noisy.
- **Bad, because** CI path filters that target Terraform changes must use loose globs (`**/*.tf`) that may match unintended files.

### Option 2: Subdirectory layout (chosen)

- **Good, because** it matches the rest of `nwarila-platform`; contributors see a consistent shape across repositories.
- **Good, because** the repository root is uncluttered — governance and tooling files do not visually compete with module HCL.
- **Good, because** terraform-docs, pre-commit hooks, and CI working directories have a single, predictable target.
- **Good, because** future adjacent directories (`examples/`, `tests/`) can sit alongside `terraform/` without crowding the root.
- **Neutral, because** the `//terraform` path component in every consumer's `source =` URL is paid once per consumer.
- **Bad, because** the Terraform Registry's auto-detection does not follow `//terraform` paths; registry publication would require restructuring or a registry-shape mirror.
- **Bad, because** error messages and logs include the extra path segment.

### Option 3: Hybrid layout

- **Good, because** it preserves root-layout consumer ergonomics for the primary module while leaving room for additional modules under `modules/`.
- **Bad, because** the repository's intent is intentionally single-concern: "If a second concern justifies a separate module in the future, that is grounds for a new repo, not a subdir here." Allowing `modules/` invites drift from that constraint.
- **Bad, because** it inherits the root-layout's cluttered repository root.

### Option 4: Symlink `terraform/` → repo root

- **Good, because** consumers could pin either path form and both would work.
- **Bad, because** git on Windows does not handle symlinks portably; the symlink resolves differently across operating systems and CI runners.
- **Bad, because** consumers would still need to pick one shape; the symlink only delays the choice and adds a debugging vector.

## Confirmation

Adherence to this ADR is confirmed by the following mechanisms. The wording `MUST`, `SHOULD`, and `MAY` follows [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) conventions.

1. **Layout check.** All module HCL MUST reside under `/terraform/`. No `.tf` files MAY exist at the repository root. A reviewer SHOULD reject a PR that introduces a root-level `.tf` file.
2. **CI working-directory check.** The PR-validation workflow MUST set `defaults.run.working-directory: terraform` and MUST scope its `paths:` filter to `terraform/**`. Drift here silently disables Terraform validation; reviewers SHOULD inspect both fields when reviewing workflow changes.
3. **Consumer-contract check.** The `README.md` `Usage` section MUST show the consumer `source =` URL with the `//terraform` path component. A PR that removes the `//terraform` segment is a breaking documentation change.
4. **Editorial rule.** A change of layout (back to root, or to a different subdirectory name) is itself an architectural decision and MUST be recorded as a superseding ADR; it MUST NOT be made by silent refactor.

## Consequences

### Positive

- The repository root is uncluttered; governance and tooling files are not visually competing with module HCL.
- Layout matches the rest of `nwarila-platform`; contributors see a consistent shape across repositories.
- CI `paths:` filters and `working-directory:` settings can be unambiguous.
- Future adjacent directories (`examples/`, `tests/`) can be added without crowding the root.

### Negative

- Consumers must include `//terraform` in their `source =` URL. A consumer that omits it hits `terraform init` failure with no module found — non-obvious if they copied a snippet from a root-layout module.
- The Terraform Registry's auto-detection does not follow `//terraform` paths; registry publication would require restructuring back to root or a separate mirror repo.
- One additional path segment in error messages and logs (e.g. `terraform/locals.tf:5` rather than `locals.tf:5`).

### Neutral

- The `.gitignore` allowlist must enumerate `terraform/` and each tracked `.tf` file inside it; this is consistent with the deny-all + explicit-allow pattern from [ADR-0003 (org)](../org/0003-use-deny-all-gitignore-strategy.md).
- Future ADRs that introduce additional Terraform configurations (e.g. examples that get applied in CI) must declare their working directory explicitly rather than assuming the repo root.

## Assumptions

This decision rests on the following assumptions. If any becomes false, this ADR should be revisited:

1. The `nwarila-platform` portfolio continues to use `terraform/` as the conventional subdirectory for Terraform module repositories.
2. This module is not published to the Terraform Registry. If registry publication is desired in the future, the registry's root-detection requirement may force a layout change.
3. Consumers of this module are willing to learn the `//terraform` path-segment convention. If a consumer base emerges that expects root-layout semantics (e.g. via a generated module catalog), the trade-off may shift.

## Supersedes

None.

## Superseded by

None (current).

## Implementing PRs

Pending. This ADR ships in the same PR as the workflow `working-directory` fix, the README `source =` URL update, and the repo-specific development notes now housed under `docs/how-to/`.

## Related ADRs

- [ADR-0001 (org)](../org/0001-use-architecture-decision-records.md) — establishes the format and dual-scope structure of decision records, including this repo-specific ADR.
- [ADR-0003 (org)](../org/0003-use-deny-all-gitignore-strategy.md) — establishes the deny-all `.gitignore` strategy. This repo's `.gitignore` allowlist explicitly enumerates `terraform/` and its tracked contents, consistent with that strategy.
- [ADR-0004 (org)](../org/0004-use-renovate-for-dependency-updates.md) — standardizes Renovate across the org. [ADR-0002 (repo)](0002-use-repo-local-renovate-baseline.md) records this repo's local Renovate baseline while the org shared preset is not published.

## Compliance Notes

This ADR establishes a directory-layout convention. It does not directly modify the security posture of the module. It does affect the consumer contract surface: any consumer pinning this module before this ADR landed is pinning to a state in which the repository was mid-refactor. The first tagged release (`v1.0.0`) is the first stable expression of the chosen layout, so consumers cannot have pre-existing `?ref=v...` pins that depend on a different shape.

| Framework              | Control / Practice ID                                    | Potential Evidence Contribution                                                                 |
| ---------------------- | -------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| NIST SP 800-53 Rev. 5  | CM-2 (Baseline Configuration)                            | The locked layout serves as a baseline configuration of the module's source structure.          |

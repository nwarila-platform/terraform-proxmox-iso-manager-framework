# Architecture Decision Records

This directory contains the Architecture Decision Records (ADRs) for
`terraform-proxmox-iso-manager-framework`.

ADRs are organized by scope per
[org ADR-0001](org/0001-use-architecture-decision-records.md). This repository
currently populates the org and repo scopes:

- **`org/`** - byte-identical mirrors of org-baseline ADRs from
  [`nwarila-platform/.github/docs/decision-records/`](https://github.com/nwarila-platform/.github/tree/main/docs/decision-records).
  These ADRs apply to repositories in the `nwarila-platform` organization and
  are kept in sync with their masters.
- **`repo/`** - repository-specific ADRs that apply only to this repository.

The namespaces are independent: `org/0001` and `repo/0001` can coexist because
they are in different directories.

## Index

### Org-Baseline (mirrored from `nwarila-platform/.github`)

These mirrors are kept byte-identical to their masters by the `Org ADR Sync`
workflow (see
[`.github/workflows/org-adr-sync.yaml`](../../.github/workflows/org-adr-sync.yaml)).
Do not edit these files directly; changes must land at the master location in
`nwarila-platform/.github` and propagate via the next sync run.

| #                                                              | Title                                                           | Status   | Date       |
| -------------------------------------------------------------- | --------------------------------------------------------------- | -------- | ---------- |
| [0001](org/0001-use-architecture-decision-records.md)          | Use Architecture Decision Records to Document Design Rationale  | Accepted | 2026-04-22 |
| [0002](org/0002-adopt-diataxis-documentation-framework.md)     | Adopt Diataxis as the Documentation Framework                   | Accepted | 2026-04-24 |
| [0003](org/0003-use-deny-all-gitignore-strategy.md)            | Use a Deny-All `.gitignore` Strategy                            | Accepted | 2026-04-25 |
| [0004](org/0004-use-renovate-for-dependency-updates.md)        | Use Renovate for Dependency Updates with Per-Template Baselines | Accepted | 2026-05-05 |
| [org/0005](org/0005-keep-github-control-planes-namespace-local.md) | Keep GitHub Control Planes Namespace-Local | Accepted | 2026-06-02 | Use the owning namespace control plane for governance, ADRs, repo hygiene, and reusable workflow callers. |

### Repository-Specific

| #                                               | Title                                                      | Status   | Date       |
| ----------------------------------------------- | ---------------------------------------------------------- | -------- | ---------- |
| [0001](repo/0001-terraform-subdirectory-layout.md) | Place Module HCL in a `terraform/` Subdirectory         | Accepted | 2026-05-05 |
| [0002](repo/0002-use-repo-local-renovate-baseline.md) | Use a Repo-Local Renovate Baseline Until Org Preset Exists | Accepted | 2026-05-05 |
| [0003](repo/0003-allow-example-local-readmes.md) | Allow Short Example-Local READMEs                         | Accepted | 2026-05-05 |
| [0004](repo/0004-consume-terraform-template.md) | Consume NWarila/terraform-framework-template as Golden Standard | Accepted | 2026-05-07 |

## How to Contribute a New ADR

See [org ADR-0001](org/0001-use-architecture-decision-records.md) section
"How to Contribute a New ADR" and the org-level
[decision-records README](https://github.com/nwarila-platform/.github/blob/main/docs/decision-records/README.md).
The format is MADR 4.0-aligned with portfolio-specific extensions; copy
[org ADR-0001](org/0001-use-architecture-decision-records.md) as your template.

For decisions that affect only this repository, place the new file at
`docs/decision-records/repo/NNNN-short-kebab-title.md` where `NNNN` is the next
unused four-digit number in the repo namespace, and update the index above. Do
not mirror it to any other repository.

For decisions that should apply org-wide, do not author them here. Author the
new ADR in `nwarila-platform/.github` and follow the mirroring workflow
described there.

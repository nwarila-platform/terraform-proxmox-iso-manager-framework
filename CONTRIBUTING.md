# Contributing

## Repository Layout

This is a single-module repository. Module HCL lives under `terraform/` so the repo root
stays focused on governance, docs, and tooling. Consumers import the module via the git
double-slash path syntax — see `README.md` for the canonical `source =` form.

```text
.
├── terraform/
│   ├── locals.tf
│   ├── outputs.tf
│   ├── resources.tf
│   ├── variables.tf
│   └── versions.tf
├── docs/
│   └── ADR/                # architectural decision records
├── README.md               # consumer-facing usage
├── CONTRIBUTING.md
├── SECURITY.md
├── SUPPORT.md
├── CHANGELOG.md            # maintained by release-please
├── LICENSE
└── .github/                # CODEOWNERS, issue/PR templates, workflows
```

The rationale for the `terraform/` subdirectory layout (and the rejected root-layout
alternative) is recorded in
[`docs/decision-records/repo/0001-terraform-subdirectory-layout.md`](docs/decision-records/repo/0001-terraform-subdirectory-layout.md).
There are no nested `modules/` directories. If a second concern justifies a separate
module in the future, that is grounds for a new repo, not a subdir here.

## Branching

- `main` is protected. All changes land via PR.
- Feature branches: `feat/<short-name>` or `fix/<short-name>`.
- One PR per logical change.

## Conventional Commits

Every commit subject MUST follow the [Conventional Commits 1.0](https://conventionalcommits.org)
spec. release-please consumes commit prefixes to compute the next version and write
`CHANGELOG.md`.

| Prefix | Effect on next release |
|---|---|
| `feat:` | Minor version bump |
| `fix:` | Patch version bump |
| `feat!:` / `BREAKING CHANGE:` footer | Major version bump |
| `chore:`, `test:`, `ci:`, `refactor:`, `docs:`, `security:` | No bump (some hidden in changelog) |

## Local Validation

Before opening a PR:

```bash
terraform fmt -recursive terraform/
cd terraform && terraform init -backend=false && terraform validate
```

The PR Validation workflow runs the same checks against the `terraform/` directory.
Keeping local clean prevents avoidable round-trips.

## Architectural Decisions (ADRs)

Material decisions with rejected alternatives belong in `docs/decision-records/` per
[org ADR-0001](docs/decision-records/org/0001-use-architecture-decision-records.md). The
directory is split into two scopes:

- **`docs/decision-records/org/`** — byte-identical mirrors of org-baseline ADRs from
  `nwarila-platform/.github`. Do not edit these; they are sync'd from upstream.
- **`docs/decision-records/repo/`** — repository-specific ADRs. New repo-scope ADRs are
  authored here as `NNNN-short-kebab-title.md` using the canonical template (which is
  [org ADR-0001](docs/decision-records/org/0001-use-architecture-decision-records.md)
  itself — the file is both the inaugural decision and the worked template).

See [`docs/decision-records/README.md`](docs/decision-records/README.md) for the full
index and authoring workflow.

Write an ADR when a decision shapes how future work in this repo is done and a reader
six months from now would reasonably ask "why did we choose X over Y?". Do **not** write
an ADR for runbooks, style preferences with no real alternatives, or short-lived task
notes — those belong in issues, PR descriptions, or inline comments.

## Module Contract Changes

Adding a required input or removing an output is a breaking change and must use the `feat!:`
prefix or include a `BREAKING CHANGE:` footer. Renaming an output without alias is breaking.
Adding an optional input with a sensible default is non-breaking.

When changing the module's contract, also update `README.md`'s Inputs and Outputs tables in
the same PR.

## Releasing

You don't release directly. The `Release Please` workflow opens (or updates) a single
`chore: release X.Y.Z` PR whenever release-bumping commits land on `main`. Merging that PR
creates the corresponding tag, which downstream consumer repos pin via `?ref=vX.Y.Z`.

The first release is forced to `1.0.0` via the `release-as` field in
`release-please-config.json` under `packages."."`. **After the v1.0.0 tag is cut, remove
that field** so subsequent releases bump from Conventional Commit types in the normal
way. Leaving `release-as` in place would freeze every release at 1.0.0 regardless of
commit content.

Dependency-update PRs are opened by Renovate (see
[ADR-0002](docs/ADR/0002-renovate-instead-of-dependabot.md)) on a weekly schedule. They
land on `main` like any other PR and feed the same release-please pipeline.

## Security

The repository inherits its security policy from
[`nwarila-platform/.github/SECURITY.md`](https://github.com/nwarila-platform/.github/blob/main/SECURITY.md);
see the [Security tab](../../security/policy) for the rendered policy and reporting
instructions. CI security scanners (Trivy, Gitleaks, CodeQL) are wired in
[`.github/workflows/`](.github/workflows/).

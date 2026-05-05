# Contributing

## Repository Layout

This is a single-module repository. The module HCL lives at the repo root:

```
.
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── README.md          # also serves as the module's README on the Terraform Registry
├── .github/
│   └── workflows/
└── ...
```

There are no nested `modules/` directories. If a second concern justifies a separate module
in the future, that is grounds for a new repo, not a subdir here.

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
terraform fmt -recursive .
terraform init -backend=false
terraform validate
```

The PR Validation workflow runs the same checks. Keeping local clean prevents avoidable
round-trips.

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

## Security

See [SECURITY.md](SECURITY.md) for vulnerability disclosure and the coverage of CI security
scanners.

# How to develop this module locally

This repository relies on generic community-health defaults from `nwarila-platform/.github`.
Keep repo-specific development notes here instead of adding local `CONTRIBUTING.md`,
`SUPPORT.md`, `SECURITY.md`, issue templates, or pull request templates.

## Repository layout

Module HCL lives under `terraform/` so consumers import it with the git double-slash source
path:

```hcl
source = "git::https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework.git//terraform?ref=vX.Y.Z"
```

The root remains for README, docs, workflows, release automation, and repo tooling.

## Local validation

Run the exact Terraform version pinned in `terraform/versions.tf`:

```bash
make ci
```

`make ci` runs Terraform formatting, init, validate, tests, generated-docs
drift checks, docs layout enforcement, and OPA policy tests. The `CI` workflow
runs the same local gates in GitHub Actions.

## Terraform lockfile policy

This repository is a consumed child module, not a root Terraform stack. Generated Terraform
working files stay untracked:

- `terraform/.terraform/`
- `terraform/.terraform.lock.hcl`
- `tests/fixtures/*/.terraform/`
- `tests/fixtures/*/.terraform.lock.hcl`
- `artifacts/`

Consumers' root modules own provider lockfiles. This module expresses compatibility with exact
provider constraints in `terraform/versions.tf`.

## Contract changes

Adding a required input or removing an output is breaking and must be released as a breaking
change. Adding an optional input with a safe default is non-breaking. When the module
contract changes, update `README.md` and run `make docs` so
`docs/reference/terraform.md` stays in sync.

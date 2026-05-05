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
cd terraform
terraform fmt -check -recursive .
terraform init -backend=false
terraform validate
terraform test
```

The PR Validation workflow runs the same Terraform checks.

## Terraform lockfile policy

This repository is a consumed child module, not a root Terraform stack. Generated Terraform
working files stay untracked:

- `terraform/.terraform/`
- `terraform/.terraform.lock.hcl`

Consumers' root modules own provider lockfiles. This module expresses compatibility with exact
provider constraints in `terraform/versions.tf`.

## Contract changes

Adding a required input or removing an output is breaking and must be released as a breaking
change. Adding an optional input with a safe default is non-breaking. When the module contract
changes, update `README.md` and `docs/reference/terraform.md` in the same PR.

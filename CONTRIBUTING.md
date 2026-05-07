# Contributing

This repository is a Terraform child module. Keep changes small, reviewable, and tied to the module contract.

## Local prerequisites

Required:

- Terraform `1.15.1`
- Bash
- Git
- Python 3
- GNU Make

CI also uses:

- TFLint `0.59.1`
- terraform-docs `0.20.0`
- OPA `1.10.0`
- Graphviz for graph rendering

Install repository CI tools with:

```bash
bash tools/install_ci_tools.sh
```

Install Graphviz with your operating system package manager before running graph validation.

## Required local validation

Run:

```bash
make ci
```

Run graph validation when Terraform dependency shape, fixtures, graph tooling, or release evidence changes:

```bash
make graph
```

## Change rules

- Preserve the `terraform/` child-module layout.
- Preserve exact Terraform and provider pins unless updating the documented version policy by ADR.
- Do not add live Proxmox dependencies to tests.
- Do not commit Terraform state, plans, `.terraform/`, provider caches, credentials, signed URLs, or `tfvars`.
- Do not weaken validation rules without a matching test and an explicit rationale.
- Keep examples runnable with `terraform init -backend=false` and `terraform validate`.
- Keep security claims aligned with `docs/explanation/threat-model.md`.
- Keep generated Terraform reference tables inside the `BEGIN_TF_DOCS` and `END_TF_DOCS` markers.

## Commit style

Use Conventional Commits:

```text
feat: add supported behavior
fix: correct broken behavior
docs: update documentation only
test: update tests only
ci: update workflows only
deps: update dependencies only
security: security-relevant change
chore: maintenance without user-facing effect
```

Release Please uses these commits to generate releases and changelog entries.

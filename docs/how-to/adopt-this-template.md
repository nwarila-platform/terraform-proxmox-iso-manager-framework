# Adopt This Template

Use this checklist when deriving another Terraform module repository from this one.

## 1. Rename project metadata

Update:

- Repository name
- README title
- GitHub badge URLs
- Module source examples
- Release Please package name if needed
- CODEOWNERS entries if ownership changes

## 2. Replace module domain

Update:

- `terraform/variables.tf`
- `terraform/locals.tf`
- `terraform/resources.tf`
- `terraform/outputs.tf`
- `terraform/tests/`
- `docs/explanation/architecture.md`
- `docs/explanation/threat-model.md`
- `docs/explanation/testing-strategy.md`
- `docs/reference/invariants.md`

Do not keep Proxmox ISO language in a module that does not manage Proxmox ISOs.

## 3. Replace examples and fixtures

Keep only example categories that are real for the derived module:

- Minimal valid module call
- Real consumer-shaped example
- Adoption or recovery example, if the module supports adoption or recovery
- Failure-case example for an important rejected configuration
- Test fixtures, if fixture tooling remains relevant

Delete fake examples. A smaller honest template is better than broad but false coverage.

## 4. Update version pins

Update exact pins in:

- `terraform/versions.tf`
- Example `terraform` blocks
- README provider requirements
- Renovate custom managers, if applicable
- CI Terraform setup inputs

Keep exact pinning unless a repository-specific ADR changes the policy.

## 5. Update documentation

Update:

- `README.md`
- `docs/README.md`
- `docs/explanation/architecture.md`
- `docs/explanation/testing-strategy.md`
- `docs/explanation/threat-model.md`
- `docs/reference/release-gates.md`
- `docs/reference/invariants.md`
- `docs/reference/mirroring.md`
- `docs/reference/terraform.md`

Regenerate Terraform reference docs after editing the module.

## 6. Validate locally

Run:

```bash
make ci
```

Also inspect:

```bash
git status --short
git diff --check
```

## 7. Validate in GitHub

Open a pull request and require the relevant workflows to pass before merge:

- CI
- Security Scan
- CodeQL Analysis
- Scorecard
- Template Sync
- Repo Hygiene
- Org ADR Mirror Check, if org ADR mirrors are present

## 8. First release

After merge, verify:

- Release Please opened or updated a release PR.
- The release PR changelog is accurate.
- The release tag points to the intended commit.
- Release evidence was generated without state, plans, `.terraform/`, `tfvars`, caches, credentials, tokens, signed URLs, or secrets.

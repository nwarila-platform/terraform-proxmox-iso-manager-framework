# Security Policy

## Scope

Security scope includes:

- Terraform module code in `terraform/`
- Example configurations in `examples/`
- Terraform tests and fixtures
- GitHub Actions workflows
- Dependency automation
- Release evidence tooling
- OPA policy checks in `policies/`
- Documentation that affects safe use of the module

Security scope does not include:

- Trustworthiness of upstream ISO publishers or mirrors
- Consumer Proxmox cluster hardening
- Consumer provider credentials
- Consumer Terraform backends
- Consumer Packer templates outside this repository
- Consumer networks, DNS, TLS interception, or local trust stores

See `docs/explanation/threat-model.md` for the detailed security boundary.

## Supported versions

Only the latest released version is supported.

Consumers should pin this module to a release tag and update deliberately after reviewing the changelog.

## Reporting a vulnerability

Use GitHub's private vulnerability reporting flow for this repository when available.

If private reporting is unavailable, open a public issue asking for a private reporting channel. Do not include exploit details, credentials, tokens, private infrastructure names, signed URLs, or live target information in a public issue.

## Handling expectations

Security fixes should include:

- A minimal patch
- A regression test when practical
- Updated documentation when the security boundary changes
- A release note using a `security:` Conventional Commit

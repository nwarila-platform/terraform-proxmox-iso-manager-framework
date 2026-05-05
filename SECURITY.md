# Security Policy

## Supported Versions

Only the latest commit on `main` is actively maintained. Security fixes are applied to `main`
and released from there.

## Reporting a Vulnerability

This project follows coordinated disclosure. **Do not open a public issue for security
vulnerabilities.**

**Email:** reports@TrinityTechnicalServices.com

Please include:

- a description of the issue
- the affected version
- steps to reproduce
- expected versus actual behavior
- any suggested remediation

### Response Timeline

| Stage | Timeline |
|---|---|
| Acknowledgement | Within 48 hours |
| Assessment | Within 5 business days |
| Resolution | Before public disclosure |

## Security Controls

- **Trivy** scans this repository for filesystem misconfigurations and secrets on every push,
  PR, and weekly schedule.
- **Gitleaks CLI** scans repository history for secrets on every push, PR, and weekly
  schedule (SHA256-pinned download, no third-party action wrapper, MIT-licensed binary).
- **CodeQL** analyzes GitHub Actions workflow content.
- **SHA-pinned actions**: every `uses:` reference in `.github/workflows/` pins to a full
  commit SHA, with a comment indicating the human-readable tag it corresponds to.
- **Dependabot** tracks GitHub Actions updates.
- **`persist-credentials: false`** is set on every checkout step.

## Scope

### In Scope

- Module input validation gaps that fail open (e.g. accepting injection-vulnerable values).
- HCL constructs that accidentally expose sensitive values to plan output / state.
- Workflow vulnerabilities in this repository.

### Out of Scope

- Vulnerabilities in the Proxmox VE platform itself.
- Vulnerabilities in the `bpg/proxmox` Terraform provider.
- Misuse by downstream consumers (e.g. checking `tfvars` containing secrets into git).
- The integrity of the upstream ISO source itself — this module verifies the SHA256 the
  consumer provides; the consumer is responsible for sourcing trustworthy ISO checksums.

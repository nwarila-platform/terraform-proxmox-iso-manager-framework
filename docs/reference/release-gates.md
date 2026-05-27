# Release Gates

Every release should leave behind enough evidence for a reviewer to understand what was
validated and what would have blocked publication.

PR-time gates run via `make ci` in `pr-validation.yaml`:

| Gate | Tool | Blocks PR? | Notes |
|---|---|---|---|
| terraform fmt | `terraform fmt -check -recursive` | Yes | Enforces stable HCL formatting. |
| terraform init -backend=false | `terraform init` | Yes | Initializes providers without backend or state. |
| terraform validate | `terraform validate` | Yes | |
| terraform test | `terraform test` | Yes | Uses `mock_provider` for Proxmox. |
| tflint | `tflint --chdir=terraform` | Yes | |
| terraform-docs sync | `terraform-docs --output-check` | Yes | Fails if `docs/reference/terraform.md` is out of sync. |
| Docs layout enforcement | `tools/check_docs_layout.py` | Yes | Enforces Diataxis quadrant and ADR locations. |
| OPA policies | `opa test policies/opa` | Yes | |

Security gates run in `security.yaml` (Trivy, Gitleaks, zizmor) and `codeql.yaml`
(CodeQL Actions analysis); supply-chain signals come from `scorecard.yaml`.

Release evidence is produced by `release-evidence.yaml`, which invokes the canonical
`NWarila/terraform-framework-template` reusable-release-evidence reusable with
`repo_type: framework`. See [`docs/how-to/review-release-evidence.md`](../how-to/review-release-evidence.md)
for the artifact contract.

Release Please publishes release notes and tags after qualifying merges to `main`.
`release-please.yaml` explicitly dispatches `release-evidence.yaml` after each
release, since `GITHUB_TOKEN`-driven events do not cascade automatically.

## Workflow Control Plane

| Workflow | Trigger | Purpose | Permission baseline |
| --- | --- | --- | --- |
| `pr-validation.yaml` | PR, push to `main`, merge queue, manual | Terraform, docs, lint, and OPA gates via `make ci` | `contents: read` |
| `security.yaml` | PR, push to `main`, merge queue, weekly, manual | Trivy, Gitleaks, and zizmor scans | Job-specific read plus SARIF upload |
| `codeql.yaml` | PR, push to `main`, merge queue, weekly, manual | Static analysis for GitHub Actions | `contents: read`, `security-events: write`, `actions: read` |
| `scorecard.yaml` | Push to `main`, weekly, manual | OpenSSF Scorecard | `id-token: write`, `actions: read`, `contents: read` |
| `org-adr-sync.yaml` | Weekly, manual | Verify mirrored org ADRs against `nwarila-platform/.github` | `contents: read` |
| `template-sync.yaml` | Weekly, manual | Detect baseline drift against `NWarila/terraform-framework-template` via `NWarila/drift-gate` | `contents: read`, `checks: write` |
| `release-please.yaml` | Push to `main` | Release PRs and GitHub releases; dispatches `release-evidence.yaml` on release | Write permissions required for release automation |
| `release-evidence.yaml` | Release published, manual dispatch | Release evidence artifact | `contents: write`, `attestations: write`, `id-token: write` |
| `auto-merge.yaml` | `pull_request_target` | Auto-merge trusted-bot PRs once required checks pass | `contents: write`, `pull-requests: write` |

## Artifact Rules

Release evidence and workflow artifacts must not include Terraform state, raw plan files,
`.terraform/`, `tfvars`, provider caches, credentials, tokens, signed URLs, or private
infrastructure values. Bundle composition is governed by the canonical
`reusable-release-evidence.yaml` reusable; reviewers should sample uploaded artifacts
before publication.

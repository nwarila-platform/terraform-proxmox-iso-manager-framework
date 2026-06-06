# Release Gates

Every release should leave behind enough evidence for a reviewer to understand what was
validated and what would have blocked publication.

PR-time gates run via `make ci` in `ci.yaml`:

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

Security caller workflows delegate to org-owned reusable scanners: `security.yaml`
invokes Trivy, Gitleaks, and zizmor; `codeql.yaml` invokes CodeQL Actions
analysis; `scorecard.yaml` invokes OpenSSF Scorecard. Local proof covers the
caller wiring, pinned reusable references, and upload permissions; scanner
implementation and tool-version proof live in the upstream reusable workflows.

Release evidence is produced by `release.yaml`'s `evidence` job, which invokes the
canonical `NWarila/terraform-framework-template` reusable-release-evidence reusable
with `repo_type: framework`. See [`docs/how-to/review-release-evidence.md`](../how-to/review-release-evidence.md)
for the artifact contract.

Release Please publishes release notes and tags. `release.yaml`'s `release-please`
job invokes the canonical `reusable-release-please` reusable, which dispatches
`release.yaml` back with `task=release-evidence` after publishing a release
(GITHUB_TOKEN-driven `workflow_dispatch` is exempt from the no-cascade rule).
Push-triggered runs require repo variable `RELEASE_PLEASE_ON_PUSH=true`.

## Workflow Control Plane

| Workflow | Trigger | Purpose | Permission baseline |
| --- | --- | --- | --- |
| `ci.yaml` | PR, push to `main`, merge queue, manual | Terraform, docs, lint, and OPA gates via `make ci` | `contents: read` |
| `security.yaml` | PR, push to `main`, merge queue, weekly, manual | Trivy, Gitleaks, and zizmor scans | Job-specific read plus SARIF upload |
| `codeql.yaml` | PR, push to `main`, merge queue, weekly, manual | Static analysis for GitHub Actions | `contents: read`, `security-events: write`, `actions: read` |
| `scorecard.yaml` | Push to `main`, weekly, manual | OpenSSF Scorecard | `id-token: write`, `actions: read`, `contents: read` |
| `org-adr-sync.yaml` | PR, weekly, manual | Verify org-baseline drift against `nwarila-platform/.github` via `NWarila/drift-gate` | `contents: read`, `checks: write` |
| `template-sync.yaml` | Weekly, manual | Detect baseline drift against `NWarila/terraform-framework-template` via `NWarila/drift-gate` | `contents: read`, `checks: write` |
| `release.yaml` | Push to `main` (gated by `RELEASE_PLEASE_ON_PUSH`), `release.published`, manual dispatch with `task` choice | Release PRs + tags via `reusable-release-please`; evidence bundle via `reusable-release-evidence` | Per-job: release-please needs write on contents/PRs/issues/actions; evidence needs write on contents/attestations and `id-token: write` |
| `auto-merge.yaml` | `pull_request_target` | Auto-merge trusted-bot PRs once required checks pass | `contents: write`, `pull-requests: write` |

## Artifact Rules

Release evidence and workflow artifacts must not include Terraform state, raw plan files,
`.terraform/`, `tfvars`, provider caches, credentials, tokens, signed URLs, or private
infrastructure values. Bundle composition is governed by the canonical
`reusable-release-evidence.yaml` reusable; reviewers should sample uploaded artifacts
before publication.

# Quality Gates

Each automated check in this repository plays one of four roles. The role
determines *when* the check runs and *what failure means*. For the canonical
list of release-blocking gates see [release-gates.md](release-gates.md); this
document classifies each gate's role.

| Role | Meaning | When it runs |
| --- | --- | --- |
| **Blocking** | Required for PR merge to `main`. Failure blocks the PR. | `pull_request` / `merge_group` triggers in `ci.yaml`, `security.yaml`, `codeql.yaml`, `org-adr-sync.yaml` |
| **Scheduled** | Periodic posture telemetry. Runs on a cron; does **not** block PRs. | `schedule` trigger in `security.yaml`, `codeql.yaml`, `scorecard.yaml`, `template-sync.yaml`, `org-adr-sync.yaml` |
| **Release** | Runs at release time. Failure blocks the release tag and the evidence bundle. | `release.yaml` `evidence` job and the reusable it calls |
| **Advisory** | Surfaces signal without blocking. Reserved for steps whose publishing channel is best-effort. | Specific steps marked `continue-on-error: true` in the called reusables |

## Gate inventory

| Gate | Workflow | Role | Notes |
| --- | --- | --- | --- |
| `terraform fmt -check` | `ci.yaml` (`make ci`) | Blocking | Stable HCL formatting. |
| `terraform init -backend=false` | `ci.yaml` (`make ci`) | Blocking | Providers resolve without backend/state. |
| `terraform validate` | `ci.yaml` (`make ci`) | Blocking | |
| `terraform test` | `ci.yaml` (`make ci`) | Blocking | `mock_provider` for Proxmox; no live cluster. |
| `tflint` | `ci.yaml` (`make ci`) | Blocking | |
| `terraform-docs --output-check` | `ci.yaml` (`make ci`) | Blocking | Fails if `docs/reference/terraform.md` is stale. |
| `tools/check_docs_layout.py` | `ci.yaml` (`make ci`) | Blocking | Diataxis quadrant + ADR-tier placement. |
| `opa test policies/opa` | `ci.yaml` (`make ci`) | Blocking | Exercises `iso_manager.rego` against fixtures. |
| Trivy (filesystem + secrets) | `security.yaml` | Blocking | Fails on HIGH/CRITICAL. |
| Gitleaks | `security.yaml` | Blocking | Full-history secret scan. |
| zizmor | `security.yaml` | Blocking | GitHub Actions security analysis. |
| CodeQL (Actions) | `codeql.yaml` | Blocking | Static analysis of workflow code. |
| OpenSSF Scorecard | `scorecard.yaml` | Scheduled | Supply-chain posture; skipped on PR (private-repo GraphQL unreliable). |
| Org-baseline drift | `org-adr-sync.yaml` (`NWarila/drift-gate`) | Blocking | Mirror parity with `nwarila-platform/.github`. |
| Framework-template drift | `template-sync.yaml` (`NWarila/drift-gate`) | Scheduled | Mirror parity with `NWarila/terraform-framework-template`. PR-gating deferred until baseline backfill is complete. |
| Release evidence | `release.yaml` `evidence` job | Release | Bundle + SBOM + attestations attached to the GitHub release. |

## Where `continue-on-error` is allowed

`continue-on-error: true` is reserved for steps whose **publishing channel** is
best-effort, not for the gate logic itself. For example, SARIF upload steps in
the called security reusable may be advisory (the scan still fails the job; only
the Security-tab upload is best-effort). This repository does not add
`continue-on-error` to any gate that would otherwise block a PR.

## Repo-hygiene policy (planned)

The universal `repo_hygiene` policy (SHA-pinned `uses:`, exact terraform/provider
pins, `pull_request_target` boundary safety) is enforced by a planned
`repo-hygiene.yaml` caller of the framework template's
`reusable-repo-hygiene.yaml`. Until that caller lands, those invariants are
enforced by review plus the zizmor (`security.yaml`) and Renovate pin discipline.

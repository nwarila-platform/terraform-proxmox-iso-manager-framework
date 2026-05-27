# Quality Gates

Each automated check enforced by this repository plays one of four roles. The
role determines *when* the check runs and *what failure means*.

| Role | Meaning | When it runs |
| --- | --- | --- |
| **Blocking** | Required for PR merge to `main`. Failure blocks the PR. | `pull_request` / `merge_group` triggers in `ci.yaml`, `drift-gate.yaml`, `security.yaml` |
| **Scheduled** | Periodic posture telemetry. Runs on a cron; does **not** block PRs. | `schedule` trigger in `security.yaml` |
| **Release** | Runs at release-cut time. Failure blocks the release tag and prevents the evidence bundle from being attached. | `release.yaml` and the reusables it calls |
| **Advisory** | Surfaces signal without blocking. Reserved for steps whose *publishing channel* is best-effort, or where the gate is explicitly opt-in. | Specific steps marked `continue-on-error: true` (see below) |

For the canonical list of required PR checks see
[release-gates.md](release-gates.md). This document classifies each gate's
role and explains the few places where `continue-on-error` is allowed.

## Gate inventory

| Gate | Source | Role | Notes |
| --- | --- | --- | --- |
| actionlint | `ci.yaml` job `actionlint` | Blocking | Workflow YAML/expression validation. |
| workflow-helper-tests | `ci.yaml` job `workflow-helper-tests` | Blocking | ShellCheck on `tools/ci/*.sh`, Python input-binding checks, Bats coverage. |
| terraform verify (`verify.py verify`) | `ci.yaml` job `terraform-ci` | Blocking | Wraps fmt, init, validate, tflint, `terraform test`, OPA (test + source + plan), `privileged-workflows`, docs-diff, docs-layout, ADR schema, manifest, integration. |
| privileged-workflows | `verify.py ci` (via `verify.py verify`) | Blocking | `check_privileged_workflows.py` + fixture-driven test runner. Rejects `actions/checkout` and PR-controlled refs in any `pull_request_target` workflow, transitively through local reusables. |
| markdownlint | `ci.yaml` job `markdownlint` | Blocking | Docs hygiene. |
| drift-gate | `drift-gate.yaml` | Blocking | Verifies the org-baseline overlay matches `NWarila/.github` at the pinned source ref. |
| Trivy IaC misconfig + secrets | `security.yaml` -> `reusable-iac-security.yaml` (PR path) | Blocking | Trivy scan exit status is the gate; SARIF upload is advisory (see below). |
| Gitleaks | `security.yaml` -> `reusable-iac-security.yaml` | Blocking by default | Caller-configurable via `inputs.gitleaks_advisory`; advisory mode is opt-in per consumer. |
| zizmor (Actions posture) | `security.yaml` -> `reusable-iac-security.yaml` | Blocking | zizmor exit status is the gate; SARIF upload is advisory. |
| CodeQL | `security.yaml` -> `reusable-codeql.yaml` | Blocking | Static analysis. SARIF upload is advisory. |
| OpenSSF Scorecard | `security.yaml` -> `reusable-scorecard.yaml` | Scheduled / push / branch protection / manual; skipped on PR and merge queue | Posture telemetry; skipped on PR paths because Scorecard GraphQL is gated on private repos. |
| Release evidence + SBOM + attestations | `release.yaml` -> `reusable-release-evidence.yaml` | Release | Produces evidence bundle, SPDX SBOM, attestations for both. Failure prevents release assets from being attached. |
| Auto-merge (trusted bots) | `auto-merge.yaml` -> `reusable-auto-merge.yaml` | Not a gate | Operates on `pull_request_target` with no PR checkout; must keep passing `privileged-workflows`. |

## When `continue-on-error: true` is allowed

The repository deliberately limits this flag to three narrow contexts.
Anywhere else, it would mask a gate's failure and should be removed.

1. **SARIF upload to GitHub Security** (`reusable-iac-security.yaml`,
   `reusable-codeql.yaml`, `reusable-scorecard.yaml`) -- the *scan* is the
   gate and runs without `continue-on-error`. The upload step is
   best-effort because publishing to the Security tab requires GitHub
   Advanced Security on private repos. Findings remain visible in the run
   log and as workflow artifacts.
2. **Scorecard analysis on private repos** (`reusable-scorecard.yaml`) --
   Scorecard's GraphQL queries fail with *Resource not accessible by
   integration* on private repositories; granting access requires a PAT,
   which conflicts with the no-shared-secrets policy. The run log retains
   the warning.
3. **Gitleaks advisory mode** (`reusable-iac-security.yaml`) -- caller-
   parameterised via `inputs.gitleaks_advisory`. Lets consumers adopt
   Gitleaks while triaging historical findings, then flip the input to
   default-blocking once clean.

## Adding a new gate

1. Decide its role from the taxonomy above.
2. If the gate is reproducible locally, wire it through `tools/verify.py`
   so contributors can run it before pushing.
3. Add a row to the inventory table.
4. If blocking, ensure it appears in the repository's required status
   checks (branch protection on `main`).
5. Do not add `continue-on-error: true` outside the three contexts listed
   above without an explicit rationale in the workflow file.

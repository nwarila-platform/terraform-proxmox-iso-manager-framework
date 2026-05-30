# Production Readiness Handoff

> Archived snapshot: this document records a 2026-05-27 handoff from before
> the workflow migration landed. It is retained for history, but current repo
> state comes from the live workflows and the docs updated after that migration.

Date: 2026-05-27

## Snapshot

- Repository: `nwarila-platform/terraform-proxmox-iso-manager-framework`
- Branch: `feat/packer-boot-iso-contract`
- HEAD: `45fbf935ced0774acfada2055c945d1d33d2ebbf` (uncommitted edits on top)
- `origin/main`: `fe8b92f68b09259f21633c7cbee7b765b08748d3`
- Branch relation: ahead 9, behind 1
- Open PRs: none.
- Local HEAD is not visible to GitHub; no workflow runs or combined status
  checks exist for this exact SHA.
- Worktree remains dirty from prior sessions. This session preserved existing
  dirty work and only changed `.github/workflows/template-sync.yaml` plus
  this handoff.

## Audited

- Local git status, branch, remotes, recent commits, diff stat, workflow
  files, docs, Terraform pins, OPA policy, Renovate config, and the
  `NWarila/terraform-framework-template` baseline manifest at its current
  `main` SHA `c885df7bd5cf9d1d5a4b3aabe1b1b9ced10e63b0` (2026-05-26).
- Recent GitHub Actions on `main` via `gh run list --limit 12`. The release
  commit `fe8b92f` has Repo CI and Release Please green; `codeql.yaml`,
  `security.yaml`, `scorecard.yaml` failed at 0 seconds (retired caller);
  most recent `template-sync.yaml` run also failed instantly for the same
  reason.
- Confirmed via `gh api repos/NWarila/terraform-template` that the retired
  template repo returns HTTP 404.
- Confirmed via `gh api repos/NWarila/terraform-framework-template/contents`
  that the canonical template publishes a `baseline-manifest.json` (63
  byte-identical entries) and a `drift-gate.yaml` workflow that consumes
  it via the `NWarila/drift-gate` composite action.
- Confirmed via `gh api repos/NWarila/drift-gate` that the action exists.
  Current `main` HEAD is `dd091e7d730b2711e09bf86c8d66b7e9b873dd53`
  (2026-05-26). Action inputs read: `source-repo`, `source-ref`, `manifest`,
  `consumer-ref`, `check-name`, `github-token`. Requires `checks: write`
  to post per-file annotations.
- Cross-referenced `baseline-manifest.json` against the local working tree:
  17 of 63 byte-identical files are present locally, 46 are missing. The
  46-file gap is real fleet backfill scope, not a single-session task.

## Selected Problem

`.github/workflows/template-sync.yaml` was the last workflow on `main`
still calling the retired `NWarila/terraform-template` reusable target.
Every scheduled invocation failed at 0 seconds, and the locally-staged
fixes for `codeql.yaml`, `security.yaml`, and `scorecard.yaml` (already
migrated to `NWarila/terraform-framework-template@c885df7b...`) had no
matching update for template-sync.

## Changed

- `.github/workflows/template-sync.yaml`
  - Removed the dead reusable-workflow caller
    (`NWarila/terraform-template/.github/workflows/reusable-template-sync.yaml`).
  - Replaced with the canonical `NWarila/drift-gate@dd091e7d...` composite
    action, pointed at `NWarila/terraform-framework-template@c885df7b...`
    with `manifest: baseline-manifest.json`. Same pattern as the framework
    template's own `drift-gate.yaml`.
  - Trigger reduced from daily cron + `contents: write` /
    `pull-requests: write` to weekly cron + `workflow_dispatch` only with
    `contents: read` + `checks: write`. The action does not open PRs; it
    posts a check-run with per-file drift annotations.
  - `pull_request` trigger intentionally deferred: 46 of 63 baseline files
    are not yet mirrored locally, so PR-gating would currently make every
    PR red on a known backfill. Add `pull_request` after the backfill.
  - Renovate annotations added so both pins (drift-gate SHA and
    framework-template `source-ref`) update automatically. The existing
    `NWarila/terraform-framework-template` rule in `.github/renovate.json5`
    already groups the source-ref bumps.
- `docs/reference/production-readiness-handoff.md`
  - Replaced previous session's notes with this current handoff.

## Verification

Passed:

- `gh api` against `NWarila/terraform-template` (confirmed 404),
  `NWarila/terraform-framework-template/{contents,commits/main}`,
  `NWarila/terraform-framework-template/contents/baseline-manifest.json`
  (decoded and inspected), `NWarila/drift-gate/{,commits/main}`, and
  `NWarila/drift-gate/contents/action.yml` (interface confirmed).
- `gh run list -R nwarila-platform/terraform-proxmox-iso-manager-framework
  --limit 12` confirmed the failing-workflow set on `main`.
- Python/PyYAML parse of `.github/workflows/template-sync.yaml`:
  `triggers: ['schedule', 'workflow_dispatch']`, `jobs: ['baseline']`.
- `grep` for `NWarila/terraform-template` across the repo: no remaining
  references in `.github/workflows/`. Remaining references are in
  `docs/decision-records/repo/0004-consume-terraform-template.md`
  (untracked, codifies the retired standard - do not stage as-is) and
  this handoff (retrospective).
- `terraform -chdir=terraform fmt -check -recursive`: clean.

Unavailable locally:

- `terraform -chdir=terraform validate` blocked: local CLI is 1.14.3 but
  `versions.tf` pins `= 1.15.2`. Prior session noted this same gap and
  used an escalated environment to satisfy 1.15.2. This session's edit
  is workflow-only and touches no `.tf` files, so the validate gap does
  not gate this change.
- `tflint`, `terraform-docs`, `opa`, `actionlint` not installed locally.
- `python3` not present (the Makefile default); `python` is available
  as Python 3.14.3.

Not run locally for the same tooling reasons: full `make ci`, `tflint`,
`terraform-docs --output-check`, OPA tests, actionlint.

## Known Remaining Problems

- **Baseline-manifest backfill**: 46 of 63 byte-identical entries from
  `NWarila/terraform-framework-template@c885df7b...` are missing locally.
  Categorised:
  - 7 `reusable-*.yaml` workflows - this consumer calls them via `uses:`
    rather than mirroring; verify whether the canonical manifest expects
    consumer mirroring or whether the template should mark these as
    template-only.
  - `tools/` and `tools/ci/` (~10 files including `build_opa_input.py`,
    `verify.py`, `apply_overlay.sh`, integration runners).
  - `tests/ci/*.bats` and `tests/fixtures/privileged-workflows/*` test
    harness.
  - `policies/opa/{repo_hygiene,terraform_plan}.rego` plus tests.
  - `docs/{tutorials,how-to,reference,explanation}/.gitkeep`,
    `docs/decision-records/{template,repo}/.gitkeep`, and the
    `docs/decision-records/template/*.md` set.
  - `docs/reference/{mirroring,quality-gates,runner-protocol}.md`.
  - `fixtures/integration/basic/README.md`.
  The new `template-sync.yaml` will surface this list weekly and on
  `workflow_dispatch`. PR-gating should be enabled only after backfill.
- `policies/opa/iso_manager.rego` still requires deleted/renamed workflow
  names (`release-evidence.yml`, `graph-regression.yml`). Its tests mirror
  the stale names. `opa test` is not installed locally so this drift is
  uncaught even by the existing policy suite.
- Some docs still reference older workflow names such as `repo-ci.yml`,
  `release-evidence.yml`, and `graph-regression.yml`. This session fixed
  only the template-sync references; the org-adr-sync session before it
  fixed the org-baseline references; the remainder are open.
- `docs/decision-records/repo/0004-consume-terraform-template.md` is
  untracked and still codifies the retired `NWarila/terraform-template`
  standard including a link to the removed org ADR-0005. Do not stage
  as-is; needs rewrite to reflect `NWarila/terraform-framework-template`
  consumption.
- `.github/workflows/auto-merge.yaml` comment still lists `template-sync`
  as a trusted bot. The new template-sync does not open PRs, so the
  trusted-bot list could be tightened; functional impact is nil because
  the reusable-auto-merge gates on PR author, not workflow name.
- Branch is behind `origin/main` by the release `1.2.0` commit.
- Local branch has not been pushed; remote CI has not validated this
  session's change.
- Worktree remains dirty across 33 files from prior sessions. The
  workflow fixes for codeql/scorecard/security and the new
  org-adr-sync.yaml verifier are validated locally but not yet committed.
  Until those land, `main` continues to show those workflows red.

## Recommended Next Smallest Task

Open a PR for the workflow-fix bundle that is already validated locally
but uncommitted: `codeql.yaml`, `scorecard.yaml`, `security.yaml`,
`org-adr-sync.yaml` (and now `template-sync.yaml`). All four point at
either the canonical `NWarila/terraform-framework-template@c885df7b...`
or canonical drift-gate/self-contained verifier patterns. Landing them
clears the four guaranteed-red workflows on `main` and unblocks honest
PR signal for the larger baseline-manifest backfill that follows.

Avoid bundling the staged docs/ADR edits, the unfinished
`0004-consume-terraform-template.md`, or any of the terraform/test
fixture changes in the same PR - those are separate concerns and would
inflate review scope.

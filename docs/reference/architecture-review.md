# Architecture Review — Comprehensive Report

**Date**: 2026-05-27
**Author**: Claude (Opus 4.7) for @NWarila
**Audience**: Deep-Research review; external technical critique
**Repo under review**: `nwarila-platform/terraform-proxmox-iso-manager-framework`
**Related upstream**: `NWarila/terraform-framework-template`

---

## 0. Reading Notes for the Reviewer

This document is intentionally self-contained. You should be able to evaluate the design choices, the audit verdicts, and the execution plan without cloning the repos. Where a claim depends on a specific file's content I've quoted enough of it to make the claim checkable. Where I'm uncertain or where a decision is genuinely contested, I flag it explicitly — please push back hardest there.

The repo author is the same person who authored the upstream framework template; this is not a "consumer pushing back on a vendor" situation. The author wanted an outside critical pass and is the decision-maker.

I want you to:

1. **Stress-test the design principle** — is "consumers mirror what they run; the template keeps what only it runs" the right framing? What does it miss?
2. **Audit the audit** — for each of the 15 themes below, is the verdict correct? Are there alternatives I didn't consider?
3. **Critique the execution plan** — is the 8-stage order right? What dependencies did I miss?
4. **Find the silent failure modes** — what breaks 6 months from now that this plan doesn't anticipate?

---

## 1. The Ecosystem

### 1.1 Orgs and repos

There are two GitHub orgs in play:

- **`NWarila/`** (personal-style org) — owns the canonical framework templates and shared tooling.
  - `NWarila/.github` — org-level baseline manifest for all NWarila/ repos.
  - `NWarila/terraform-framework-template` — the canonical Terraform-framework template that derivative frameworks consume. *This is the upstream under review.*
  - `NWarila/terraform-runner-template` — separate template for runners (which call frameworks).
  - `NWarila/github-terraform-runner` — a runner instance.
  - `NWarila/drift-gate` — composite action used by every consumer's drift verification.

- **`nwarila-platform/`** (platform-style org) — owns the production consumers that depend on the framework templates.
  - `nwarila-platform/.github` — org-level baseline manifest for all nwarila-platform/ repos (separate from the NWarila/.github manifest above).
  - `nwarila-platform/terraform-proxmox-iso-manager-framework` — *the consumer under review*. A Terraform child module that manages Proxmox VE installer ISOs. Consumed by ~12 downstream Packer projects.

### 1.2 The layered baseline pattern

Each repo participates in a layered baseline:

```
NWarila/.github                    ← org baseline #1 (for NWarila/ repos)
nwarila-platform/.github           ← org baseline #2 (for nwarila-platform/ repos)
NWarila/terraform-framework-template  ← framework-tier baseline
   ↑ extends org baseline above
nwarila-platform/terraform-proxmox-iso-manager-framework  ← consumer
   ↑ extends framework-tier baseline above
   ↑ also mirrors from nwarila-platform/.github
```

Each "baseline" is a `baseline-manifest.json` enumerating files derivative repos must mirror byte-identically. Enforcement is via the `NWarila/drift-gate` composite action: a consumer workflow calls drift-gate with `source-repo`, `source-ref`, and `manifest` inputs; drift-gate fails CI if any manifest entry is missing or content-different.

### 1.3 The "secure standardized 90%" design intent

From the upstream author (the same person as the consumer author), in their own words:

> "The point of the template is to provide a secure, standardized, 90% starting point to allow developers to focus on their code development and less stress about design decisions or creating compliant repos."

Operationally this means:

- The template pre-decides **security baselines** (SHA-pinned actions, exact terraform pins, supply-chain quarantine, etc.).
- The template pre-decides **CI/CD plumbing** (reusable workflows, OPA policies, evidence bundles).
- A consumer's job is the remaining **~10%** — the actual Terraform module / domain code / examples — plus per-repo customizations (owner, dep groups, repo-specific docs).

The reviewer should challenge this framing if appropriate. In particular:

- Is "90/10" the right split for Terraform repos? Could the template be heavier (95/5) or lighter (75/25)?
- Is the "byte-identical mirror" mechanism the right enforcement tool? Alternatives include policy-as-code, composite-action-only delivery, or no enforcement at all.

---

## 2. The Problem We Identified

### 2.1 Starting state (before any work this session)

The consumer was on a feature branch with ~33 modified files representing a multi-session fleet-rollout effort. CI on `main` had four workflows failing at 0 seconds because they referenced a retired `NWarila/terraform-template` reusable target (HTTP 404). The replacement target is `NWarila/terraform-framework-template`.

Drift-gate was not yet running on the consumer. The consumer had no `template-sync.yaml` (or had a broken one — see below).

### 2.2 First-pass fixes (PRs #44, #45)

Two PRs (numbered in the consumer repo) shipped before the architectural question was raised:

- **PR #44** — Consolidated workflow rollout: every caller workflow repointed to `NWarila/terraform-framework-template@c885df7b...`. Replaced the dead `template-sync.yaml` with a `NWarila/drift-gate` caller. Replaced the dead `org-adr-sync.yaml` with a self-contained Python verifier.

- **PR #45** — Post-rollout fix-ups exposed by PR #44's CI: a zizmor suppression for `pull_request_target` on `auto-merge.yaml`, terraform-docs regeneration for v0.23.0, stale workflow refs in OPA policy + docs, and a rewrite of `0004-consume-terraform-template.md` ADR for current mechanics.

After PR #45, CI on `main` was green except for `template-sync.yaml` which (correctly) reported drift: **46 of 63** framework-manifest `byte_identical` entries were missing locally.

### 2.3 The architectural question

The next move would have been to mirror all 46 missing files into the consumer. PR #46 attempted exactly that — pulled all 46 from `NWarila/terraform-framework-template@c885df7b` and committed them.

The author then asked: "Why are we copying all the terraform-framework files from nwarila, instead of defining a live terraform-runner?"

That question reframed the work. The 46 files included:

- 7 reusable workflow files (`reusable-*.yaml`) that consumers reach via cross-repo `uses:` — never invoked from a consumer-local file.
- ~10 helper Python/shell scripts under `tools/` — invoked only by the template's own `make ci` for self-validation.
- 4 bats test files under `tests/ci/` — testing the template's `tools/`.
- 4 privileged-workflow security fixtures under `tests/fixtures/privileged-workflows/` — inputs for the template's own checks.
- 4 universal OPA policies under `policies/opa/repo_hygiene*.rego`, `terraform_plan*.rego` — invoked only by the template's own `tools/verify.py`.
- 4 template-tier ADRs.
- A handful of `.gitkeep` markers and reference docs.

None of these files are invoked by anything in a consumer's production lifecycle. Carrying byte-identical local copies is dead weight — pure mirror that exists only to satisfy drift-gate, not to enable any consumer behavior.

PR #46 was closed without merging. The fix moved upstream.

### 2.4 The upstream fix (PR #18)

[NWarila/terraform-framework-template#18](https://github.com/NWarila/terraform-framework-template/pull/18) — *Already merged at SHA `dbf38381...`* — slimmed `baseline-manifest.json` from **63 → 11 `byte_identical` + 9 `scaffold_starter`** entries.

Changes:

- **Removed 12 org-baseline duplicates** — `LICENSE`, 7 Diataxis `.gitkeep` markers, 2 ADR-tier `.gitkeep` markers, 5 reusable workflows. The org's `NWarila/.github/baseline-manifest.json` already enumerates these; double-listing created two sources of truth.

- **Removed ~30 template-internal entries** — all `tools/*.py` and `tools/ci/*` (helper scripts; only invoked from template's own `make ci`), all `tests/ci/*.bats` (test the tools), all `tests/fixtures/privileged-workflows/*` (inputs for the tools), all `policies/opa/repo_hygiene*.rego` and `terraform_plan*.rego` (universal policies the template runs against itself), all `docs/decision-records/template/*` (template's own ADRs, readable on github.com), 2 remaining reusable workflows (`reusable-release-evidence`, `reusable-terraform-deploy`).

- **Moved 5 to `scaffold_starter`** — `Makefile`, `.gitignore`, `.github/CODEOWNERS`, `.github/renovate.json5`, `.github/PULL_REQUEST_TEMPLATE.md`. These are per-consumer customizable; drift-gate documents but does not byte-compare them.

- **Moved 3 more to `scaffold_starter`** in a follow-up commit — `docs/reference/invariants.md`, `quality-gates.md`, `release-gates.md`. All three reference template-specific workflow names (`ci.yaml`, `drift-gate.yaml`, `release.yaml`) and the template's synthetic-provider examples; consumers legitimately need to customize.

- **Updated `tools/check_baseline_manifest.py`** — dropped the `--check-present-sources` flag and the unconditional unlisted-template-ADR check. Both were the inverse of the new principle: they enforced "every template-internal file must be mirrored to consumers." The remaining checks still keep the manifest honest.

- **Documented the design principle** in `docs/reference/mirroring.md` with a heuristic for future additions: *"Does a consumer invoke this file in its own production lifecycle?"*

The final `byte_identical` set is 11 entries:

```
.editorconfig
.gitattributes
.markdownlint-cli2.jsonc
.pre-commit-config.yaml
.terraform-docs.yml
.tflint.hcl
.github/workflows/security.yaml
docs/reference/mirroring.md
docs/reference/runner-protocol.md
tools/check_docs_layout.py
tools/install_ci_tools.sh
```

The `scaffold_starter` set is 9 entries:

```
.gitignore
.github/CODEOWNERS
.github/PULL_REQUEST_TEMPLATE.md
.github/renovate.json5
Makefile
baseline-manifest.json
docs/reference/invariants.md
docs/reference/quality-gates.md
docs/reference/release-gates.md
```

### 2.5 The consumer-side resync (PR #47)

[nwarila-platform/terraform-proxmox-iso-manager-framework#47](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/pull/47) — *Open, all 12 CI checks green, awaiting merge authorization* — bumped `template-sync.yaml`'s SHA pin to `dbf38381` and synced 9 of the 11 byte_identical entries to canonical content (2 missing + 7 divergent).

The remaining divergence is `.github/workflows/security.yaml`. The canonical content uses local-relative paths (`uses: ./.github/workflows/reusable-iac-security.yaml`) which don't exist in the consumer, and bundles three jobs (iac, codeql, scorecard) into one workflow while the consumer ships them as three separate workflows for separate badges, schedules, and code-owner routing.

That divergence is tracked as [upstream issue #19](https://github.com/NWarila/terraform-framework-template/issues/19) — the proposed fix is to move `security.yaml` to `scaffold_starter` (it's a per-consumer caller, not a content-canonical workflow).

After PR #47 merges, the consumer satisfies 10 of 11 byte_identical entries (only security.yaml remains divergent, by design, pending issue #19).

### 2.6 The OPA wiring question

A subsequent question from the author surfaced a related issue: should the universal OPA policies (`repo_hygiene.rego`, `terraform_plan.rego`) — now template-only per the slim manifest — actually run against the consumer's repo state?

- `repo_hygiene.rego` enforces SHA-pinning, exact terraform pins, pull_request_target safety, and a few other universal hygiene rules. **Applicable** to the consumer.
- `terraform_plan.rego` enforces AWS-specific resource invariants (tags, admin ports, IAM wildcards). **Not applicable** — consumer uses `bpg/proxmox`, no AWS resources.

The chosen wiring is a new upstream reusable workflow (`reusable-repo-hygiene.yaml`) that does cross-repo checkout of the framework, builds OPA input via `tools/build_opa_input.py`, and runs `opa eval` against `policies/opa/repo_hygiene.rego`. Consumers add a thin caller that `uses:` the reusable. **Not yet implemented.**

---

## 3. The File-by-File Audit

Authored as `docs/reference/file-audit.md` in this repo. 88 tracked files audited.

### 3.1 Audit framing

For each tracked file: is this template-owned 90% (canonical mirror), consumer-owned 10% (domain), starter (per-repo customizable), or misplaced (in wrong layer)?

### 3.2 Distribution

| Verdict | Count |
|---|---|
| KEEP as-is | 70 |
| DELETE | 9 |
| RENAME | 1 |
| REFACTOR | 3 |
| SYNC | 1 |
| CUSTOMIZE | 1 |
| ADD | 1 |
| Makefile cleanup (follows A) | 1 |
| Upstream PRs needed | 3 |
| Resolved/N-A | 1 |

### 3.3 Decisions by theme

All 15 themes have been decided. Verdicts shown alongside the consequence:

| Theme | File(s) | Verdict | Rationale | Risk |
|---|---|---|---|---|
| **A** | `tools/render_graphs.sh`, `tf_graph_cycles.py`, `tf_graph_summary.py`, `docs/how-to/generate-terraform-graphs.md`, `docs/reference/graph-artifacts.md`, `docs/reference/graphs/*`, `docs/explanation/dependency-graph-validation.md`, `examples/failure-cases/dependency-cycle/*` | **DELETE** | Graph-regression CI workflow already deleted in `f3eba02`. Local `make graph` target survives but no consumer of the module needs graph artifacts. ~10 files of dead weight. | Low. Loss of local-dev graph visualization. Reversible (in git history). |
| **B** | `tools/generate_release_evidence.sh` | **DELETE** | Canonical `reusable-release-evidence` supersedes. Verify no `Makefile`/workflow/doc references before delete. | Low. |
| **C** | `.github/workflows/pr-validation.yaml` | **RENAME → ci.yaml** | Canonical template name is `ci.yaml`. Functionally identical (runs `make ci`). Aligns with fleet standardization. | Medium. Branch-protection rule UI update needed. Required-check name change is visible. |
| **D** | `.github/workflows/release-please.yaml`, `release-evidence.yaml` | **REFACTOR → release.yaml** | Canonical `reusable-release-please` dispatches `release.yaml` with `task` workflow_dispatch input. Consumer currently runs `release-please-action` natively then explicitly dispatches `release-evidence.yaml`. Refactor consolidates and aligns. | High. Complex refactor; release pipeline is load-bearing. |
| **E** | `.github/workflows/org-adr-sync.yaml` | **UPSTREAM PR + consumer caller** | Currently ~80 lines of embedded Python verifier in the consumer's workflow. Should be a thin caller for a new upstream `reusable-org-adr-sync.yaml`. Every fleet consumer benefits. | Low. Existing self-contained version stays working until swap. |
| **F** | `.github/renovate.json5` | **REFACTOR to `extends:`** | Canonical doc says "consumers extend it via `extends:`" but the consumer currently duplicates. DRY. Less drift over time. | Medium. Behavior change in Renovate; needs careful PR review. |
| **G** | `.github/PULL_REQUEST_TEMPLATE.md` | **SYNC** to canonical | Trivial divergence. No domain content in the consumer's version that justifies the diff. | Trivial. |
| **H** | `docs/reference/invariants.md` | **CUSTOMIZE** for ISO domain | Canonical mixes universal lines (SHA-pinning, exact pins) with template-test-specific lines (synthetic providers, multi-env). Keep universal; drop template-test-specific; add ISO-specific invariants. | Low. |
| **I** | `docs/reference/quality-gates.md` | **ADD** customized copy | Consumer doesn't have one. Canonical is in scaffold_starter. Add a copy mapping the canonical gate-role taxonomy onto the consumer's actual workflow names. | Low. |
| **J** | `docs/reference/golden-template-contract.md` | **DELETE** | Pre-dates the slim manifest. Superseded by `mirroring.md` (now canonical and mirrored). Two docs with overlapping content. | Low. |
| **K** | `.template-type` (silent dependency on the canonical reusable-release-evidence) | **UPSTREAM PR** | File exists locally (`framework`). Read by `reusable-release-evidence` to gate framework-vs-runner behavior. Not in any manifest. Should be added to `byte_identical`. | Low. Already-present in every consumer; just formalizes the implicit dependency. |
| **L** | `policies/exceptions/README.md` | **KEEP** | 13-line process placeholder. Cheap insurance. | None. |
| **M** | `Makefile` | **CLEANUP** (follows A) | Remove the `graph:` target once Theme A deletes `tools/render_graphs.sh`. | Trivial. |
| **N** | `docs/decision-records/repo/0002-use-repo-local-renovate-baseline.md` | **REWRITE** (follows F) | ADR currently records the duplicate choice; needs rewrite to record the new `extends:` choice. | Trivial. |
| **O** | (org-baseline 0005) | **RESOLVED — N/A** | I initially flagged a missing ADR-0005. The consumer's org (`nwarila-platform/.github`) only publishes 4 ADRs (0001-0004); 0005 only exists in the *other* org (`NWarila/.github`) which doesn't apply to this consumer. No drift. | None. |
| **OPA-wiring** | new `.github/workflows/repo-hygiene.yaml` caller | **UPSTREAM PR + consumer caller** | Publish `reusable-repo-hygiene.yaml` upstream; consumer adds caller. `terraform_plan.rego` skipped (AWS-only). | Medium. New CI gate may surface findings on first run. |

---

## 4. Open Decisions / Reviewer Pushback Welcome

Areas where I want Deep Research's strongest critique:

### 4.1 Is "byte_identical mirror" the right enforcement tool at all?

The current pattern is:

1. Template publishes `baseline-manifest.json` enumerating files.
2. Consumer mirrors each file byte-identically.
3. Consumer's `template-sync.yaml` runs `NWarila/drift-gate` to enforce.

This works but has properties worth challenging:

- **Cost**: each consumer carries N file copies. After the slim, N=11 — small. But every fleet-wide change to those 11 requires N consumer PRs (Renovate-driven).
- **Trust**: byte-identity assumes consumers don't have a *good* reason to diverge. The 8 themes we moved to `scaffold_starter` are evidence that the boundary is fuzzy.
- **Alternatives not seriously considered**:
  - **Policy-as-code only**: drop the mirror; have a composite action evaluate consumer state at PR time and fail on policy violations. No file mirror.
  - **Composite-action delivery**: package the canonical content as a composite action that *generates* the local files. Consumer adds the action; files appear in CI but aren't committed.
  - **OPA bundles served from the template**: OPA's bundle service feature; runtime fetch, no commit.

For the reviewer: which alternative deserves deeper exploration?

### 4.2 The `security.yaml` problem (issue #19)

Canonical bundles iac + codeql + scorecard into a single `security.yaml`. Consumer splits them into three. Both designs are reasonable. The current proposal is to move `security.yaml` to `scaffold_starter` (don't enforce content). But a stronger argument might be:

- The "secure standardized 90%" principle says security plumbing should be standardized.
- Consumers diverging on security workflow shape is a bug, not a feature.
- The right fix is to **make consumers adopt the canonical** (single bundled workflow) rather than ratify the divergence by moving it to scaffold_starter.

Counter-argument: consumer-side splits enable separate badges, schedules, ownership — practical benefits with no security loss (the underlying reusables run the same code).

What's the right call?

### 4.3 Theme D — release pipeline refactor risk

Refactoring `release-please.yaml` + `release-evidence.yaml` → single `release.yaml` with task dispatch is the **highest-risk** item in the plan. The release pipeline is load-bearing:

- Wrong refactor = no releases for the consumer's downstream Packer projects.
- The native `release-please-action` consumer uses today *works*.
- The canonical pattern's task-dispatch design has nuances (GITHUB_TOKEN cascade restrictions, `workflow_dispatch` ref handling) that we'd need to test thoroughly.

The alternative is **keep the consumer's split** and accept the divergence. Is this divergence worth eliminating?

### 4.4 Theme F — renovate `extends:` pattern

Switching to `extends:` removes the duplicated dep groups but introduces a runtime dependency on the canonical's GitHub-served raw content. Has anyone actually tested whether `"extends": ["github>NWarila/terraform-framework-template//.github/renovate.json5"]` works against a SHA-pinned base? Renovate's `extends` docs are not unambiguous on this — it may require `@<branch>` or `@<sha>` suffix, and the SHA-pin discipline (which the slim manifest preserves elsewhere) may not extend cleanly.

I haven't verified this experimentally. The reviewer should challenge whether the recommended approach actually works.

### 4.5 Coverage gaps I haven't addressed

- **No security review of the cross-repo `actions/checkout` pattern** I'm proposing for OPA wiring (and reusable-org-adr-sync). The framework template is public, but a malicious upstream commit could inject arbitrary code that runs in the consumer's CI context. Drift-gate's SHA-pin discipline mitigates this *if* renovate auto-merge is conservative. Worth a dedicated threat-model pass.
- **No fleet-wide impact assessment**. There are ~12 downstream Packer projects that depend on this consumer's outputs. The Packer contract changed earlier this session (PR #44 series moved from flat `iso_file` / `iso_checksum` to object-shaped `boot_iso` / `additional_iso_files` pkrvars). I haven't verified that every downstream project has migrated.
- **No SBOM/provenance verification**. The canonical reusable-release-evidence generates SBOM + attestations. I haven't confirmed the consumer's release evidence actually carries provenance that survives a `gh attestation verify` check.

---

## 5. Execution Plan (For Critique)

Eight stages. Sequenced for minimum review burden. Each stage is one PR (except stage 2 which is three parallel PRs).

### Stage 1 — Merge PR #47

Already green. Awaiting authorization. Unrelated to audit but blocks rebase pain.

### Stage 2 — Three upstream PRs in parallel against `NWarila/terraform-framework-template`

1. **`reusable-org-adr-sync.yaml`** — wraps the consumer's current self-contained Python verifier as a reusable. Inputs: `org_baseline_repo`, `org_baseline_ref`. ~80 lines of YAML; same code path.
2. **Add `.template-type` to `baseline-manifest.json` byte_identical** — formalizes the silent dependency `reusable-release-evidence` has on this file.
3. **`reusable-repo-hygiene.yaml`** — cross-repo checkout of framework, runs `tools/build_opa_input.py` then `opa eval data.repo_hygiene.deny[_]` against `policies/opa/repo_hygiene.rego`. ~40 lines.

### Stage 3 — Consumer cleanup PR (deletes)

- Delete Theme A graph subsystem (~10 files).
- Delete Theme B `tools/generate_release_evidence.sh` (verify no refs first).
- Delete Theme J `docs/reference/golden-template-contract.md`.
- Theme M Makefile cleanup (drop `graph:` target).
- Update `.gitignore` allowlist (drop deleted entries).

### Stage 4 — Consumer config standardization PR

- Theme F: `renovate.json5` → `extends:` pattern. *Requires verification that this works.*
- Theme N: rewrite ADR-0002 to record the new choice.
- Theme G: sync `.github/PULL_REQUEST_TEMPLATE.md` to canonical.

### Stage 5 — Consumer workflow architecture PR

- Theme C: rename `pr-validation.yaml` → `ci.yaml`.
- Theme D: consolidate `release-please.yaml` + `release-evidence.yaml` → single `release.yaml` with task dispatch.
- Branch-protection UI update (manual, not in PR).
- **Highest-risk stage.** Consider splitting C and D into separate PRs.

### Stage 6 — Consumer docs PR

- Theme H: customize `invariants.md` for ISO domain.
- Theme I: add `quality-gates.md` customized copy.

### Stage 7 — Wire upstream reusables into consumer

After Stage 2 PRs merge:

- Swap `org-adr-sync.yaml` from self-contained verifier to caller of new `reusable-org-adr-sync.yaml`.
- Add `.template-type` byte_identical (file already exists; just track in CI).
- Add new caller workflow for `reusable-repo-hygiene.yaml`.
- Bump `template-sync.yaml` SHA pin to pick up the new manifest entries.

### Stage 8 — Resolve upstream issue #19

Decide on `security.yaml` design — adopt canonical (single bundled workflow) or move to `scaffold_starter` (ratify split).

---

## 6. State Snapshot (For Reproducibility)

### 6.1 Consumer repo state

- Branch: `chore/resync-slim-manifest` (PR #47, green, awaiting merge)
- HEAD: `9a41e93` (audit-time)
- Files tracked: 88

### 6.2 Upstream framework template state

- `main` HEAD: `dbf38381` (after PR #18 merged)
- `baseline-manifest.json`: 11 byte_identical + 9 scaffold_starter

### 6.3 Org baseline state

- `nwarila-platform/.github` HEAD at last verification: `8e890d1f...`
- `NWarila/.github` HEAD: not directly inspected (consumer doesn't mirror from this org)

### 6.4 Composite action state

- `NWarila/drift-gate` HEAD: `dd091e7d...` (action.yml inputs: source-repo, source-ref, manifest, consumer-ref, check-name, github-token)

---

## 7. Specific Questions For Deep Research

If you do nothing else, please answer these:

1. **Is the slim manifest the right ceiling?** Could `byte_identical` go even smaller (e.g., 6 entries) by accepting that `.gitattributes` and `.pre-commit-config.yaml` are local-dev-only and don't need fleet enforcement?

2. **Is `scaffold_starter` the right intermediate category, or should we just remove starter entries from the manifest entirely?** The current semantic ("documented but not byte-compared") is subtle and may be a footgun.

3. **For the cross-repo OPA pattern (Stage 2 PR 3)**: is `actions/checkout` of the framework at a SHA pin sufficient supply-chain control, or do we need additional verification (e.g., signed commits, attestation verification before `opa eval`)?

4. **Theme D (release pipeline refactor)**: is the canonical task-dispatch pattern actually better than the consumer's native `release-please-action` + explicit evidence dispatch? Concrete bug or just consistency?

5. **Theme F (renovate `extends:`)**: does this work with SHA pinning of the extended base, and if not, what's the right way to get DRY without losing pin discipline?

6. **What's the one thing in this plan that's most likely to bite us in 6 months that I haven't called out?**

---

## 8. Appendix: Key Files Referenced

For quick context if you want to read source:

- This consumer's audit doc: [`docs/reference/file-audit.md`](file-audit.md)
- This consumer's session handoff: [`docs/reference/production-readiness-handoff.md`](production-readiness-handoff.md)
- Canonical manifest contract: [`docs/reference/mirroring.md`](mirroring.md) (newly added in PR #47, sourced from upstream)
- Canonical runner protocol: [`docs/reference/runner-protocol.md`](runner-protocol.md) (same)
- Consumer's drift-gate caller: [`.github/workflows/template-sync.yaml`](../../.github/workflows/template-sync.yaml)
- Consumer's org-adr-sync (the self-contained verifier slated for refactor): [`.github/workflows/org-adr-sync.yaml`](../../.github/workflows/org-adr-sync.yaml)
- Consumer's domain policy: [`policies/opa/iso_manager.rego`](../../policies/opa/iso_manager.rego)
- The actual Terraform module: [`terraform/resources.tf`](../../terraform/resources.tf)

End of report.

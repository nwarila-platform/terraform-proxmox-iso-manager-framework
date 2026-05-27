# File-by-File Adversarial Audit

Date: 2026-05-27
Repo: `nwarila-platform/terraform-proxmox-iso-manager-framework`
Tracked files: 88

## Framing

The framework template's job is to provide a **secure, standardized 90%
starting point** so developers focus on their domain code (the remaining 10%)
without re-deciding compliance or infrastructure plumbing. Every file in this
consumer is therefore one of:

- **Template-owned 90%** — canonical content the consumer mirrors or
  consumes via `uses:`/checkout. Drift-gate enforces.
- **Consumer-owned 10%** — domain-specific to ISO management. Consumer owns.
- **Starter** — consumer keeps but customizes per-repo. drift-gate documents
  but doesn't byte-compare.
- **Misplaced** — currently in this consumer but belongs upstream, or vice
  versa.

The audit reads each tracked file through this lens and assigns a verdict:
**KEEP** (correct as-is), **SYNC** (drift to canonical), **MOVE**
(scaffold_starter or upstream), **DELETE** (dead weight),
**REFACTOR** (needs restructure).

## Summary

| Verdict | Count | Notes |
|---|---|---|
| KEEP as-is | 70 | Already correct or already addressed in PRs #44, #45, #47 |
| DELETE | 9 | Graph subsystem (Theme A, 7 files) + generate_release_evidence (B, 1) + golden-template-contract (J, 1) |
| RENAME | 1 | pr-validation.yaml → ci.yaml (Theme C) |
| REFACTOR | 3 | release-please + release-evidence → release.yaml (D); renovate.json5 → extends (F); ADR-0002 rewrite (N) |
| SYNC | 1 | PR template to canonical (G) |
| CUSTOMIZE | 1 | invariants.md for ISO domain (H) |
| ADD | 1 | quality-gates.md customized copy (I) |
| Makefile cleanup | 1 | Remove graph targets (M, follows A) |
| Upstream PRs needed | 3 | reusable-org-adr-sync (E), `.template-type` in manifest (K), reusable-repo-hygiene OPA wiring |
| Resolved/no action | 1 | Theme O (org-baseline 0005 doesn't apply to nwarila-platform/.github) |

## File-by-file

### Repo hygiene / dotfiles (8)

| File | Purpose | Owner | Verdict | Reasoning |
|---|---|---|---|---|
| `.editorconfig` | Editor whitespace/encoding rules | Template (90%) | **KEEP** | byte_identical with canonical; already matches. |
| `.gitattributes` | Line-ending normalization, binary attrs | Template (90%) | **KEEP** | byte_identical, synced in PR #47. |
| `.gitignore` | Deny-all allowlist | Consumer (starter) | **KEEP** | Already in scaffold_starter; consumer extends allowlist with own paths. |
| `.markdownlint-cli2.jsonc` | Markdown lint rules | Template (90%) | **KEEP** | byte_identical, already matches. |
| `.pre-commit-config.yaml` | Pre-commit hook spec | Template (90%) | **KEEP** | byte_identical, synced in PR #47. |
| `.terraform-docs.yml` | terraform-docs config | Template (90%) | **KEEP** | byte_identical, synced in PR #47. |
| `.tflint.hcl` | TFLint config | Template (90%) | **KEEP** | byte_identical, synced in PR #47. |
| `.template-type` | Repo-type discriminator (`framework`) | Template (90%) | **REFACTOR-UPSTREAM** | Not in slim manifest. **Should be** byte_identical — every framework consumer needs this single-line marker, and the reusable-release-evidence already gates on it. File the upstream issue to add it back to byte_identical. |

### Top-level files (4)

| File | Purpose | Owner | Verdict | Reasoning |
|---|---|---|---|---|
| `README.md` | Consumer-facing repo readme | Consumer (10%) | **KEEP** | Domain-specific (describes ISO module). |
| `CHANGELOG.md` | Release-please managed changelog | Consumer (10%) | **KEEP** | Auto-managed by release-please; per-repo. |
| `LICENSE` | MIT license text | Org (covered by NWarila/.github manifest) | **KEEP** | Not in framework manifest (removed in PR #18 as duplicate); org manifest enforces. |
| `Makefile` | Local `make ci` orchestration | Consumer (starter) | **DECIDE** | Already in scaffold_starter. Consumer's local Makefile has graph targets (render_graphs.sh) that no longer have CI counterparts. Drop those targets? Keep for local dev? |

### Release automation (2)

| File | Purpose | Owner | Verdict | Reasoning |
|---|---|---|---|---|
| `.release-please-manifest.json` | release-please version tracking | Consumer (10%) | **KEEP** | Per-repo version state. |
| `release-please-config.json` | release-please configuration | Consumer (10%) | **KEEP** | Per-repo release config. |

### GitHub config (3 + 9 workflows)

| File | Purpose | Owner | Verdict | Reasoning |
|---|---|---|---|---|
| `.github/CODEOWNERS` | Code ownership routing | Consumer (starter) | **KEEP** | scaffold_starter; per-repo owner (`@NWarila`). |
| `.github/PULL_REQUEST_TEMPLATE.md` | PR template | Consumer (starter) | **DECIDE** | scaffold_starter. Currently divergent from canonical — keep consumer version or sync? |
| `.github/renovate.json5` | Renovate config | Consumer (starter) | **DECIDE** | scaffold_starter. Consumer has dep groups for terraform-framework-template + others. Should consumer use `extends:` to canonical instead of duplicate? |
| `.github/workflows/auto-merge.yaml` | Caller for reusable-auto-merge | Template-pattern, consumer-local | **KEEP** | Caller is consumer-local by GitHub Actions requirement. SHA-pinned to framework-template; zizmor suppression in place. |
| `.github/workflows/codeql.yaml` | Caller for reusable-codeql | Template-pattern, consumer-local | **KEEP** | Same pattern as auto-merge. |
| `.github/workflows/scorecard.yaml` | Caller for reusable-scorecard | Template-pattern, consumer-local | **KEEP** | Same pattern. |
| `.github/workflows/security.yaml` | Caller for reusable-iac-security | Template-pattern, consumer-local | **WAIT** | Tracked by upstream issue #19. Currently divergent from canonical (canonical bundles 3 jobs / uses local relative paths). Keep consumer-tailored 3-workflow split. |
| `.github/workflows/release-evidence.yaml` | Caller for reusable-release-evidence | Template-pattern, consumer-local | **KEEP** | Caller pattern; passes repo_type=framework. |
| `.github/workflows/release-please.yaml` | Native release-please-action + evidence dispatch | Consumer (10%) | **DECIDE** | Native, not a caller. Consumer chose this because reusable-release-please dispatches release.yaml (which we don't have). Should consumer adopt the canonical release.yaml pattern + task dispatch instead? Bigger refactor. |
| `.github/workflows/pr-validation.yaml` | Native `make ci` runner | Consumer (90%-pattern but native) | **DECIDE** | Runs local make ci. Canonical pattern (in template) is `ci.yaml`. Should this be renamed + restructured to match? Or stays consumer-specific? |
| `.github/workflows/org-adr-sync.yaml` | Self-contained org ADR drift verifier | Template-pattern, consumer-local | **REFACTOR-UPSTREAM** | Currently self-contained Python verifier embedded in workflow. **Should be** a caller for an upstream `reusable-org-adr-sync` workflow that does the same. Drop ~80 lines of embedded Python in every consumer. |
| `.github/workflows/template-sync.yaml` | Drift-gate against framework-template baseline | Template-pattern, consumer-local | **KEEP** | Caller for NWarila/drift-gate composite action. Already lean. |

### Docs root (1)

| File | Purpose | Owner | Verdict | Reasoning |
|---|---|---|---|---|
| `docs/README.md` | Diataxis quadrant index | Consumer (mix) | **KEEP** | Lists consumer's actual docs. Per-repo content. |

### ADRs - org tier (4)

| File | Purpose | Owner | Verdict | Reasoning |
|---|---|---|---|---|
| `docs/decision-records/org/0001-use-architecture-decision-records.md` | Org-baseline mirror | Org | **KEEP** | Mirrored via org-adr-sync.yaml; not in framework manifest. |
| `docs/decision-records/org/0002-adopt-diataxis-documentation-framework.md` | Org-baseline mirror | Org | **KEEP** | Same. |
| `docs/decision-records/org/0003-use-deny-all-gitignore-strategy.md` | Org-baseline mirror | Org | **WAIT** | Currently missing locally — org-adr-sync would flag if upstream has it. Verify state. |
| `docs/decision-records/org/0004-use-renovate-for-dependency-updates.md` | Org-baseline mirror | Org | **KEEP** | Same. |

### ADRs - repo tier (4)

| File | Purpose | Owner | Verdict | Reasoning |
|---|---|---|---|---|
| `docs/decision-records/repo/0001-terraform-subdirectory-layout.md` | Per-repo ADR | Consumer | **KEEP** | Domain-specific decision. |
| `docs/decision-records/repo/0002-use-repo-local-renovate-baseline.md` | Per-repo ADR | Consumer | **DECIDE** | If renovate.json5 moves to `extends:` pattern, this ADR becomes stale. |
| `docs/decision-records/repo/0003-allow-example-local-readmes.md` | Per-repo ADR | Consumer | **KEEP** | Domain. |
| `docs/decision-records/repo/0004-consume-terraform-template.md` | Per-repo ADR | Consumer | **KEEP** | Documents the consumption decision; rewritten in PR #45. |

### Diataxis - explanation (4)

| File | Purpose | Owner | Verdict | Reasoning |
|---|---|---|---|---|
| `docs/explanation/architecture.md` | Module architecture | Consumer (10%) | **KEEP** | Domain. |
| `docs/explanation/threat-model.md` | Module threat model | Consumer (10%) | **KEEP** | Domain-specific risks. |
| `docs/explanation/testing-strategy.md` | Test approach | Consumer (10%) | **KEEP** | Domain. References render_graphs.sh — see graph-tooling decision. |
| `docs/explanation/dependency-graph-validation.md` | Why graphs matter | Consumer | **DECIDE** | 62 lines justifying graph validation. If graph tooling stays (see graph-tooling decision), keep. If tooling deleted, delete this. |

### Diataxis - how-to (5)

| File | Purpose | Owner | Verdict | Reasoning |
|---|---|---|---|---|
| `docs/how-to/use-from-a-packer-template.md` | Downstream consumer guide | Consumer (10%) | **KEEP** | Domain-critical: documents the Packer contract. |
| `docs/how-to/develop-this-module.md` | Local dev setup | Consumer (10%) | **KEEP** | Domain. |
| `docs/how-to/adopt-this-template.md` | How to adopt | Consumer | **DECIDE** | Documents how OTHER repos adopt this module. Useful or redundant with use-from-a-packer-template? |
| `docs/how-to/generate-terraform-graphs.md` | How to run make graph | Consumer | **DECIDE** | Tied to graph tooling decision. |
| `docs/how-to/review-release-evidence.md` | How to review evidence | Consumer | **KEEP** | Rewritten in PR #45 to defer to canonical reusable. |

### Diataxis - reference (9 + graphs subdir)

| File | Purpose | Owner | Verdict | Reasoning |
|---|---|---|---|---|
| `docs/reference/terraform.md` | Auto-generated tf docs | Consumer (10%) | **KEEP** | terraform-docs output for this module. |
| `docs/reference/release-gates.md` | Release gate catalog | Consumer (starter) | **KEEP** | Now in scaffold_starter upstream; consumer customized in PR #45. |
| `docs/reference/invariants.md` | Invariants doc | Consumer (starter) | **DECIDE** | Now in scaffold_starter upstream. Consumer has the canonical version. Customize for ISO domain or leave generic? |
| `docs/reference/golden-template-contract.md` | Required-files contract | Consumer | **DECIDE** | Pre-dates the slim manifest; describes what consumers must have. Now redundant with mirroring.md (mirrored from upstream). Delete or rewrite? |
| `docs/reference/mirroring.md` | Manifest contract | Template (90%) | **KEEP** | byte_identical; mirrored in PR #47. |
| `docs/reference/runner-protocol.md` | Runner-framework contract | Template (90%) | **KEEP** | byte_identical; mirrored in PR #47. Note: consumer is a framework, not a runner; doc is informational. |
| `docs/reference/quality-gates.md` | Gate role taxonomy | Consumer (starter) | **MISSING** | Canonical is in scaffold_starter. Consumer doesn't have a copy. Add one or skip? |
| `docs/reference/graph-artifacts.md` | Graph evidence schema | Consumer | **DECIDE** | Tied to graph tooling decision. |
| `docs/reference/production-readiness-handoff.md` | Session continuity | Consumer (working doc) | **KEEP** | Maintained per-session. |
| `docs/reference/graphs/minimal.plan.svg` | Sample graph SVG | Consumer | **DECIDE** | Tied to graph tooling decision. |
| `docs/reference/graphs/minimal.summary.json` | Sample graph summary | Consumer | **DECIDE** | Same. |

### decision-records README (1)

| File | Purpose | Owner | Verdict | Reasoning |
|---|---|---|---|---|
| `docs/decision-records/README.md` | ADR index/explainer | Consumer | **KEEP** | Documents the org/repo/template tier model. |

### Examples (10)

| File | Purpose | Owner | Verdict | Reasoning |
|---|---|---|---|---|
| `examples/minimal/{README,main,outputs,versions}.tf` | Smallest invocation | Consumer (10%) | **KEEP** | Domain. |
| `examples/packer-consumer/{README,main,outputs,example.pkrvars.hcl.tmpl}` | Packer consumer pattern | Consumer (10%) | **KEEP** | Domain — the actual integration surface. |
| `examples/adoption-recovery/{README,main}.tf` | Recovery scenario | Consumer (10%) | **KEEP** | Domain. |
| `examples/failure-cases/dependency-cycle/{README,main}.tf` | Failure-case example | Consumer (10%) | **DECIDE** | If graph tooling deleted (cycle detection gone), is this example still useful? |

### Policies (3)

| File | Purpose | Owner | Verdict | Reasoning |
|---|---|---|---|---|
| `policies/opa/iso_manager.rego` | ISO-domain policy | Consumer (10%) | **KEEP** | Domain (HTTPS-only URLs, overwrite_unmanaged restrictions, checksum=sha256, verify=true). |
| `policies/opa/iso_manager_test.rego` | ISO policy tests | Consumer (10%) | **KEEP** | Domain. |
| `policies/exceptions/README.md` | Exception process | Consumer | **DECIDE** | Documents a process. Empty or has real exceptions? Verify. |

### Terraform module (5)

| File | Purpose | Owner | Verdict | Reasoning |
|---|---|---|---|---|
| `terraform/versions.tf` | Pin Terraform + providers | Consumer (10%) | **KEEP** | Domain. Pins terraform=1.15.2 + bpg/proxmox=0.105.0. |
| `terraform/variables.tf` | Input contract | Consumer (10%) | **KEEP** | Domain. |
| `terraform/locals.tf` | Internal values | Consumer (10%) | **KEEP** | Domain. |
| `terraform/resources.tf` | proxmox_download_file resource | Consumer (10%) | **KEEP** | THE module — the literal 10%. |
| `terraform/outputs.tf` | Output contract | Consumer (10%) | **KEEP** | Domain. |
| `terraform/tests/validation.tftest.hcl` | Module-level terraform tests | Consumer (10%) | **KEEP** | Domain. |

### Tests fixtures (6)

| File | Purpose | Owner | Verdict | Reasoning |
|---|---|---|---|---|
| `tests/fixtures/minimal/*.tf` | Test fixture invoking module minimally | Consumer (10%) | **KEEP** | Domain test fixture. |
| `tests/fixtures/packer-consumer/*.tf` | Test fixture for packer pattern | Consumer (10%) | **KEEP** | Domain. |

### Tools (6)

| File | Purpose | Owner | Verdict | Reasoning |
|---|---|---|---|---|
| `tools/check_docs_layout.py` | Diataxis layout enforcement | Template (90%) | **KEEP** | byte_identical; synced in PR #47. |
| `tools/install_ci_tools.sh` | Pinned CI tooling installer | Template (90%) | **KEEP** | byte_identical; synced in PR #47. |
| `tools/render_graphs.sh` | Render terraform graphs | Consumer (now-dead?) | **DECIDE** | Graph CI workflow was deleted (`f3eba02`). Local-only `make graph` target still works. Keep for local dev or delete? |
| `tools/tf_graph_cycles.py` | Detect graph cycles | Consumer (now-dead?) | **DECIDE** | Tied to graph tooling decision. |
| `tools/tf_graph_summary.py` | Summarize graphs | Consumer (now-dead?) | **DECIDE** | Same. |
| `tools/generate_release_evidence.sh` | Generate release evidence bundle | Consumer (now-dead?) | **DECIDE** | Release evidence is now generated by reusable-release-evidence. Is this script invoked anywhere? `make` references? CI references? Delete if dead. |

---

## Decisions needed

The audit identifies **18 DECIDE** rows and **3 REFACTOR-UPSTREAM** rows. Everything else is KEEP. The decisions cluster into themes:

### Theme A: Graph tooling (7 files, 1 decision)

- `tools/render_graphs.sh`, `tools/tf_graph_cycles.py`, `tools/tf_graph_summary.py` — render + analyze graphs
- `docs/how-to/generate-terraform-graphs.md`, `docs/reference/graph-artifacts.md`, `docs/reference/graphs/*` — graph docs and sample outputs
- `examples/failure-cases/dependency-cycle/*` — failure-case example for cycle detection
- `docs/explanation/dependency-graph-validation.md` — explainer

**Decision**: Keep entire graph tooling subsystem for local dev, OR delete it all (CI workflow already gone). Mid-state of "keep tools, delete docs" is incoherent.

### Theme B: Release-evidence helper (1 file, 1 decision)

- `tools/generate_release_evidence.sh` — was the pre-canonical evidence generator

**Decision**: Delete (canonical reusable supersedes), unless still invoked from somewhere.

### Theme C: pr-validation vs ci.yaml naming (1 file, 1 decision)

- `.github/workflows/pr-validation.yaml` runs `make ci`. Canonical template name is `ci.yaml`. Functionally identical.

**Decision**: Rename to `ci.yaml` for fleet consistency, OR keep `pr-validation.yaml` (more accurate to its trigger pattern).

### Theme D: release-please native vs canonical (1 file, 1 decision)

- Consumer's `release-please.yaml` runs `release-please-action` natively and dispatches `release-evidence.yaml`. Canonical pattern is `release.yaml` with `task` workflow_dispatch input.

**Decision**: Refactor to canonical pattern (requires adding `task` input to release-evidence.yaml + renaming), OR keep consumer's split. Refactor is bigger scope.

### Theme E: Caller workflows — `org-adr-sync.yaml` (1 file, 1 upstream PR)

- Self-contained Python verifier embedded in YAML. ~80 lines.
- Should be a caller for an upstream `reusable-org-adr-sync.yaml` (mirrored on the framework template, or org). Drop the embedded Python from every consumer.

**Decision**: File upstream issue/PR.

### Theme F: renovate.json5 — `extends:` vs duplicate (1 file, 1 decision)

- Canonical is in scaffold_starter. Consumer has its own dep groups but doesn't `extends:` the canonical.
- ADR-0002 (`use-repo-local-renovate-baseline.md`) documents the duplicate choice; would become stale if extends pattern adopted.

**Decision**: Switch to `extends:` pattern, OR keep duplicate.

### Theme G: PR template (1 file, 1 decision)

- `.github/PULL_REQUEST_TEMPLATE.md` is scaffold_starter. Consumer's diverges from canonical. Trivial.

**Decision**: Sync to canonical, OR keep consumer's.

### Theme H: invariants.md (1 file, 1 decision)

- `docs/reference/invariants.md` is scaffold_starter. Consumer has canonical content from PR #47 sync; some lines apply (SHA-pinning, exact pins), some are template-test-specific (synthetic providers, multi-env example).

**Decision**: Customize for ISO domain, OR leave canonical with a "applies in spirit" note.

### Theme I: docs/reference/quality-gates.md missing (1 file, 1 decision)

- Canonical is in scaffold_starter. Consumer doesn't have a copy. Quality-gates classifies gate roles (blocking/scheduled/release/advisory).

**Decision**: Add a consumer-customized copy, OR skip (consumer doesn't have a strong need without it).

### Theme J: golden-template-contract.md (1 file, 1 decision)

- `docs/reference/golden-template-contract.md` lists files the template contract requires. Now redundant with mirroring.md (which is canonical).

**Decision**: Delete (superseded), OR rewrite as ISO-specific contract notes.

### Theme K: `.template-type` upstream gap (1 file, 1 upstream PR)

- File exists locally (`framework`). Used by `reusable-release-evidence` to gate framework-vs-runner behavior. NOT in any manifest — silent dependency.

**Decision**: File upstream PR to add `.template-type` to byte_identical (consumer-required).

### Theme L: Exception README (1 file, 1 decision)

- `policies/exceptions/README.md` — process doc for policy exceptions. Need to verify content vs need.

**Decision**: Verify utility, KEEP or DELETE.

### Theme M: Makefile (1 file, 1 decision)

- scaffold_starter. Consumer has graph targets that are stranded if graph tooling goes (Theme A).

**Decision**: Depends on Theme A outcome.

### Theme N: ADR-0002 staleness if extends adopted (1 file, conditional)

- Stale if Theme F adopts `extends:` pattern.

**Decision**: Conditional on Theme F.

### Theme O: ADR for org-baseline missing 0005 (1 file, 1 investigation)

- Org publishes 5 ADRs (0001-0005). Consumer mirrors 4. ADR-0003 (deny-all gitignore) is in the consumer's local list. Missing one matters.

**Decision**: Investigate state; either add missing ADR or document gap.

---

## Approved decisions (2026-05-27)

All 15 themes decided. Verdicts:

- **A**: DELETE graph subsystem (7+ files).
- **B**: DELETE `tools/generate_release_evidence.sh`.
- **C**: RENAME `pr-validation.yaml` → `ci.yaml`.
- **D**: REFACTOR `release-please.yaml` + `release-evidence.yaml` into a single `release.yaml` with task dispatch (matches canonical `reusable-release-please` contract).
- **E**: Upstream PR — publish `reusable-org-adr-sync.yaml`; consumer becomes a thin caller.
- **F**: Refactor `.github/renovate.json5` to use `extends:`; rewrite ADR-0002.
- **G**: Sync `.github/PULL_REQUEST_TEMPLATE.md` to canonical.
- **H**: Customize `docs/reference/invariants.md` for the ISO domain.
- **I**: Add `docs/reference/quality-gates.md` as a customized copy mapping canonical taxonomy to consumer workflows.
- **J**: DELETE `docs/reference/golden-template-contract.md` (superseded by mirroring.md).
- **K**: Upstream PR — add `.template-type` to baseline-manifest.json `byte_identical`.
- **L**: KEEP `policies/exceptions/README.md`.
- **M**: Remove graph targets from `Makefile` (follows A).
- **N**: Rewrite ADR-0002 to record the `extends:` choice (follows F).
- **O**: Resolved — no action.
- **OPA**: Upstream PR — publish `reusable-repo-hygiene.yaml`; consumer becomes a caller.

## Execution plan

Sequenced for minimum reviewability:

### Stage 1: Land PR #47 first (already green)
- Resync to slim manifest. Unrelated to audit but blocks rebase pain.

### Stage 2: Three upstream PRs (run in parallel — no dependencies)
1. **Upstream PR** — `reusable-org-adr-sync.yaml`. Mirrors the consumer's current self-contained verifier.
2. **Upstream PR** — Add `.template-type` to `baseline-manifest.json` `byte_identical`.
3. **Upstream PR** — `reusable-repo-hygiene.yaml`. Wraps `tools/build_opa_input.py` + `opa eval` against `policies/opa/repo_hygiene.rego`.

### Stage 3: Consumer cleanup PR (deletes only)
- Delete graph subsystem (Theme A: 7 files).
- Delete `tools/generate_release_evidence.sh` (Theme B).
- Delete `docs/reference/golden-template-contract.md` (Theme J).
- Clean up `Makefile` graph targets (Theme M).
- Update `.gitignore` allowlist (drop deleted entries).
- ADR if scope warrants documenting the deletions.

### Stage 4: Consumer config standardization PR
- Refactor `.github/renovate.json5` to use `extends:` (Theme F).
- Rewrite ADR-0002 (Theme N).
- Sync `.github/PULL_REQUEST_TEMPLATE.md` to canonical (Theme G).

### Stage 5: Consumer workflow architecture PR
- Rename `.github/workflows/pr-validation.yaml` → `ci.yaml` (Theme C).
- Refactor `.github/workflows/release-please.yaml` + `release-evidence.yaml` → single `release.yaml` with task dispatch (Theme D).
- Branch protection rule update (manual via UI, not in PR).

### Stage 6: Consumer docs PR
- Customize `docs/reference/invariants.md` (Theme H).
- Add `docs/reference/quality-gates.md` (Theme I).

### Stage 7: Wire upstream reusables into consumer
- Swap `.github/workflows/org-adr-sync.yaml` from self-contained verifier to caller of `reusable-org-adr-sync.yaml` (depends on Stage 2 PR 1 merging).
- Add `.github/workflows/repo-hygiene.yaml` as caller for `reusable-repo-hygiene.yaml` (depends on Stage 2 PR 3 merging).
- Bump `template-sync.yaml` SHA pin to pick up `.template-type` manifest entry (depends on Stage 2 PR 2 merging).
- Add `.template-type` to byte_identical mirror state (drift-gate verifies).

### Stage 8: Investigate / resolve issue #19 (security.yaml)
- Out of scope for this audit cascade; tracked separately.

---

## Addendum: Deep Research external critique (2026-05-27)

External adversarial review (ChatGPT Deep Research) on the architecture-review.md.
Validated the slim manifest direction and explicitly endorsed not restoring the
heavy mirror. Surfaced 10 risks not caught by the file-by-file audit (security /
governance / control-completeness gaps the file lens missed).

**Adopted P0+P1 findings (folded into existing stages or added below):**

- **P0a** — Add `merge_group` trigger to PR-gating workflows (merge-queue support). Fold into Stage 5.
- **P0b** — Pin runner image to `ubuntu-24.04` (not `ubuntu-latest`). Fold into Stage 5.
- **P0c** — Add `packer validate` job for tracked Packer fixture. Fold into Stage 5.
- **P1a** — Gate `iso_url` output behind `expose_iso_url` variable (default false; output becomes null unless explicitly enabled). Disclosure-risk reduction for path-embedded tokens.
- **P1b** — Add `adopt_unmanaged_confirmation` variable required when `overwrite_unmanaged=true`. Destructive-recovery friction.
- **P1c** — Require second-reviewer on `.github/workflows/**` and release paths via CODEOWNERS. Segregation of duties.
- **P1d** — Document enforceable least-privilege Proxmox RBAC (`Datastore.AllocateTemplate`, `Sys.Audit`, `Sys.Modify`). Fold into Stage 6 docs.

**Deferred (P2/P3):**

- **P2** — Proxmox sandbox integration job (mock-only tests don't validate provider behavior). Requires sandbox availability + token provisioning.
- **P2** — Release evidence attestations via `actions/attest` + SBOM. Bigger scope; depends on canonical reusable-release-evidence.
- **P3** — Revisit exact-pin policy for reusable child modules (Terraform guidance suggests min-version for reusables, exact for root). Portfolio-wide design question.

**Deep Research factual errors (noted, not actioned):**

- Their structural diff marks `.pre-commit-config.yaml`, `.terraform-docs.yml`, `.tflint.hcl` as **Missing** on live main. They're actually tracked (gitignore lines 12-14; `git ls-files` confirms). Their explicit caveat — "I could not independently retrieve the template repository contents" — leaked into the consumer-side claims too.

## Revised execution plan

### Stage 5 (expanded): Consumer workflow architecture PR
- Theme C: rename `pr-validation.yaml` → `ci.yaml`.
- Theme D: consolidate `release-please.yaml` + `release-evidence.yaml` → single `release.yaml` with task dispatch.
- **P0a** — Add `merge_group` trigger to `ci.yaml`, `security.yaml`, `codeql.yaml`, `scorecard.yaml`.
- **P0b** — Pin all `runs-on: ubuntu-latest` → `ubuntu-24.04` in consumer-owned workflow steps.
- **P0c** — Add `packer validate examples/packer-consumer/build.pkr.hcl` step to `ci.yaml`.
- Branch protection rule UI update (manual, not in PR).

### Stage 6 (expanded): Consumer docs PR
- Theme H: customize `invariants.md` for ISO domain.
- Theme I: add `quality-gates.md`.
- **P1d** — Add explicit Proxmox RBAC requirements section to consumer-facing docs (likely `docs/how-to/use-from-a-packer-template.md` or a new `docs/reference/proxmox-rbac.md`).

### Stage 6.5 (new): Module hardening PR
- **P1a** — `terraform/variables.tf`: add `expose_iso_url` (default false).
- **P1b** — `terraform/variables.tf`: add `adopt_unmanaged_confirmation` (default "").
- **P1a** — `terraform/outputs.tf`: gate `iso_url` output on `expose_iso_url`, mark sensitive.
- **P1b** — `terraform/resources.tf`: add lifecycle precondition requiring `adopt_unmanaged_confirmation == iso_pin.filename` when `overwrite_unmanaged=true`.
- New repo ADR documenting the BACKWARDS-INCOMPATIBLE change + migration notes.
- Major version bump in `.release-please-manifest.json`.
- Update examples + tests to reflect new contract.
- Update consumer-facing docs (use-from-a-packer-template.md) with migration guide.

### Stage 6.6 (new): Governance PR
- **P1c** — `.github/CODEOWNERS`: route `.github/workflows/**`, release-please config, and SECURITY.md to require second reviewer (in addition to @NWarila).
- Branch protection rule update (UI) requiring code-owner approval on those paths.


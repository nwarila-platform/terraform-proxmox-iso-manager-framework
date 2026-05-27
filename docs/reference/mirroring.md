# Mirroring And Consumer Baseline

This template's role is to give downstream frameworks a standardized
scaffold to drop their code into and get a highly effective deployment
cycle for free. `baseline-manifest.json` enumerates only what a consumer
**actually uses in its own production lifecycle**. Files that exist solely
to serve this template's own self-tests stay in the template; consumers
reach them through `uses:` or cross-repo checkout, not by mirroring.

## Design Principle

> Consumers mirror what they run. The template keeps what only it runs.

Concretely:

- A consumer's local `make ci`, pre-commit hooks, editor, formatter, and
  PR-time security caller need certain files locally. Those go in
  `byte_identical`.
- Consumer caller workflows reach this template's reusables via cross-repo
  `uses:`. The reusables themselves are template-only.
- Helper tools, fixture inputs, and unit tests that only the template's
  own `make ci` invokes are template-only.
- Files that every consumer wants but customizes per-repo (ownership,
  Renovate dep groups, `.gitignore` allowlist, repo-specific `Makefile`
  targets) belong in `scaffold_starter`, not `byte_identical`.

## byte_identical

Drift-gate enforces byte-equality on these entries in every consumer.

| Path | Why it's mirrored |
| --- | --- |
| `.editorconfig`, `.gitattributes`, `.markdownlint-cli2.jsonc`, `.pre-commit-config.yaml`, `.terraform-docs.yml`, `.tflint.hcl` | Local editor / formatter / linter configs |
| `.github/workflows/security.yaml` | Canonical security caller — every consumer runs it identically |
| `docs/reference/mirroring.md` (this file) | Canonical statement of the manifest contract |
| `docs/reference/runner-protocol.md` | Canonical contract for how runners call the framework deploy reusable |
| `tools/check_docs_layout.py` | Invoked by the consumer's local `make ci` for Diataxis layout enforcement |
| `tools/install_ci_tools.sh` | Invoked by the consumer's PR-validation workflow to install pinned CI tooling |

## scaffold_starter

Drift-gate documents these entries but does not byte-compare them.
Consumers receive them at bootstrap and customize freely.

| Path | Why it's a starter |
| --- | --- |
| `Makefile` | Consumers add their own targets (graph rendering, release-evidence helpers, etc.) |
| `.gitignore` | Consumers extend the allowlist with their own examples/, tests/, terraform/ files |
| `.github/CODEOWNERS` | Consumers set their own ownership |
| `.github/renovate.json5` | Consumers add their own dep groups (terraform-framework-template SHA pin, terraform CLI, providers, etc.) |
| `.github/PULL_REQUEST_TEMPLATE.md` | Consumers tailor PR fields to their domain |
| `baseline-manifest.json` | Template repos that derive from this one publish their own manifest |
| `docs/reference/invariants.md` | Consumers add framework-specific invariants and may drop those tied to this template's synthetic providers |
| `docs/reference/quality-gates.md` | Consumers map the gate-role taxonomy onto their actual workflow names |
| `docs/reference/release-gates.md` | Consumers document the gates that actually run in their own release pipeline |

## Template-Only (NOT in the manifest)

These files live in this template and serve this template's own
validation. Consumers do not mirror them; consumer workflows reach them
through cross-repo `uses:` (reusable workflows) or cross-repo
`actions/checkout` (helper scripts called from reusables).

- `.github/workflows/reusable-*.yaml` — consumers `uses:` them cross-repo.
- `tools/build_opa_input.py`, `build_plan_input.py`, `check_adr_schema.py`,
  `check_baseline_manifest.py`, `check_privileged_workflows.py`,
  `run_privileged_workflow_tests.py`, `verify.py` — invoked only by this
  template's own `make ci`.
- `tools/ci/*` — invoked by `reusable-terraform-deploy` after that
  reusable checks this template out into a `framework/` path.
- `tests/ci/*.bats` — bats tests for this template's own `tools/`.
- `tests/fixtures/privileged-workflows/*` — inputs for this template's
  own `tools/check_privileged_workflows.py`.
- `policies/opa/repo_hygiene*.rego`, `terraform_plan*.rego` — universal
  policies evaluated only by this template's own `tools/verify.py`. When a
  consumer wants to enforce them, the right answer is a composite action
  or reusable workflow that cross-checks-out this template — not a
  byte-identical mirror.
- `fixtures/integration/basic/README.md` — input for this template's
  integration runner.
- `docs/decision-records/template/*` — this template's own ADRs.
  Consumers read them on github.com.

**Heuristic for adding a new file**: ask "does a *consumer* invoke this
file in its own production lifecycle?" If yes, it belongs in
`byte_identical` (or `scaffold_starter` if it's per-repo customizable).
If no — if it serves only the template's own self-tests, fixtures, or
internal helpers — it stays template-only and consumers reach it via
`uses:`/checkout when they need to.

## Org Baseline

The `NWarila/.github` organization manifest enumerates files every repo
under the org mirrors regardless of framework type (`LICENSE`,
`SECURITY.md`, `CODE_OF_CONDUCT.md`, the org-tier ADRs, Diataxis
`.gitkeep` markers, and the universal reusable workflows). Those entries
intentionally do **not** appear here — they are sourced from the org and
would be a duplicate source of truth in this manifest.

## New Framework Checklist

1. Rewrite `README.md` for the real framework.
2. Replace the synthetic Terraform under `terraform/`.
3. Update examples and generated Terraform docs.
4. Run `python tools/verify.py verify` (template-side validation).

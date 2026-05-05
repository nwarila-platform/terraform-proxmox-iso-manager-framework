# ADR-0004: Use Renovate for Dependency Updates with Shared Org Baseline

| Field          | Value                                    |
| -------------- | ---------------------------------------- |
| Status         | Accepted                                 |
| Date           | 2026-05-05                               |
| Authors        | Nick Warila (@NWarila)                   |
| Decision-maker | Nick Warila (sole portfolio maintainer)  |
| Consulted      | None.                                    |
| Informed       | None.                                    |
| Reversibility  | Medium                                   |
| Review-by      | N/A (Accepted)                           |

## TL;DR

All `nwarila-platform/*` repositories track dependency updates via [Renovate](https://docs.renovatebot.com/). Common settings — schedule, semantic-commit prefixes, dependency-dashboard, SHA-pin retention on GitHub Actions, PR concurrency caps — live in a single shared baseline at `nwarila-platform/.github/.github/renovate.json5`. Every adopting repository's local `.github/renovate.json5` extends `github>nwarila-platform/.github` and adds only the overrides specific to that repository's manager surface (e.g., `terraform.rangeStrategy: "bump"` for child modules, `"pin"` for root modules). Renovate replaces Dependabot at the org level because Dependabot does not update Terraform's `required_version` field and has incomplete coverage of pinned tool versions in adjacent tooling. The shared-baseline pattern keeps the policy DRY across the org while preserving per-repo override capability.

## Context and Problem Statement

Repositories under the `nwarila-platform` organization track several version-pin surfaces that need automated updates:

- **GitHub Actions** referenced by full commit SHA in workflow files, per the org's SHA-pin policy.
- **Terraform** version constraints — `required_version` on the `terraform` block, and provider versions in `required_providers`.
- **Tool versions** in adjacent tooling such as `.tool-versions` (asdf), devcontainer feature inputs, the `terraform_version:` literal in `hashicorp/setup-terraform` workflow steps, Dockerfile `FROM` lines, and pre-commit `rev:` references.
- **Other ecosystems** as repos add language-specific tooling (npm, pip, etc.).

Dependabot supports the GitHub Actions case well. It does **not** support Terraform's `required_version` field — Dependabot's Terraform updater scans `required_providers` but ignores the constraint on Terraform itself. Dependabot also has limited and inconsistent handling of pinned tool versions in adjacent tooling. As repositories grow to include any of those, Dependabot leaves silent drift. Adopting Dependabot for every new repository accepts that gap by default, which is misaligned with the org's secure-by-default posture.

Renovate offers native managers for every one of those surfaces (`terraform`, `terraform-version`, `github-actions`, `pre-commit`, `asdf`, `dockerfile`, `devcontainer`, `npm`, `pip`, etc.) plus a `regex` manager for arbitrary version literals. It also rewrites the trailing tag comment on SHA-pinned Actions bumps (`# v6` → `# v6.1.0`), preserving the human-readability convention enforced in the org's Actions SHA-pin policy.

A second concern beyond manager coverage is configuration drift. If every repository hand-rolls its Renovate config, common settings (schedule, semantic-commit prefixes, SHA-pin retention) diverge across repos and the org loses uniform behavior. Renovate's `extends` mechanism solves this: a single shared config at the org level is inherited by every consuming repo, with per-repo overrides limited to repo-specific concerns.

The previous per-repo `.github/dependabot.yml` files covered only `github-actions`, at varying schedules. That coverage no longer matches the org's actual update surface, and the cadence drift produces avoidable PR churn.

## Decision Drivers

The following forces shaped this decision:

1. **Coverage of Terraform `required_version` and adjacent tooling.** Dependabot does not handle these; Renovate does. As repositories grow to pin Terraform CLI versions and other tool versions in adjacent tooling, the gap widens.
2. **SHA-pin retention on GitHub Actions.** The org's SHA-pin policy requires every `uses:` entry to be a 40-character commit SHA with a tag comment. The dependency-update tool must preserve this format on every bump.
3. **Conventional Commit emission.** Update PRs should emit Conventional Commit prefixes that release-please (where configured) categorises.
4. **Cross-repo consistency.** Common settings must be uniform across repos. Per-repo configs that drift are a maintenance liability.
5. **DRY (Inheritance over duplication).** Hand-copying the same settings into every new repo is error-prone. A shared baseline that consuming repos inherit reduces maintenance to one place. This aligns with the "Inheritance over duplication" principle in [ADR-0001 (org)](0001-use-architecture-decision-records.md).
6. **Per-repo override capability.** Some settings (e.g., `terraform.rangeStrategy: "bump"` vs `"pin"`) are repo-specific. The shared baseline must accommodate per-repo overrides without forcing a one-size-fits-all default that is wrong for half the repos.
7. **Reasonable PR cadence.** Daily PR creation produces noise; weekly cadence aligns with most repository review windows.

## Considered Options

1. **Stay on Dependabot org-wide.** Continue with per-repo `.github/dependabot.yml`, accepting the `required_version` gap and per-repo cadence drift.
2. **Adopt Renovate per-repo with no shared baseline.** Each repo maintains its own `.github/renovate.json5` independently.
3. **Adopt Renovate with a shared org baseline.** Common settings live in `nwarila-platform/.github/.github/renovate.json5`; consuming repos extend `github>nwarila-platform/.github` and override repo-specific concerns.
4. **Mix Dependabot for legacy repos and Renovate for new repos.** Run both tools depending on repo age.
5. **Hand-roll a scheduled GitHub Actions workflow that opens update PRs.** Custom maintenance pipeline.

## Decision Outcome

Chosen option: **Option 3, Renovate with a shared org baseline.**

The baseline lives at `nwarila-platform/.github/.github/renovate.json5` and configures:

- `extends: ["config:recommended"]` as the inherited Renovate baseline.
- `schedule: ["before 6am on monday"]` (weekly), the org cadence.
- `semanticCommits: "enabled"` so PRs use Conventional Commit prefixes.
- `dependencyDashboard: true` so each repo gets a single tracking issue rather than a flood of standalone PRs.
- `prConcurrentLimit: 5` and `prHourlyLimit: 2` to cap noise during update bursts.
- `github-actions.pinDigests: true` to preserve SHA-pin format and rewrite trailing tag comments.
- A `packageRules` entry that maps `github-actions` updates to `ci(actions): ...` Conventional Commit prefixes.

Each adopting repository carries a minimal `.github/renovate.json5` that:

- Inherits the baseline via `extends: ["github>nwarila-platform/.github"]`.
- Adds only the overrides that are genuinely repo-specific. The most common are:
  - `terraform.rangeStrategy` — `"bump"` for child modules (so consumer-side compatibility is preserved), `"pin"` for root modules.
  - Additional `packageRules` for managers the baseline does not cover (e.g., `terraform`, `pip`, `npm`).

The `.github/dependabot.yml` file MUST NOT exist in any adopting repository. Repositories that previously contained one MUST remove it as part of their Renovate migration PR.

Renovate enablement requires the Renovate GitHub App to be installed against each repository or against the entire org. Installation is a one-time operation outside the repo's git history and is the maintainer's responsibility.

## Pros and Cons of the Options

### Option 1: Stay on Dependabot org-wide

- **Good, because** Dependabot is GitHub-native; no third-party app installation required.
- **Good, because** existing single-ecosystem configurations are already working for GitHub Actions in the repos that have them.
- **Bad, because** Dependabot cannot update Terraform's `required_version` field. Repositories with pinned Terraform versions accumulate untracked drift.
- **Bad, because** Dependabot's coverage of pinned tool versions in adjacent tooling is incomplete and inconsistent.
- **Bad, because** Dependabot's per-repo configuration provides no shared baseline; common settings drift across repos.

### Option 2: Adopt Renovate per-repo with no shared baseline

- **Good, because** every repo's behavior is fully self-contained and visible in one file.
- **Good, because** there is no implicit dependency on an external config repo at evaluation time.
- **Bad, because** common settings (schedule, semantic-commit prefixes, SHA-pin retention) drift across repos as new repos are bootstrapped from older templates.
- **Bad, because** changing an org-wide setting (e.g., shifting the cadence from weekly to bi-weekly) requires a coordinated PR across every repo.
- **Bad, because** it duplicates ~30 lines of identical config into every repository, contradicting the org's "Inheritance over duplication" principle.

### Option 3: Adopt Renovate with a shared org baseline (chosen)

- **Good, because** Renovate covers every update surface the org has now or is likely to grow into.
- **Good, because** `pinDigests: true` preserves SHA-pin format on GitHub Actions bumps and rewrites trailing tag comments in place.
- **Good, because** `semanticCommits` emits Conventional Commit prefixes that release-please categorises without per-PR rewriting.
- **Good, because** the shared baseline at `nwarila-platform/.github` keeps common settings uniform across the org. Changing a setting in one place updates every consuming repo on its next Renovate run.
- **Good, because** consuming repos remain free to override repo-specific concerns (e.g., `terraform.rangeStrategy`) without re-declaring the entire config.
- **Good, because** the dependency-dashboard issue surfaces pending updates without flooding the PR list.
- **Neutral, because** Renovate requires the GitHub App to be installed once per repository (or once per org).
- **Bad, because** the Renovate GitHub App is a third-party dependency in the supply chain (managed by Mend); operational burden of compromise is real.
- **Bad, because** the dependency-dashboard issue is opinionated; if not curated it can clutter the issue tracker.
- **Bad, because** an outage or breaking change in the shared baseline propagates to every consuming repo at once. Mitigation: changes to `nwarila-platform/.github/.github/renovate.json5` are reviewed in PR like any other org-baseline change.

### Option 4: Mix Dependabot and Renovate

- **Good, because** legacy repos avoid the migration cost.
- **Bad, because** the org loses uniform dependency-update behavior. New contributors must learn which repo uses which tool.
- **Bad, because** the `required_version` coverage gap remains for any repo still on Dependabot, partially defeating the value of switching at all.
- **Bad, because** mixed-tool environments accumulate inconsistencies (different cadences, different commit-message formats) that erode the value of having either tool.

### Option 5: Hand-roll a scheduled GitHub Actions workflow

- **Good, because** it provides full control over update logic, schedule, and PR template.
- **Bad, because** it imposes disproportionate maintenance burden for a personal-account org.
- **Bad, because** features like release-notes fetching, semver diffing, and dependency-graph awareness would all be reinvented.
- **Bad, because** a hand-rolled workflow is a single point of failure with no community support.

## Confirmation

Adherence to this ADR is confirmed by the following mechanisms. The wording `MUST`, `SHOULD`, and `MAY` follows [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) conventions.

1. **Tool-presence check.** Every adopting repository MUST contain `.github/renovate.json5`. A `.github/dependabot.yml` file MUST NOT exist; a CI script or `pre-commit` hook MAY assert its absence.
2. **Inheritance check.** Every adopting repository's `.github/renovate.json5` MUST include `github>nwarila-platform/.github` in its `extends` array, or document an explicit reason in a repo-specific superseding ADR for not doing so.
3. **SHA-pin retention check.** The shared baseline MUST set `github-actions.pinDigests: true`. A reviewer SHOULD reject a PR to the baseline that removes or disables this setting without a superseding ADR.
4. **Schedule check.** The shared baseline MUST schedule weekly or less-frequent runs. Daily or more-frequent schedules would produce avoidable PR churn across the org.
5. **Override discipline.** Repository-local overrides MUST be limited to repo-specific concerns. Settings that should apply org-wide MUST be added to the shared baseline rather than copy-pasted into every consuming repo.
6. **Editorial rule.** A change of dependency-update tool (back to Dependabot, or to a third option) is itself an architectural decision and MUST be recorded as a superseding ADR.

Enforcement tooling is recommended but not mandatory at acceptance time. A repository MAY add CI scripts that verify (1)–(3); the org-wide adoption pattern MAY be enforced by the same `org-adr-sync` workflow that mirrors org ADRs into consuming repos.

## Consequences

### Positive

- Terraform `required_version` updates are tracked automatically across the org; the Dependabot-shaped gap is closed.
- Action SHAs stay current with their tag comments rewritten in place across every repo, preserving the SHA-pin convention without manual intervention.
- Conventional Commit prefixes flow into release-please without per-PR rewriting.
- Common settings live in one place; changing the cadence or a packaging rule org-wide takes one PR rather than many.
- New repositories bootstrap with a ~6-line `renovate.json5` that inherits the org behavior automatically.
- Future managers (pre-commit, devcontainer features, mkdocs Python deps, Docker base images) can be enabled by editing the shared baseline rather than every consuming repo.

### Negative

- One additional GitHub App must be installed against the org (or per-repo).
- Renovate's dependency-dashboard issue is opinionated and clutters the issue tracker if not curated.
- The shared baseline is now a load-bearing artifact: an outage or breaking change at `nwarila-platform/.github/.github/renovate.json5` propagates to every consuming repo on the next Renovate run.
- Release-notes fetching adds latency to PR creation (negligible in practice).

### Neutral

- The `github>` extends syntax creates a runtime dependency on `nwarila-platform/.github` being reachable when Renovate evaluates a consuming repo. In practice this is reliable; if it becomes unreliable, repositories MAY temporarily inline the baseline.
- This ADR scopes the decision to the `nwarila-platform` organization. If `NWarila/*` user-account repos adopt Renovate later, they will reference this ADR as the canonical pattern but with their own user-level shared baseline.
- Repo-specific overrides remain permitted; this ADR is not a uniformity-at-all-costs mandate. The only constraint is that overrides MUST be repo-specific concerns.

## Assumptions

This decision rests on the following assumptions. If any becomes false, this ADR should be revisited:

1. The Renovate GitHub App remains free for personal-account organizations and continues to be actively maintained.
2. Renovate continues to support the `extends: ["github>org/.github"]` shared-config pattern.
3. The Renovate config schema remains compatible with the configuration shape used here.
4. The org continues to use Conventional Commits + release-please for repos that publish releases. A switch to a different release tool would require adjusting `semanticCommitType` overrides in the shared baseline.

## Supersedes

None — `.github/dependabot.yml` files in `nwarila-platform/*` repos were single-ecosystem configurations with no prior ADR documenting their adoption. This ADR replaces that pattern as a new decision rather than as a formal supersession.

## Superseded by

None (current).

## Implementing PRs

Pending. The first implementing PR ships in `terraform-proxmox-iso-manager-framework`, which migrates from `dependabot.yml` to the shared-baseline `.github/renovate.json5` pattern. Subsequent adopting repositories will be listed here.

## Related ADRs

- [ADR-0001](0001-use-architecture-decision-records.md) — establishes the format and dual-scope structure of decision records.
- [ADR-0003](0003-use-deny-all-gitignore-strategy.md) — establishes the deny-all `.gitignore` strategy. Renovate config files are explicitly allowlisted in adopting repositories per ADR-0003.

## Compliance Notes

This ADR preserves the SHA-pin policy (encoded in the shared baseline as `github-actions.pinDigests: true`). It does not modify branch-protection or PR-review requirements: every Renovate PR is subject to the same `main`-branch protections as a human-authored PR, including required status checks. Future ADRs that adopt additional managers (e.g., `pre-commit`, `pip`, `docker`) inherit this ADR's defaults and need only document scope-specific divergence in repo-local config.

| Framework              | Control / Practice ID                                                | Potential Evidence Contribution                                                                                                |
| ---------------------- | -------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| NIST SP 800-53 Rev. 5  | SI-2 (Flaw Remediation)                                              | Renovate's automated update PRs contribute to the timely application of patches and security fixes across the org.            |
| NIST SP 800-53 Rev. 5  | CM-3 (Configuration Change Control)                                  | The shared-baseline pattern records org-wide dependency-management policy in source control with PR review history.            |
| NIST SP 800-218 (SSDF) | PW.4 (Reuse Existing, Well-Secured Software When Feasible)           | Tracking dependency updates with SHA-pin retention preserves the supply-chain integrity posture for reused software.           |

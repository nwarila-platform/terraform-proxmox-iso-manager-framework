# ADR-0002: Extend the Framework-Template Renovate Preset

| Field          | Value                                    |
| -------------- | ---------------------------------------- |
| Status         | Accepted (supersedes the previous local-baseline decision) |
| Date           | 2026-05-27                               |
| Authors        | Nick Warila (@NWarila)                   |
| Decision-maker | Nick Warila (sole portfolio maintainer)  |
| Consulted      | None.                                    |
| Informed       | None.                                    |
| Reversibility  | High                                     |
| Review-by      | N/A (Accepted)                           |

## TL;DR

This repository's `.github/renovate.json5` extends the canonical preset published
by `NWarila/terraform-framework-template`. The local file keeps only repo-specific
package grouping; stack-wide Renovate policy (digest pinning, exact terraform
pins, supply-chain quarantine, custom `# renovate:` annotation managers,
schedule, etc.) lives upstream and is inherited automatically.

This supersedes the previous decision (recorded in the original version of this
ADR) to inline a full local baseline. That decision was correct at the time —
`nwarila-platform/.github` did not publish a working preset, and inlining was
safer than extending a missing artifact. The framework-template now publishes a
working preset, so the original blocker is gone and the org ADR-0004 pattern
becomes viable directly.

## Context and Problem Statement

Org ADR-0004 standardizes Renovate across the portfolio and expects consumers
to inherit a shared baseline. The original ADR-0002 deferred this because the
referenced preset did not exist. As of `NWarila/terraform-framework-template`
SHA `efcf3274` (2026-05-27), the framework template publishes a complete
Renovate preset at `.github/renovate.json5` that encodes:

- `pinDigests: true` for `github-actions` (SHA pinning)
- `rangeStrategy: "pin"` for `terraform` (exact module + provider pins)
- A `customManagers` regex that tracks `# renovate: datasource=…` annotations
  in workflow inputs and shell scripts (covers terraform/tflint/terraform-docs/
  opa version bumps)
- A weekly schedule (`before 6am on monday`)
- A 7-day supply-chain quarantine via `minimumReleaseAge` (no update lands
  sooner than 7 days after the upstream release timestamp)
- Dependency-dashboard + semantic-commits enablement

That preset is the right authority for stack-wide behavior. Duplicating it
locally guarantees drift over time and forces every consumer to rev in lockstep
through Renovate-driven PRs against each duplicated rule.

## Decision Drivers

1. Stack-wide Renovate behavior must apply uniformly across the fleet without
   per-consumer copy-paste.
2. Consumer-specific package grouping (the framework template's own SHA pin,
   per-repo automerge decisions) must remain locally controllable.
3. Pin discipline for the *extended preset itself* is unavoidable — Renovate's
   preset-extension mechanism does not support SHA-pinning the preset source.
   The tradeoff must be documented and accepted explicitly.

## Considered Options

1. Extend the framework-template preset; keep only consumer-specific rules
   locally.
2. Keep the inlined local baseline (original ADR-0002 decision).
3. Hybrid: copy the framework-template preset verbatim and let drift-gate or a
   periodic sync workflow enforce byte-equality.

## Decision Outcome

Chosen option: **Option 1, extend the framework-template preset.**

The local `.github/renovate.json5` becomes:

```jsonc
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "github>NWarila/terraform-framework-template//.github/renovate.json5"
  ],
  "packageRules": [
    {
      "matchDepNames": ["NWarila/terraform-framework-template"],
      "groupName": "terraform-framework-template",
      "semanticCommitType": "chore",
      "semanticCommitScope": "deps",
      "automerge": false
    }
  ]
}
```

The extends reference does NOT pin a ref (Renovate's preset extension does not
support SHA pinning of the preset source). It follows the framework-template's
`main` branch. This is the same convention used by other consumers in the fleet
(see `NWarila/github-terraform-runner` which extends `NWarila/terraform-runner-template`
the same way).

## Pros and Cons of the Options

### Option 1: Extend the framework-template preset (chosen)

- **Good, because** stack-wide Renovate behavior is centralized; one upstream
  change propagates to every consumer without copy-paste.
- **Good, because** the consumer file is reviewable as a ~10-line
  consumer-specific addition rather than a ~70-line duplicated baseline.
- **Good, because** it matches org ADR-0004's stated pattern.
- **Bad, because** the extended preset reference cannot be SHA-pinned, so
  upstream-preset changes propagate without an intermediate consumer PR
  review. Mitigated by the framework template's own CI gating on preset
  changes and by Renovate's preset-resolution being deterministic per commit
  (a faulty preset would surface in every consumer's next Renovate run).

### Option 2: Keep the inlined local baseline (previous decision)

- **Good, because** every Renovate rule is locally visible and version-pinned
  in commit history.
- **Bad, because** stack-wide changes require N consumer PRs.
- **Bad, because** drift between consumers accumulates silently; the previous
  inlined config was already missing the framework template's supply-chain
  quarantine and several customManager improvements.

### Option 3: Hybrid mirror with drift-gate enforcement

- **Good, because** keeps byte-identity with the canonical preset.
- **Bad, because** drift-gate failures on consumer PRs now block on
  Renovate-internal changes that have nothing to do with the consumer's
  domain. Friction without security benefit.

## Confirmation

Adherence is confirmed by:

1. `.github/renovate.json5` `extends:` array contains
   `github>NWarila/terraform-framework-template//.github/renovate.json5`.
2. The local file contains no `enabledManagers`, `customManagers`,
   `schedule`, `minimumReleaseAge`, or general-Terraform/GitHub-Actions
   `packageRules` (those live upstream).
3. The local file's `packageRules` contains only consumer-specific entries
   (currently: the `NWarila/terraform-framework-template` SHA-pin
   automerge=false group).
4. Renovate's preview/dependency-dashboard runs reflect upstream-preset
   behavior after the first scheduled run.

## Consequences

### Positive

- Stack-wide Renovate changes ship to this consumer automatically.
- Local file is small, focused, and easy to review.
- Supply-chain quarantine, custom managers, and digest-pin discipline are
  inherited rather than duplicated.

### Negative

- Upstream preset changes are not visible to this repo until Renovate's next
  scheduled run; there is no per-consumer review checkpoint on preset bumps.
- A bad upstream-preset commit would propagate to every consumer
  simultaneously. Mitigated by the framework template's own CI.

### Neutral

- The reversibility is high: re-inlining the preset is a single
  `.github/renovate.json5` rewrite.

## Assumptions

1. `NWarila/terraform-framework-template/.github/renovate.json5` will continue
   to publish a working preset and won't be removed without notice.
2. Renovate continues to resolve `github>owner/repo//path` preset references
   without authentication for public repos.
3. The framework-template's own CI gates preset changes before they merge to
   `main`.

## Supersedes

The original ADR-0002 decision to inline a full local baseline (recorded in
this same file's previous content). The blocker that justified inlining
(missing upstream preset) is resolved.

## Superseded by

None (current).

## Implementing PRs

This ADR ships with the `.github/renovate.json5` rewrite that adopts the
extends pattern.

## Related ADRs

- [ADR-0004 (org)](../org/0004-use-renovate-for-dependency-updates.md) —
  establishes the desired shared-baseline pattern; this ADR's new decision
  realizes it.
- [ADR-0004 (repo)](0004-consume-terraform-template.md) — records the
  consumption of `NWarila/terraform-framework-template`; this ADR extends
  that consumption to Renovate.

## Compliance Notes

| Framework              | Control / Practice ID                           | Potential Evidence Contribution                                                                            |
| ---------------------- | ----------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| NIST SP 800-53 Rev. 5  | SI-2 (Flaw Remediation)                         | Inherited Renovate preset provides automated dependency-update visibility with fleet-wide consistency.     |
| NIST SP 800-218 (SSDF) | PW.4 (Reuse Existing, Well-Secured Software)    | Inherited digest pinning, exact-Terraform pinning, and supply-chain quarantine keep reused components tracked.  |

# ADR-template/0001: Pin Terraform and Provider Versions Exactly

| Field          | Value                                   |
| -------------- | --------------------------------------- |
| Status         | Accepted                                |
| Date           | 2026-05-06                              |
| Authors        | Nick Warila (@NWarila)                  |
| Decision-maker | Nick Warila (sole portfolio maintainer) |
| Consulted      | Terraform runner pinning ADR and provider lock policy. |
| Informed       | Derivative frameworks via baseline manifest. |
| Reversibility  | Medium                                  |
| Review-by      | N/A (Accepted)                          |

## TL;DR

Every framework derived from `NWarila/terraform-framework-template` MUST pin the Terraform CLI and every provider to exact versions. `terraform.required_version` uses `= X.Y.Z`, and every `required_providers` entry uses `version = "= X.Y.Z"`. Range constraints such as `>=`, `~>`, and open upper bounds are not used. Renovate updates those exact pins through reviewable PRs.

## Context and Problem Statement

Terraform frameworks are the executable infrastructure boundary in this portfolio. Runner repositories provide data and call a pinned framework, but the framework controls the Terraform module, provider graph, backend declaration, tests, generated docs, and deploy reusable.

Without exact pins, a framework can be tested with one Terraform or provider version and deployed with another. That weakens reproducibility and makes supply-chain review harder: a behavior change can enter through a tool update that never appeared in a source diff. Version ranges are common for broadly published community modules, but this portfolio mainly consumes modules and frameworks it owns. Cross-author constraint satisfiability is less important than deterministic, tested execution.

The org Renovate baseline deliberately leaves Terraform range strategy to the type-template tier. This framework template owns that stack-specific choice.

## Decision Drivers

1. **Reproducibility.** Framework CI and runner deploys should execute the same Terraform and provider versions.
2. **Supply-chain clarity.** Every version change should appear in a PR and pass the full validation surface before merge.
3. **Fast failure.** A user running the wrong Terraform CLI should fail during `terraform init`, not halfway through a plan or apply.
4. **Portfolio control.** The maintainer controls the frameworks and the consumers, so broad third-party module compatibility is not the dominant force.
5. **Renovate fitness.** Exact pins work cleanly with Renovate's `rangeStrategy: "pin"`.

## Considered Options

1. Exact pins for both Terraform CLI and providers.
2. Exact Terraform CLI pin with provider ranges.
3. Pessimistic ranges such as `~> X.Y`.
4. Minimum ranges such as `>= X.Y`.
5. No explicit constraints.

## Decision Outcome

Chosen option: **Option 1, exact pins for both Terraform CLI and providers.**

Frameworks derived from this template MUST:

- Set `terraform.required_version` to one exact version using `= X.Y.Z`.
- Set every provider version to one exact version using `= X.Y.Z`.
- Keep Renovate's Terraform `rangeStrategy` at `pin`.
- Treat a Terraform or provider bump as a dependency change that must pass CI before merge.
- Record any relaxation of this rule as a superseding repository-level ADR.

## Pros and Cons of the Options

### Option 1: Exact pins for both Terraform CLI and providers

- **Good, because** every run uses the versions CI exercised.
- **Good, because** dependency changes are explicit, reviewable, and auditable.
- **Good, because** failures from an unexpected local CLI version are immediate and clear.
- **Bad, because** consumers must update local tooling when the framework pin moves.
- **Bad, because** exact pins are less flexible if the framework is later consumed as a public third-party module.

### Option 2: Exact Terraform CLI pin with provider ranges

- **Good, because** the runtime is fixed.
- **Bad, because** provider behavior can still drift between test and deploy.
- **Bad, because** the mixed policy is harder to explain and review.

### Option 3: Pessimistic ranges

- **Good, because** patch releases can be consumed with less friction.
- **Bad, because** a compatible range is still wider than the exact version tested.

### Option 4: Minimum ranges

- **Good, because** it is easy for consumers to satisfy.
- **Bad, because** it claims compatibility with future versions that have not been tested.

### Option 5: No explicit constraints

- **Good, because** it imposes no version discipline.
- **Bad, because** it abandons reproducibility and makes incident analysis harder.

## Confirmation

1. `terraform/versions.tf` MUST use exact pins for `required_version` and every provider version.
2. The OPA `repo_hygiene` policy MUST reject non-exact Terraform and provider constraints.
3. `make ci` MUST run Terraform init, validate, tests, policy, docs, and manifest checks against the pinned versions.
4. Renovate PRs that change Terraform or provider versions MUST pass the same validation before merge.

## Consequences

### Positive

- CI, local development, and runner deploys converge on one tested toolchain.
- Dependency changes are easy to review and easy to roll back.
- The policy matches the portfolio's wider preference for immutable references and explicit updates.

### Negative

- Tool updates can require coordinated consumer changes.
- Exact pins create more Renovate PRs than wide ranges.

### Neutral

- External consumers that prefer ranges can fork or supersede this decision in their own repository tier.

## Assumptions

1. The portfolio continues to control both framework repositories and most consumers.
2. Renovate continues to support exact Terraform/provider updates.
3. The framework validation surface remains cheap enough to run on every dependency bump.

## Supersedes

None.

## Superseded by

None (current).

## Implementing PRs

- [`87323cd`](https://github.com/NWarila/terraform-framework-template/commit/87323cdbe7a9ae73508d9d00e9fe061f3a4d2474) introduced the exact-pinned synthetic framework baseline.
- [`a0641e2`](https://github.com/NWarila/terraform-framework-template/commit/a0641e28ccf9cae1c0a465040ff264b90c834458) updated provider pins to the published versions used by the first release.
- [#1](https://github.com/NWarila/terraform-framework-template/issues/1) / [`8f03db7`](https://github.com/NWarila/terraform-framework-template/commit/8f03db70875352c1d676f1618aef833d6974538f) added the drift-gated quality surface that keeps the pinning policy inherited by derivatives.

## Related ADRs

- [Org ADR-0004](../org/0004-use-renovate-for-dependency-updates.md) establishes Renovate as the dependency-update mechanism and leaves stack-specific Terraform range strategy to type-template ADRs.

## Compliance Notes

None.

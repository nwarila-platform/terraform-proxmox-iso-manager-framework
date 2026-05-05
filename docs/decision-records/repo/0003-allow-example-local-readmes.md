# ADR-0003: Allow Short Example-Local READMEs

| Field          | Value                                   |
| -------------- | --------------------------------------- |
| Status         | Accepted                                |
| Date           | 2026-05-05                              |
| Authors        | Nick Warila (@NWarila)                  |
| Decision-maker | Nick Warila (sole portfolio maintainer) |
| Consulted      | None.                                   |
| Informed       | None.                                   |
| Reversibility  | High                                    |
| Review-by      | N/A (Accepted)                          |

## TL;DR

Short `README.md` files are allowed inside `examples/` directories. They may orient a
reader to the local fixture goal and usage, but they must not become durable architecture,
reference, testing, or policy documentation. Long-form documentation remains governed by
the Diataxis structure under `docs/`.

## Context and Problem Statement

Org ADR-0002 adopts Diataxis for repository documentation. Terraform module repositories
also conventionally expose root-level `examples/` directories, and Terraform examples often
include a local `README.md` explaining what a specific example demonstrates.

Without an explicit repo decision, reviewers could interpret the Diataxis rule as banning
all non-`docs/` Markdown except the root `README.md`. That would make examples less
copyable and less useful for visitors evaluating the module quickly.

## Decision Drivers

1. Terraform's standard module structure recommends `examples/` for copyable usage.
2. Example readers need short fixture-local orientation.
3. Durable documentation still needs one governed home under `docs/`.
4. The deny-all `.gitignore` allowlist must make every exception explicit.

## Decision Outcome

Chosen option: allow short example-local READMEs with strict scope.

Rules:

- Example READMEs must be short.
- Example READMEs must not contain major architecture, reference, testing, or release-gate
  content.
- Example READMEs must link back to canonical docs under `docs/how-to/`,
  `docs/reference/`, or `docs/explanation/` when readers need durable documentation.
- Only the minimal example is required to be a complete standalone Terraform root. Other
  examples may be overlays or negative cases when that avoids duplicating version pins and
  provider boilerplate.
- Long-form documentation remains under `docs/`.

## Consequences

### Positive

- Examples remain copyable and understandable on their own.
- The Diataxis docs tree remains the source of durable documentation.
- The deny-all `.gitignore` can explicitly allow only the intended example files.

### Negative

- Reviewers must watch for example READMEs growing into hidden reference docs.

### Neutral

- This decision does not change ADR placement. ADRs still live under
  `docs/decision-records/org/` or `docs/decision-records/repo/`.

## Confirmation

Reviewers should reject changes that add long-form documentation to example READMEs. The
docs layout checker enforces `docs/` structure, while this ADR governs the explicit
exception for `examples/**/README.md`.

## Related ADRs

- [ADR-0002 (org)](../org/0002-adopt-diataxis-documentation-framework.md) - adopts the
  Diataxis documentation framework.
- [ADR-0003 (org)](../org/0003-use-deny-all-gitignore-strategy.md) - establishes explicit
  `.gitignore` allowlisting.

# Documentation

This directory follows the [Diátaxis](https://diataxis.fr) documentation framework per
[org ADR-0002](decision-records/org/0002-adopt-diataxis-documentation-framework.md).

## Quadrants

| Quadrant                       | Purpose                                          | When to read |
|--------------------------------|--------------------------------------------------|--------------|
| [reference/](reference/)       | Look up specific facts about the module's contract | "What does input X do?" |
| [how-to/](how-to/)             | Step-by-step guides for goal-directed tasks       | "How do I use this from a Packer template?" |
| [explanation/](explanation/)   | Conceptual background and rationale               | "What's the threat model?" |

This module does not currently ship learning-oriented `tutorials/`. Consumers of a
single-purpose Terraform module typically read reference + how-to material rather
than following a structured tutorial.

## Architecture Decision Records

ADRs live in their own subtree at [`decision-records/`](decision-records/) and are
governed by [org ADR-0001](decision-records/org/0001-use-architecture-decision-records.md).
ADRs are not subject to the Diátaxis quadrant rule (per the Co-existence rule in
org ADR-0002 §Confirmation §4).

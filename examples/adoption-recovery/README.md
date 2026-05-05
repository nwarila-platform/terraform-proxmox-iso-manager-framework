# Adoption And Recovery Example

This is not normal operation.

Start from [`../minimal/`](../minimal/) and add the single argument shown in `main.tf` only
when an operator has confirmed that a same-name unmanaged ISO already present in Proxmox
storage should be deleted and replaced by the reviewed pin. The normal default is
`overwrite_unmanaged = false`, which fails closed when a same-name unmanaged ISO exists.

This directory intentionally does not repeat the Terraform/provider version block; the
minimal example is the canonical copyable root.

For the safety rationale, see
[Architecture](../../docs/explanation/architecture.md) and
[Threat model](../../docs/explanation/threat-model.md).

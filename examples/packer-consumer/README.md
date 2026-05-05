# Packer Consumer Example

Shows the intended handoff after starting from
[`../minimal/`](../minimal/): Terraform pins, downloads, and verifies the ISO on Proxmox,
then emits values that a Packer template repository can write into `*.pkrvars.hcl`.

This directory intentionally does not repeat the Terraform/provider version block; the
minimal example is the canonical copyable root. Real consumers own Packer plugin pins and
full builder settings. See
[Use from a Packer template](../../docs/how-to/use-from-a-packer-template.md).

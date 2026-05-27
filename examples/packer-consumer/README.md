# Packer Consumer Example

Shows the intended handoff after starting from
[`../minimal/`](../minimal/): Terraform pins, downloads, and verifies the ISO on Proxmox,
then emits a `boot_iso` object that a Packer template repository writes into an
auto-loaded pkrvars file (e.g. `iso.auto.pkrvars.hcl`).

The shape of the emitted object matches the `boot_iso` variable type declared by
[`nwarila-platform/proxmox-packer-framework`](https://github.com/nwarila-platform/proxmox-packer-framework)
in `packer/variables.pkr.hcl`. The example pre-populates ISO-lifecycle fields from this
module's outputs and defaults the consumer-policy fields (`type`, `index`, `unmount`,
`cd_label`, `keep_cdrom_device`) to the values used by the proxmox-packer-framework
examples. Consumers needing other values should override at their own consumer repo.

This directory intentionally does not repeat the Terraform/provider version block; the
minimal example is the canonical copyable root. Real consumers own Packer plugin pins and
full builder settings. See
[Use from a Packer template](../../docs/how-to/use-from-a-packer-template.md).

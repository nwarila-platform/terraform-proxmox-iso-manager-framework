# Minimal Example

Smallest normal consumer shape: configure the Proxmox provider, call the module from a
pinned release tag, and pass `module.iso.iso_path` to downstream tooling.

Consumers should pin `source` to a release tag, not a branch. For the complete contract,
see [Terraform reference](../../docs/reference/terraform.md) and
[Packer usage](../../docs/how-to/use-from-a-packer-template.md).

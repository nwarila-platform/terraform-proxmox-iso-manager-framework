# Packer Consumer Example

This fixture mirrors the intended per-OS template repository pattern:

1. Terraform pins and manages the ISO on Proxmox.
2. Terraform emits Packer-facing values as outputs.
3. Packer consumes `iso_file` and `iso_checksum` from a `*.pkrvars.hcl` file or an
   equivalent generated variable source.

The included `build.pkr.hcl` is intentionally minimal. It demonstrates the variable
contract without trying to build a full OS image. A real consumer repo owns its Packer
plugin pins and complete builder settings.

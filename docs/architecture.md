# Architecture

This repository is a Terraform child module, not a root environment. Its responsibility
is intentionally narrow:

1. Accept a reviewed ISO pin from a consumer repository.
2. Ask Proxmox VE to download that ISO into the selected storage datastore.
3. Require SHA-256 verification before the file is accepted.
4. Return the Proxmox `iso_file` path that Packer consumers need.

## Boundaries

The consumer repository owns provider credentials, backend configuration, Packer builder
settings, and the long-lived audit trail for ISO changes. This module owns only the
Proxmox-side ISO file lifecycle for a single pinned file.

```text
consumer repo iso_pin
        |
        v
terraform child module
        |
        v
proxmox_download_file.iso
        |
        v
<storage>:iso/<filename>
        |
        v
packer iso_file
```

## Safety Defaults

- TLS verification is always enabled for the Proxmox download-url operation.
- `overwrite` defaults to `false`.
- `overwrite_unmanaged` defaults to `false`.
- Tokenized or signed URLs are rejected before planning.
- SHA-256 is the only checksum algorithm used by the managed resource.

See [Threat Model](explanation/threat-model.md) for the security boundary and
[Terraform Reference](reference/terraform.md) for the exact input/output contract.

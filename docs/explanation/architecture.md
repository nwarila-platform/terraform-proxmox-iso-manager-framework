# Architecture

This repository is a narrow Terraform child module. It manages one Proxmox ISO download
from one Git-tracked pin and returns the values a downstream Packer template build needs.

The module is intentionally small, but the repository around it is treated like a small
production platform component: exact tool pins, validation tests, security gates, graph
evidence, release evidence, and ADR-governed documentation.

## Responsibility Boundary

| Owner | Responsibility |
|---|---|
| Consumer repository | Owns provider configuration, backend configuration, credentials, Packer builder settings, and the reviewed ISO pin. |
| This module | Validates the pin, asks Proxmox to download the ISO, requires SHA-256 verification, and emits Packer-facing outputs. |
| Proxmox VE | Performs the download-url operation, stores the ISO in the selected datastore, and reports the managed file state back to Terraform. |
| Packer template repo | Renders `iso_path` and `iso_sha256` into the `boot_iso` object and empty `additional_iso_files` list expected by [`nwarila-platform/proxmox-packer-framework`](https://github.com/nwarila-platform/proxmox-packer-framework). |

```text
consumer repo
  iso_pin = { url, sha256, filename }
        |
        v
terraform apply
        |
        v
this child module
  - validates URL, checksum, filename, node, storage
  - calls proxmox_download_file.iso
  - requires verify = true and checksum_algorithm = "sha256"
        |
        v
Proxmox VE storage
  <storage>:iso/<filename>
        |
        v
Packer consumer (proxmox-packer-framework)
  boot_iso = {
    iso_checksum = "sha256:${module.iso.iso_sha256}"
    iso_file     = module.iso.iso_path
    ...
  }

  additional_iso_files = []
```

## ISO Pin Flow

The ISO pin lives in the consumer repository because that repository is the durable audit
trail for the OS template. Changing an installer ISO should be reviewed in the same place
as the template build that will consume it. The child module receives the pin as data; it
does not decide which operating system release should be used.

The pin contains:

- `url`: a non-tokenized HTTPS URL with a host and path.
- `sha256`: the expected SHA-256 digest.
- `filename`: the simple on-disk `.iso` filename in Proxmox storage.

The module outputs the same provenance values back to consumers so release notes,
attestations, or Packer variable files can record exactly which ISO fed a template build.

## Proxmox API Flow

The module manages a single `proxmox_download_file` resource. Proxmox receives the URL,
filename, target node, datastore, SHA-256 digest, and timeout. Proxmox performs the remote
download; the Terraform CLI does not stream the ISO bytes.

The resource sets:

- `content_type = "iso"`
- `checksum_algorithm = "sha256"`
- `verify = true`
- `overwrite_unmanaged = var.overwrite_unmanaged`
- `upload_timeout = var.upload_timeout`

## Output Contract

The most important output is `iso_path`, shaped as `<storage>:iso/<filename>`. That is the
format expected by Packer's Proxmox ISO builder. The module also emits the SHA-256 digest,
filename, non-tokenized URL, family, node, and storage values for downstream provenance.

## Safety Defaults

`overwrite_unmanaged` defaults to `false` because an unmanaged same-name ISO is ambiguous.
It might be a manual operator artifact, a stale build input, or evidence of drift. Normal
operation should fail closed so a person can decide whether to import, rename, or delete
the existing file.

The explicit adoption path is documented in
[`../../examples/adoption-recovery/`](../../examples/adoption-recovery/). That example is
not normal operation.

## Credentials

The module does not own Proxmox credentials. Credentials are provider configuration, and
provider configuration belongs to the root consumer repository or its CI/runtime
environment. This keeps the child module reusable and avoids creating another secret
surface in module inputs, outputs, plans, or state.

## Threat Boundary

Upstream ISO trust is outside this module's threat model. The module can verify that the
downloaded bytes match the supplied SHA-256 digest, but it cannot prove the digest itself
came from a trustworthy channel. Consumers must source checksums from upstream release
channels they trust, ideally separately from the ISO mirror URL.

Tokenized, presigned, or credential-bearing URLs are intentionally rejected because
Terraform plans, state, logs, and outputs are not a safe place for bearer tokens.

## Non-Goals

- Manage more than one ISO per module instance.
- Own Proxmox credentials, backend configuration, or provider aliases.
- Select upstream OS releases on behalf of consumers.
- Validate a distribution's release signing process.
- Build or configure Packer templates directly.
- Replace consumer-level policy about which OS releases are approved.

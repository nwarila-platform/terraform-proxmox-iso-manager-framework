# Module Reference

> Hand-maintained until `terraform-docs` is wired into pre-commit. Once wired,
> this file will be auto-generated from the HCL in [`../../terraform/`](../../terraform/);
> hand edits will be overwritten on the next generation.

## Requirements

| Requirement                         | Version    |
|-------------------------------------|------------|
| Terraform                           | `= 1.9.8`  |
| `bpg/proxmox` provider              | `= 0.98.1` |

Both are exact-pinned per
[org ADR-0005](../decision-records/org/0005-pin-terraform-and-provider-versions-exactly.md).
Consumers MUST run Terraform 1.9.8 exactly; `terraform init` fails on any other version.

## Inputs

| Name        | Type                                       | Default      | Description |
|-------------|--------------------------------------------|--------------|-------------|
| `family`    | `string`                                   | required     | Template family discriminator (e.g. `rocky9`). **Provenance-only** — echoed back through the `family` output, not consumed by any resource. Must match `[a-z0-9._-]+`. |
| `iso_pin`   | `object({ url, sha256, filename })`        | required     | The ISO to manage. `url` must be HTTPS; `sha256` must be a 64-char lowercase hex digest; `filename` must end in `.iso` and contain no path components or whitespace. |
| `node`      | `string`                                   | required     | Proxmox node name on which the download is performed. Non-empty. |
| `storage`   | `string`                                   | required     | Proxmox storage datastore (e.g. `cephFS`, `local`). Must have ISO content type enabled. Non-empty. |
| `overwrite` | `bool`                                     | `false`      | When true, replace any pre-existing file at the target path even if no SHA mismatch is detected. Use only for explicit recovery. |

### Validation rules

Every input has at least one validation block (see [`../../terraform/variables.tf`](../../terraform/variables.tf) and the test coverage in [`../../terraform/tests/validation.tftest.hcl`](../../terraform/tests/validation.tftest.hcl)):

- `family`: lowercase letters, digits, hyphens, dots, underscores only.
- `iso_pin.url`: HTTPS scheme only — `http://`, `ftp://`, `file://` are rejected.
- `iso_pin.sha256`: exactly 64 lowercase hex characters.
- `iso_pin.filename`: a simple filename ending in `.iso`, no path traversal, no whitespace.
- `node`: non-empty after trimming whitespace.
- `storage`: non-empty after trimming whitespace.

Validation runs at `terraform plan` time, before any provider initialisation.

## Outputs

| Name           | Type     | Description |
|----------------|----------|-------------|
| `iso_id`       | `string` | Proxmox file ID `<datastore>:<volume_id>`. The canonical identifier the bpg/proxmox provider uses to reference the file. |
| `iso_path`     | `string` | `<storage>:iso/<filename>`. Pass directly into Packer's `iso_file` field. |
| `iso_sha256`   | `string` | SHA-256 digest of the managed ISO. Echoed back from input for provenance. |
| `iso_url`      | `string` | Upstream URL the ISO was downloaded from. Echoed back for provenance. |
| `iso_filename` | `string` | On-disk filename of the managed ISO. Echoed back. |
| `family`       | `string` | Template family discriminator. Echoed back. |
| `node`         | `string` | Proxmox node where the download was performed. |
| `storage`      | `string` | Proxmox storage datastore the ISO landed on. |

## Resources

| Type                    | Name | Provider          |
|-------------------------|------|-------------------|
| `proxmox_download_file` | `iso` | `bpg/proxmox`    |

The single resource is created with `for_each = {}` semantics implicit in a one-shot child module: each `module "iso"` instantiation yields exactly one `proxmox_download_file.iso` resource.

## Local values

The module declares one local value:

- `iso_path = "${var.storage}:iso/${var.iso_pin.filename}"` — assembled in [`../../terraform/locals.tf`](../../terraform/locals.tf) so [`outputs.tf`](../../terraform/outputs.tf) stays declaration-only.

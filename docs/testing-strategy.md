# Testing Strategy

The module uses Terraform's native test framework with `mock_provider "proxmox"` so the
input contract can be tested without a live Proxmox cluster.

## What Is Tested

- Valid inputs produce the expected output shape.
- Safety flags fail closed by default.
- TLS verification is explicitly enabled on the managed resource.
- URL validation rejects non-HTTPS, missing-host, missing-path, whitespace, query-string,
  and fragment forms.
- SHA-256 validation rejects short, uppercase, and non-hex digests.
- Filename validation rejects non-ISO names, path traversal, subdirectories, and spaces.
- Node and storage validation reject empty, whitespace-only, and path-like values.
- Upload timeout validation enforces the supported range.
- Runnable example fixtures initialize and validate as Terraform root modules.

## What Is Not Tested Here

The test suite does not contact Proxmox, download real ISO files, or validate consumer
Packer builder settings. Those are root-repository concerns. This child module tests the
contract it can own deterministically and validates example root-module shape.

## Local Command

```bash
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform test
```

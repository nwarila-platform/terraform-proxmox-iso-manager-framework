# Module Invariants

These rules must remain true unless a future ADR explicitly changes the module contract.

## Terraform contract

- The module remains a child module under `terraform/`.
- The module manages exactly one installer ISO per module instance.
- The module exposes a Packer-compatible ISO path through `output.iso_path`.
- Public input and output names remain stable across patch and minor releases.
- Terraform and provider versions remain exact-pinned unless the version policy changes by ADR.

## Safety contract

- `overwrite` defaults to `false`.
- `overwrite_unmanaged` defaults to `false`.
- Adoption of a same-named unmanaged ISO requires explicit opt-in.
- TLS verification for the Proxmox download operation remains enabled.
- SHA-256 remains the checksum algorithm.
- Query strings, URL fragments, whitespace, path traversal, non-HTTPS schemes, missing hosts, missing paths, and credential-bearing URLs remain rejected.
- Terraform state, plan files, logs, outputs, and release artifacts are not valid places for credentials, tokens, signed URLs, or private infrastructure values.

## Testing contract

- Terraform tests do not require a live Proxmox cluster.
- Tests cover accepted inputs, rejected inputs, safety defaults, and TLS verification.
- `make ci` remains the canonical local validation entrypoint.
- `make graph` remains the graph-validation entrypoint.
- Failure-case examples are documented but are not treated as normal runnable examples.

## Documentation contract

- Generated Terraform reference tables are injected into `docs/reference/terraform.md`.
- Security boundaries live in `docs/explanation/threat-model.md`.
- Release gates live in `docs/reference/release-gates.md`.
- Template reuse standards live in `docs/reference/golden-template-contract.md`.
- Adoption steps live in `docs/how-to/adopt-this-template.md`.

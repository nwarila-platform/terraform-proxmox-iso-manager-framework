# Threat Model

This document explains what is and is not in the security scope of
`terraform-proxmox-iso-manager-framework`. For the formal vulnerability-reporting
policy, see the repository's
[Security Policy](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/security/policy),
inherited from the organization's special `.github` repository.

## What this module guarantees

- The ISO that lands at `<storage>:iso/<filename>` matches the SHA256 the consumer
  provided in `iso_pin.sha256`. The bpg/proxmox provider's `proxmox_download_file`
  resource enforces this server-side after the file lands.
- The ISO is downloaded over a non-tokenized HTTPS URL only. The `iso_pin.url` validation
  block in [`terraform/variables.tf`](../../terraform/variables.tf) rejects non-HTTPS
  schemes, missing hosts, missing paths, whitespace, query strings, fragments, and
  embedded credentials; test coverage in
  [`terraform/tests/validation.tftest.hcl`](../../terraform/tests/validation.tftest.hcl)
  verifies those rejection paths.
- The download is performed by Proxmox, not by the Terraform CLI host. The Terraform
  CLI never sees the ISO bytes; it only sends the URL + SHA + filename to the Proxmox
  API.
- Inputs that fail validation are rejected at `terraform plan` time, before any network
  call is made. Failed validation produces a clear error naming the failing input.
- The module pins Terraform and providers to exact versions in
  [`../../terraform/versions.tf`](../../terraform/versions.tf), so every consumer
  runs the exact CLI/provider build the maintainer tested with. Version drift is
  not a vector here.

## What this module does NOT guarantee

- **Upstream ISO integrity.** This module trusts the SHA256 the consumer provides. If
  the consumer pins a SHA that corresponds to a malicious ISO (e.g., copied from a
  compromised source), the module will faithfully download and verify that malicious
  ISO. The consumer is responsible for sourcing trustworthy SHA256 values from upstream
  distribution channels (Rocky Linux's signed `CHECKSUM` file, Ubuntu's signed
  `SHA256SUMS` file, etc.) — and ideally from a different channel than the URL itself.
- **Proxmox API authentication confidentiality.** This module assumes the bpg/proxmox
  provider is configured with credentials managed by the consumer. The module itself
  does not handle secrets. Credentials in `terraform.tfvars`, environment variables, or
  a secret manager are out of scope.
- **Proxmox cluster security.** This module assumes the Proxmox cluster is configured
  securely. Misconfigurations at the Proxmox layer (open ISO storage, weak API tokens,
  exposed admin endpoints) are out of scope.
- **Network path security.** TLS confidentiality and integrity between the consumer's
  Terraform CLI and the Proxmox API are the responsibility of the consumer's network
  configuration. The bpg/proxmox provider's `insecure = true` flag is an antipattern;
  this module's documentation does not encourage its use.

## Attacker model

This module assumes the following adversaries:

- **Network attacker between Proxmox and the upstream ISO source.** Mitigated by
  HTTPS-only download and server-side SHA256 verification. An attacker cannot substitute
  a different ISO without breaking SHA256.
- **Compromised upstream ISO mirror.** Partially mitigated. If the consumer pinned a
  SHA from a separately-trusted source (e.g., the upstream's signed CHECKSUM file
  fetched over a different channel), a compromised mirror cannot serve a different ISO.
  If the consumer pinned the SHA from the same mirror as the URL, this attacker is out
  of scope.
- **Compromised Terraform CLI host.** Out of scope. A compromised CLI host can modify
  the `iso_pin` object before it reaches the module; the module trusts its inputs.
  Defense-in-depth at this layer is the consumer's responsibility (host hardening,
  credential storage, code review).
- **Secret-bearing URL path segments.** Mitigated only by convention and review. The
  module rejects query strings, fragments, and embedded credentials because those are
  common locations for signed URL material, but it cannot prove that a URL path segment is
  not itself secret. Consumers must not place tokens in ISO URLs.
- **Compromised Proxmox node.** Out of scope. A compromised Proxmox node can return any
  state the module observes; the trust boundary is at the Proxmox API.

## Defense-in-depth controls in this module

- **Non-tokenized HTTPS-only `iso_pin.url`** (validation block in
  [`variables.tf`](../../terraform/variables.tf)).
- **64-character lowercase hex SHA256 enforcement** (validation block).
- **Filename character constraint** rejects path traversal, subdirectories, and
  whitespace (validation block); test coverage verifies rejection of `../foo.iso`,
  `subdir/foo.iso`, `foo bar.iso`, and `foo.img`.
- **Family character constraint** matches Proxmox tag character constraints (validation
  block).
- **`node` and `storage` character constraints** reject path-like values.
- **No secrets in module inputs.** The module intentionally rejects tokenized, presigned,
  or credential-bearing ISO URLs because Terraform state, plans, logs, and outputs are not
  safe storage for bearer tokens. All Proxmox credentials are handled by the bpg/proxmox
  provider configuration upstream of this module.
- **Explicit Proxmox download TLS verification** via `verify = true` on the managed
  resource.
- **No state-modifying side effects beyond `proxmox_download_file`.** The module's
  surface area is intentionally minimal: one resource, one local, eight outputs.

## Related security controls outside this module

- The repository's CI runs Trivy (filesystem misconfig + secret scan), Gitleaks
  (commit-history secret scan), CodeQL (Actions analysis), and actionlint (workflow
  lint) on every push and PR.
- GitHub Actions workflows are SHA-pinned per the org policy.
- Terraform and provider versions are exact-pinned in
  [`../../terraform/versions.tf`](../../terraform/versions.tf).
- Renovate (configured per [org ADR-0004](../decision-records/org/0004-use-renovate-for-dependency-updates.md))
  keeps SHA pins and version pins current with weekly PRs that the maintainer reviews
  and tests before merging.
- The variable validation rules described above are exercised on every PR by the
  `terraform test` step in `.github/workflows/ci.yaml`. A regression that
  weakens any validation block is detected at PR time, not in production.

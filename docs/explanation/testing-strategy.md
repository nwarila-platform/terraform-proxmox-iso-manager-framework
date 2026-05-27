# Testing Strategy

The test strategy is contract-focused. This is a Terraform child module with one
Proxmox-managed resource, so the highest-value tests are input validation, safe defaults,
resource arguments, graph shape, and release gates.

## What Is Tested

- Terraform formatting, initialization, and validation for the module.
- Terraform validation tests in [`../../terraform/tests/validation.tftest.hcl`](../../terraform/tests/validation.tftest.hcl).
- `mock_provider "proxmox"` usage so tests do not require a live Proxmox API.
- Positive tests for a valid ISO pin and default timeout behavior.
- Negative tests for malformed URLs, embedded credentials, invalid checksums, unsafe
  filenames, unsafe node/storage values, and out-of-range upload timeouts.
- Safety defaults for `overwrite`, `overwrite_unmanaged`, and `verify`.
- Graph generation for local-source consumer fixtures.
- Strongly connected component cycle detection against Terraform DOT graphs.
- Security scans through CodeQL, Trivy, Gitleaks, and workflow linting.
- Documentation layout enforcement for the Diataxis tree and ADR locations.

The examples under `examples/` are optimized for human readability. Only
`examples/minimal/` is a complete copyable Terraform root; the other example directories
are focused overlays or negative cases so exact version pins are not repeated throughout
the tree. CI graph validation uses the root fixtures under `tests/fixtures/`.

## Mocked Behavior

Terraform tests use `mock_provider "proxmox"` because the module's deterministic contract
can be validated without contacting a real Proxmox cluster. Variable validation runs before
provider operations, and mock resources still allow assertions against planned resource
arguments such as `verify`, `checksum_algorithm`, and `upload_timeout`.

Mocking keeps normal CI portable. Reviewers can see the exact input contract without
needing homelab credentials or a reachable Proxmox endpoint.

## Negative Input Tests

The rejection tests are part of the security boundary. They cover:

- Non-HTTPS URLs.
- Missing URL host or path.
- Whitespace in URLs.
- Query strings and fragments.
- Embedded URL credentials.
- Non-lowercase or malformed SHA-256 strings.
- Filenames with paths, traversal, whitespace, or non-ISO extensions.
- Node and storage names containing path separators, colons, whitespace, or shell
  metacharacters.
- Upload timeouts below 60 seconds or above 86400 seconds.

## Security Scans

Security scans are not substitutes for Terraform tests. They are release gates that catch
different classes of failure:

- CodeQL analyzes GitHub Actions workflow code.
- Trivy scans repository filesystem, misconfiguration, and secrets.
- Gitleaks scans history for secrets.
- actionlint checks workflow syntax and common expression mistakes.

## Why There Is No Line Coverage Percentage

Terraform modules do not produce a useful line-coverage percentage. The meaningful signal
is whether the public contract, safety defaults, generated docs, graph shape, and release
gates still pass. A coverage badge would imply precision the toolchain does not provide.

## Outside Normal CI

Real download behavior requires a Proxmox environment with:

- A reachable API endpoint.
- Valid credentials.
- A configured datastore with ISO content enabled.
- Egress from the Proxmox node to the upstream ISO source.
- Enough storage and timeout budget for large ISO downloads.

Those checks belong in a consumer environment or a dedicated integration lab, not in this
repository's normal PR CI.

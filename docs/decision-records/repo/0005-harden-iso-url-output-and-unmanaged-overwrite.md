# ADR-0005: Harden the iso_url Output and the overwrite_unmanaged Path

| Field          | Value                                    |
| -------------- | ---------------------------------------- |
| Status         | Accepted                                 |
| Date           | 2026-05-28                               |
| Authors        | Nick Warila (@NWarila)                   |
| Decision-maker | Nick Warila (sole portfolio maintainer)  |
| Consulted      | External adversarial review (Deep Research). |
| Informed       | Downstream Packer-template consumers.    |
| Reversibility  | Medium (a major version revert)          |
| Review-by      | N/A (Accepted)                           |

## TL;DR

Two module-interface hardening changes, both **backwards-incompatible** and
therefore shipped as a major version bump:

1. The `iso_url` output now returns `null` unless the new `expose_iso_url`
   variable is set `true`, and is always marked `sensitive`.
2. Setting `overwrite_unmanaged = true` now also requires the new
   `adopt_unmanaged_confirmation` variable to equal `iso_pin.filename`,
   enforced by a precondition on the managed resource.

## Context and Problem Statement

An external adversarial review of the module surfaced two soft spots that are
not classical IaC bugs but are the two places where an operator can hurt
themselves:

1. **`iso_url` disclosure.** The module validation rejects query strings,
   fragments, and embedded credentials in `iso_pin.url` precisely because those
   are common signed-URL/token locations. But it cannot prove that a URL *path
   segment* (e.g. `/private/ABC123/file.iso`) is not itself secret. The old
   `iso_url` output echoed the URL unconditionally and non-sensitively, so a
   path-embedded token would land in plan output and in state read by
   downstream tooling.

2. **`overwrite_unmanaged` blast radius.** Setting `overwrite_unmanaged = true`
   makes the provider delete a same-named unmanaged file before writing the
   managed one. The flag is a deliberate recovery affordance, but the only
   friction was its `false` default. An accidental `true` (copied from another
   module instance, flipped during debugging) would silently delete an
   unmanaged ISO.

## Decision Drivers

1. Reduce accidental disclosure of potentially-secret URL material without
   removing the provenance affordance entirely.
2. Add real friction to a destructive operation, proportional to its blast
   radius, without removing the recovery path.
3. Keep the change mechanically detectable and testable.
4. Accept a major version bump rather than weaken either control to preserve
   backwards compatibility.

## Decision Outcome

### `iso_url` output (P1a)

- New variable `expose_iso_url` (`bool`, default `false`).
- `output.iso_url` returns `var.expose_iso_url ? var.iso_pin.url : null` and is
  marked `sensitive = true`.
- Consumers that genuinely need the URL for provenance opt in explicitly; the
  recommended correlation keys remain `iso_sha256` + `iso_filename`, which are
  not secret.

### `overwrite_unmanaged` precondition (P1b)

- New variable `adopt_unmanaged_confirmation` (`string`, default `""`).
- A `precondition` on `proxmox_download_file.iso` requires
  `!var.overwrite_unmanaged || var.adopt_unmanaged_confirmation == var.iso_pin.filename`.
- The destructive flag therefore cannot be enabled without the operator naming
  the exact file being deleted.

## Backwards Compatibility

This is a **breaking change** for two consumer patterns:

1. Consumers reading `module.iso.iso_url` now get `null` unless they add
   `expose_iso_url = true`. The documented pkrvars flow uses `iso_sha256` and
   `iso_path`, not `iso_url`, so most consumers are unaffected — but any
   consumer that read `iso_url` must opt in.
2. Consumers running `overwrite_unmanaged = true` must add a matching
   `adopt_unmanaged_confirmation` or their next plan fails the precondition.

### Migration

| Old usage | New usage |
| --- | --- |
| `module.iso.iso_url` consumed downstream | add `expose_iso_url = true` to the module call; the output is now `sensitive` (use `nonsensitive()` only where unavoidable) |
| `overwrite_unmanaged = true` | also set `adopt_unmanaged_confirmation = "<exact iso_pin.filename>"` |

The major version bump is signaled to release-please via a `feat!:` commit; the
tag and CHANGELOG entry mark the break.

## Confirmation

`terraform test` (`terraform/tests/validation.tftest.hcl`) covers:

- `iso_url_hidden_by_default` — output is null without opt-in.
- `iso_url_exposed_when_opted_in` — output returns the URL with `expose_iso_url = true`.
- `overwrite_unmanaged_requires_confirmation` — precondition fires when the flag is
  true and confirmation is empty.
- `overwrite_unmanaged_rejects_mismatched_confirmation` — precondition fires on a
  non-matching confirmation.
- `overwrite_unmanaged_accepts_matching_confirmation` — passes when confirmation
  equals the filename.

43 test runs pass under Terraform 1.15.2.

## Consequences

### Positive

- Path-embedded secrets are no longer casually disclosed via `iso_url`.
- The destructive recovery path now demands explicit, file-specific intent.
- Both controls are enforced in code and exercised by tests.

### Negative

- Breaking change; downstream consumers must take the migration steps above.
- `expose_iso_url` adds one more knob to the interface.

### Neutral

- The recovery path still exists; the change adds friction, not removal.

## Related ADRs

- [ADR-0001 (repo)](0001-terraform-subdirectory-layout.md) — module layout.
- The threat model ([`docs/explanation/threat-model.md`](../../explanation/threat-model.md))
  records both controls under defense-in-depth.

## Compliance Notes

| Framework              | Control / Practice ID                        | Potential Evidence Contribution                                            |
| ---------------------- | -------------------------------------------- | -------------------------------------------------------------------------- |
| NIST SP 800-53 Rev. 5  | SC-28 (Protection of Information at Rest)    | `iso_url` suppression reduces secret material written to Terraform state.  |
| NIST SP 800-53 Rev. 5  | CM-5 (Access Restrictions for Change)        | `adopt_unmanaged_confirmation` adds change friction to a destructive path. |
| NIST SP 800-218 (SSDF) | PW.9 (Configure Software with Secure Settings) | Safe-by-default output + fail-closed destructive flag.                   |

# Mirroring And Consumer Baseline

This template is intentionally split into three layers so derivative frameworks
can stay easy to use without losing the deeper platform controls.

## Required Shared Baseline

Derivative frameworks should mirror the files listed under
`byte_identical` in [`baseline-manifest.json`](../../baseline-manifest.json).
That set is the stable scaffold: repository hygiene, docs layout checks, drift
manifest validation, security callers, reusable deploy validation, universal
OPA policy, and the Python verification entrypoint.

The `scaffold_starter` category documents starter files that are useful when a
new derivative is born but should be rewritten for its real providers. Drift
gate validates those entries as part of the manifest contract, but it does not
byte-compare them in consumers.

Use `byte_identical` only for files a downstream framework should keep
byte-for-byte with this template. Use `scaffold_starter` for examples, fixtures,
and implementation seeds that demonstrate the pattern but are expected to change
in a real framework.

## Framework-Owned Layer

The `terraform/` implementation, examples, provider choices, and framework ADRs
are allowed to diverge. This reference uses synthetic providers so the pattern is
visible without cloud accounts; real frameworks replace that Terraform code with
provider-specific resources while preserving the same validation interface.

## Optional Release Layer

`release.yaml`, release-please config, release evidence, and trusted-bot
auto-merge are supported by this template, but downstream frameworks do not have
to mirror them byte-for-byte. Keep that layer when the repo publishes versioned
releases. Drop it when the repo is only a private implementation detail.

## New Framework Checklist

1. Rewrite `README.md` for the real framework.
2. Replace the synthetic Terraform under `terraform/`.
3. Update examples and generated Terraform docs.
4. Rewrite any `scaffold_starter` policy for the real provider surface.
5. Decide whether to keep the optional release layer.
6. Run `python tools/verify.py verify`.

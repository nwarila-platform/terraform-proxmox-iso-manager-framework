## Summary

<!-- One or two sentences describing what this PR changes and why. -->

## Type

- [ ] feat: new capability or input/output
- [ ] fix: bug fix
- [ ] security: security-relevant change
- [ ] refactor: internal cleanup, no consumer-visible behavior change
- [ ] ci: CI/CD or repository tooling change
- [ ] docs: documentation only

## Breaking change?

- [ ] No — consumers can bump their `?ref=` pin without code changes.
- [ ] Yes — this PR includes a `BREAKING CHANGE:` footer in at least one commit and
      describes the migration path below.

<!-- If yes, describe what consumers must change. -->

## Test plan

- [ ] `terraform fmt -recursive .` clean
- [ ] `terraform init -backend=false && terraform validate` clean
- [ ] README updated if inputs/outputs/contract changed

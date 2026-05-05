# Release Gates

Every pull request and main-branch merge is expected to leave behind public evidence in
GitHub Actions.

## Current Gates

| Gate | Evidence |
|---|---|
| Terraform format, init, validate, and test | `PR Validation` workflow |
| Runnable example initialization and validation | `PR Validation` workflow |
| Workflow linting | `Repo CI` workflow |
| Markdown linting | `Repo CI` workflow |
| CodeQL Actions analysis | `CodeQL Analysis` workflow |
| Trivy filesystem, misconfiguration, and secret scan | `Security Scan` workflow |
| Gitleaks history scan | `Security Scan` workflow |
| SemVer tags and GitHub releases | `Release Please` workflow |

Release Please publishes the release notes and tag after a qualifying merge to `main`.
Non-user-facing maintenance types are hidden from generated changelogs so the release
history stays focused on consumer-impacting changes.

## Deferred Evidence

The next evidence layer should add generated graph artifacts and a release evidence
bundle. Those should publish workflow artifacts, not Terraform state, plans, tfvars, or
provider caches.

# Release Gates

Every release should leave behind enough evidence for a reviewer to understand what was
validated and what would have blocked publication.

| Gate | Tool | Evidence file | Blocks release? | Notes |
|---|---|---|---|---|
| terraform fmt | `terraform fmt -check -recursive` | `summary.md` command result | Yes | Enforces stable HCL formatting. |
| terraform init -backend=false | `terraform init` | `summary.md` command result | Yes | Initializes providers without backend or state. |
| terraform validate -json | `terraform validate -json` | `validate/terraform.validate.json` | Yes | Stores machine-readable validation output. |
| terraform test | `terraform test` | `tests/terraform-test.json` | Yes | Uses `mock_provider` for Proxmox. |
| markdown lint | `markdownlint-cli2` | Repo CI workflow logs | Yes | Keeps docs readable without adding generated docs noise. |
| workflow lint | `actionlint` | Repo CI workflow logs | Yes | Checks GitHub Actions syntax and expressions. |
| CodeQL Actions analysis | CodeQL | Security tab / CodeQL workflow | Yes | Analyzes GitHub Actions workflows. |
| Trivy filesystem/misconfiguration/secret scan | Trivy | Security Scan workflow / SARIF | Yes | Scans repo contents, misconfig, and secrets. |
| Gitleaks secret scan | Gitleaks | Security Scan workflow logs | Yes | Scans history with redaction. |
| Terraform graph generation | `terraform graph`, Graphviz | `graphs/*.plan.dot`, `graphs/*.plan.svg` | Yes | Normal fixtures must render successfully. |
| Dependency cycle detection | `tools/tf_graph_cycles.py` | `graphs/*.cycles.json` | Yes | Any normal-fixture cycle blocks release. |
| Docs layout enforcement | `tools/check_docs_layout.py` | `docs/docs-layout.txt` | Yes | Enforces Diataxis quadrant and ADR locations. |
| Release evidence generation | `tools/generate_release_evidence.sh` | `summary.md`, `checksums.txt` | Yes | Bundle must exclude state, plans, credentials, and real tfvars. |

Release Please publishes release notes and tags after qualifying merges to `main`. The
release evidence workflow runs on published releases, tag pushes matching `v*`, and manual
dispatch.

## Workflow Control Plane

| Workflow | Trigger | Purpose | Permission baseline |
| --- | --- | --- | --- |
| `pr-validation.yaml` | PR, push to `main`, merge queue, manual | Terraform, docs, lint, and OPA gates via `make ci` | `contents: read` |
| `repo-ci.yml` | PR, push to `main` | Markdown and workflow linting | `contents: read` |
| `security.yaml` | PR, push to `main`, merge queue, weekly, manual | Trivy and Gitleaks scans | Job-specific read plus SARIF upload |
| `codeql.yaml` | PR, push to `main`, merge queue, weekly, manual | Static analysis for GitHub Actions | `contents: read`, `security-events: write`, `actions: read` |
| `graph-regression.yml` | PR, manual | Terraform graph evidence and cycle detection | `contents: read` |
| `org-adr-sync.yaml` | PR, weekly, manual | Verify mirrored org ADRs | `contents: read` |
| `release-please.yaml` | Push to `main` | Release PRs and GitHub releases | Write permissions required for release automation |
| `release-evidence.yml` | Published release, tag push, manual | Release evidence artifact | `contents: read` |

## Artifact Rules

Release evidence and workflow artifacts must not include Terraform state, raw plan files,
`.terraform/`, `tfvars`, provider caches, credentials, tokens, signed URLs, or private
infrastructure values. The `tools/generate_release_evidence.sh` script enforces these
exclusions; reviewers should sample uploaded artifacts before publication.

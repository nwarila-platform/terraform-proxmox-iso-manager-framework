# Review Release Evidence

Release evidence is produced by the `release.yaml` workflow's `evidence` job, which
calls the canonical `NWarila/terraform-framework-template` reusable-release-evidence
reusable and uploads the bundle as a GitHub release artifact with attestations.

## Where To Look

In a workflow run, open the artifact named `release-evidence`. The bundle is produced by
the canonical reusable; consult the reusable's source for the authoritative file list. At
minimum, expect:

- a gate-results summary (`summary.md` or equivalent),
- Terraform validate and test output,
- a docs-layout snapshot,
- a security scan summary,
- a checksums manifest covering every other file in the bundle,
- an SBOM and provenance attestation alongside the artifact upload.

## Release-Blocking Findings

Block a release when:

- any gate in the evidence summary is marked `fail`,
- Terraform validation or tests fail,
- docs layout enforcement fails,
- Trivy, Gitleaks, CodeQL, actionlint, zizmor, or markdownlint report blocking findings,
- evidence includes files that should never be published.

## Files That Must Never Be Included

Evidence bundles must exclude:

- `.terraform/`
- `terraform.tfstate`
- `terraform.tfstate.backup`
- raw `tfplan` files
- real `.tfvars` containing environment data
- provider credentials
- unredacted `terraform show -json` output

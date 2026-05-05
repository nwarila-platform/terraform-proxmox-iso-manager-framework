# Review Release Evidence

Release evidence is produced by the `release-evidence.yml` workflow and uploaded as a
GitHub Actions artifact. Graph evidence is also produced by `graph-regression.yml` on pull
requests.

## Where To Look

In a workflow run, open the artifact named `release-evidence`. The bundle contains:

- `summary.md`
- `validate/terraform.validate.json`
- `tests/terraform-test.json`
- `graphs/*.plan.dot`
- `graphs/*.plan.svg`
- `graphs/*.cycles.json`
- `graphs/*.summary.json`
- `docs/docs-layout.txt`
- `security/README.md`
- `checksums.txt`

## How To Read Cycle Reports

Open each `*.cycles.json` file. A normal release should show:

```json
{
  "cycle_count": 0,
  "cycles": []
}
```

Any cycle in a normal fixture blocks release. The educational failure-case example is not a
normal release fixture.

## How To Read Graph Summaries

Open each `*.summary.json` file and check:

- `fixture` names the expected local-source fixture.
- `terraform_graph_type` is `plan`.
- `nodes` and `edges` are non-zero.
- `cycle_count` is `0`.
- `generated_from` is `terraform graph -type=plan -draw-cycles`.

Large unexpected changes to node or edge counts should be reviewed like a public contract
change, even when no cycle exists.

## Release-Blocking Findings

Block a release when:

- any gate in `summary.md` is marked `fail`,
- Terraform validation or tests fail,
- docs layout enforcement fails,
- graph generation fails,
- any normal fixture has cycles,
- Trivy, Gitleaks, CodeQL, actionlint, or markdownlint report blocking findings,
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

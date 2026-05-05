# Generate Terraform Graphs

Use graph generation when reviewing dependency shape, release evidence, or changes to
module outputs and resource references.

## From Make

```bash
make graph
```

By default this writes graph evidence under `artifacts/graphs/` for:

- `tests/fixtures/minimal`
- `tests/fixtures/packer-consumer`

## Direct Script Use

```bash
tools/render_graphs.sh
```

To render one fixture into a custom directory:

```bash
tools/render_graphs.sh tests/fixtures/minimal artifacts/graphs
```

## Outputs

Each fixture produces:

- `<fixture>.validate.json`
- `<fixture>.plan.dot`
- `<fixture>.plan.svg`
- `<fixture>.cycles.json`
- `<fixture>.summary.json`

The script does not create or store Terraform plan files. It runs `terraform graph`
directly and stores only graph and validation evidence.

## Requirements

Local graph generation requires:

- the exact Terraform version pinned in [`../../terraform/versions.tf`](../../terraform/versions.tf)
- Graphviz `dot`
- Python 3

Generated files under `artifacts/` are local evidence and should not be committed. The
repository commits only the representative graph files under
[`../reference/graphs/`](../reference/graphs/).

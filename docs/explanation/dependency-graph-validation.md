# Dependency Graph Validation

Terraform dependency shape is part of this module's release contract. A small child module
can still create bad downstream behavior if it introduces hidden provider edges, output
cycles, or surprising dependencies that consumer repositories inherit.

## Generated Evidence

The graph workflow generates Terraform plan graphs for local-source fixtures:

1. `terraform init -backend=false -input=false`
2. `terraform validate -json`
3. `terraform graph -type=plan -draw-cycles`
4. `dot -Tsvg`
5. `tools/tf_graph_cycles.py`
6. `tools/tf_graph_summary.py`

The resulting DOT, SVG, cycle JSON, and summary JSON are uploaded as CI artifacts. One
representative SVG and summary JSON are committed under
[`../reference/graphs/`](../reference/graphs/) so a visitor can inspect the evidence shape
without opening a workflow artifact.

## Cycle Detection

`tools/tf_graph_cycles.py` parses DOT edges into a directed graph and runs strongly
connected component detection. It reports:

- components with more than one node,
- self-loops,
- total node count,
- total edge count,
- total cycle count.

The script exits non-zero when cycles exist, which makes dependency cycles release
blocking.

## Why The Module Graph Is Small

The module manages one resource and computes one local value. A graph generated only from
the module directory does not show the shape a real consumer sees. The fixtures under
[`../../tests/fixtures/`](../../tests/fixtures/) wrap the child module with provider
configuration and outputs so the graph evidence reflects normal use.

## Why Consumer Fixtures Matter

Examples are optimized for copy/paste readability and use public release sources. Fixtures
are optimized for CI and use `source = "../../../terraform"` so they test the current
branch. This separation keeps public examples stable while making release evidence honest.

## Release-Blocking Failures

A release should be blocked when:

- graph generation fails,
- Terraform validation fails for a normal fixture,
- any normal fixture has a dependency cycle,
- summary JSON cannot be parsed,
- graph artifacts include Terraform state, raw plan files, credentials, real tfvars, or
  unredacted plan JSON.

The educational dependency-cycle failure case is intentionally excluded from normal graph
success fixtures.

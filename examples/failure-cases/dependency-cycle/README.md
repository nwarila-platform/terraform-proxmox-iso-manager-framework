# Dependency Cycle Failure Case

This is an educational negative example. Do not wire it into normal successful CI.

The resources in `main.tf` intentionally reference each other, which creates a Terraform
dependency cycle. The graph tooling should report a cycle if this directory is analyzed,
but normal release evidence uses only fixtures under `tests/fixtures/`.

This directory intentionally omits a `versions.tf`; it is not a copyable consumer root.

See [Dependency graph validation](../../../docs/explanation/dependency-graph-validation.md)
for the release policy.

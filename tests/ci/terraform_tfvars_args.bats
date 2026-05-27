#!/usr/bin/env bats

setup() {
  repo_root="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  script="${repo_root}/tools/ci/terraform_tfvars_args.sh"
}

@test "emits no arguments when tfvars_file is empty" {
  run bash "${script}" ""

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "emits var-file argument relative to consumer checkout" {
  run bash "${script}" "repos/public/sample-environments.tfvars"

  [ "$status" -eq 0 ]
  [ "$output" = "-var-file=../../consumer/repos/public/sample-environments.tfvars" ]
}

@test "supports custom consumer prefix for callers and tests" {
  run bash "${script}" "inputs/env.tfvars" "../consumer"

  [ "$status" -eq 0 ]
  [ "$output" = "-var-file=../consumer/inputs/env.tfvars" ]
}

@test "rejects absolute paths" {
  run bash "${script}" "/tmp/env.tfvars"

  [ "$status" -ne 0 ]
  [[ "${output}" == *"tfvars_file must be relative to the consumer checkout"* ]]
}

@test "rejects path traversal" {
  run bash "${script}" "../secrets.tfvars"

  [ "$status" -ne 0 ]
  [[ "${output}" == *"tfvars_file must not contain path traversal"* ]]
}

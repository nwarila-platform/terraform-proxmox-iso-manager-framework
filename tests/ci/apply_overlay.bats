#!/usr/bin/env bats

setup() {
  repo_root="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  script="${repo_root}/tools/ci/apply_overlay.sh"
  tmp_root="${BATS_TEST_TMPDIR:-$(mktemp -d)}"
  workspace="${tmp_root}/workspace"
  consumer="${workspace}/consumer"
  framework="${workspace}/framework"
  mkdir -p "${consumer}/repos/public" "${consumer}/files" "${framework}/terraform"
  printf 'visible\n' > "${consumer}/repos/public/main.tfvars"
  printf 'hidden\n' > "${consumer}/repos/public/.secret"
  printf 'single\n' > "${consumer}/files/one.txt"
}

@test "copies directory contents including dotfiles and skips comments" {
  run bash "${script}" "${consumer}" "${framework}" $'
    # copied into framework terraform data
    repos/public/ => terraform/repos/public/
  '

  [ "$status" -eq 0 ]
  [ -f "${framework}/terraform/repos/public/main.tfvars" ]
  [ -f "${framework}/terraform/repos/public/.secret" ]
  [[ "${output}" == *"overlay: ${consumer}/repos/public/ -> ${framework}/terraform/repos/public/"* ]]
}

@test "copies file sources into the destination directory" {
  run bash "${script}" "${consumer}" "${framework}" "files/one.txt=>terraform/fixtures/runtime/"

  [ "$status" -eq 0 ]
  [ "$(cat "${framework}/terraform/fixtures/runtime/one.txt")" = "single" ]
}

@test "rejects entries without separator" {
  run bash "${script}" "${consumer}" "${framework}" "repos/public/ terraform/repos/public/"

  [ "$status" -ne 0 ]
  [[ "${output}" == *"overlay entry missing '=>' separator"* ]]
}

@test "rejects missing sources" {
  run bash "${script}" "${consumer}" "${framework}" "repos/missing/=>terraform/repos/missing/"

  [ "$status" -ne 0 ]
  [[ "${output}" == *"overlay source missing"* ]]
}

@test "rejects source path traversal" {
  run bash "${script}" "${consumer}" "${framework}" "../outside=>terraform/repos/public/"

  [ "$status" -ne 0 ]
  [[ "${output}" == *"overlay source must not contain path traversal"* ]]
}

@test "rejects destination path traversal" {
  run bash "${script}" "${consumer}" "${framework}" "repos/public/=>../outside"

  [ "$status" -ne 0 ]
  [[ "${output}" == *"overlay destination must not contain path traversal"* ]]
}

@test "rejects workflow destinations" {
  run bash "${script}" "${consumer}" "${framework}" "repos/public/=>.github/workflows/"

  [ "$status" -ne 0 ]
  [[ "${output}" == *"overlay destination must be under terraform/repos/ or terraform/fixtures/runtime/"* ]]
}

@test "rejects framework implementation destinations" {
  run bash "${script}" "${consumer}" "${framework}" "repos/public/=>terraform/versions.tf"

  [ "$status" -ne 0 ]
  [[ "${output}" == *"overlay destination must be under terraform/repos/ or terraform/fixtures/runtime/"* ]]
}

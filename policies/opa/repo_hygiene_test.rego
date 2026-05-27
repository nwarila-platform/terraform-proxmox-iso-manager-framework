package repo_hygiene_test

import data.repo_hygiene
import rego.v1

# region ------ [ Workflow uses: pinning ] ------------------------------------------------- #

# A SHA-pinned uses reference passes.
test_sha_pinned_action_allowed if {
	count(repo_hygiene.deny) == 0 with input as {
		"workflows": {"pr.yml": [{"line": 12, "uses": "actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd"}]},
		"files": {"terraform/versions.tf": `terraform {
  required_version = "= 1.15.1"
}`},
	}
}

# A tag-versioned uses reference is denied.
test_tag_pinned_action_denied if {
	denials := repo_hygiene.deny with input as {
		"workflows": {"pr.yml": [{"line": 7, "uses": "actions/checkout@v6"}]},
		"files": {"terraform/versions.tf": `terraform {
  required_version = "= 1.15.1"
}`},
	}
	count(denials) >= 1
}

# A malformed SHA-looking reference is denied.
test_malformed_sha_action_denied if {
	denials := repo_hygiene.deny with input as {
		"workflows": {"pr.yml": [{"line": 7, "uses": "actions/checkout@xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}]},
		"files": {"terraform/versions.tf": `terraform {
  required_version = "= 1.15.1"
}`},
	}
	count(denials) >= 1
}

# A floating @main reference is denied.
test_main_branch_action_denied if {
	denials := repo_hygiene.deny with input as {
		"workflows": {"pr.yml": [{"line": 3, "uses": "actions/checkout@main"}]},
		"files": {"terraform/versions.tf": `terraform {
  required_version = "= 1.15.1"
}`},
	}
	count(denials) >= 1
}

# A local reference is allowed.
test_local_ref_allowed if {
	count(repo_hygiene.deny) == 0 with input as {
		"workflows": {"pr.yml": [{"line": 5, "uses": "./.github/actions/setup"}]},
		"files": {"terraform/versions.tf": `terraform {
  required_version = "= 1.15.1"
}`},
	}
}

# A digest-pinned docker reference is allowed.
test_docker_digest_allowed if {
	count(repo_hygiene.deny) == 0 with input as {
		"workflows": {"pr.yml": [{"line": 9, "uses": "docker://ghcr.io/example/tool:v1.0.0@sha256:abc123"}]},
		"files": {"terraform/versions.tf": `terraform {
  required_version = "= 1.15.1"
}`},
	}
}

# An undigested docker reference is denied.
test_docker_without_digest_denied if {
	denials := repo_hygiene.deny with input as {
		"workflows": {"pr.yml": [{"line": 4, "uses": "docker://ghcr.io/example/tool:v1.0.0"}]},
		"files": {"terraform/versions.tf": `terraform {
  required_version = "= 1.15.1"
}`},
	}
	count(denials) >= 1
}

# endregion --- [ Workflow uses: pinning ] ------------------------------------------------- #

# region ------ [ pull_request_target guard ] ---------------------------------------------- #

test_pull_request_target_checkout_denied if {
	denials := repo_hygiene.deny with input as {
		"workflows": {},
		"files": {".github/workflows/auto-merge.yaml": `on:
  pull_request_target:
    types: [opened]
jobs:
  dangerous:
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd`},
	}
	count(denials) >= 1
}

test_release_workflow_pull_request_target_denied if {
	denials := repo_hygiene.deny with input as {
		"workflows": {},
		"files": {".github/workflows/release.yaml": `on:
  pull_request_target:
  workflow_dispatch:`},
	}
	count(denials) >= 1
}

test_pr_validation_pull_request_target_denied if {
	denials := repo_hygiene.deny with input as {
		"workflows": {},
		"files": {".github/workflows/pr-validation.yaml": `on:
  pull_request_target:
jobs: {}`},
	}
	count(denials) >= 1
}

test_release_workflow_release_trigger_allowed if {
	count(repo_hygiene.deny) == 0 with input as {
		"workflows": {},
		"files": {".github/workflows/release.yaml": `on:
  push:
    branches: [main]
  release:
    types: [published]
  workflow_dispatch:`},
	}
}

test_auto_merge_reusable_pr_head_ref_denied if {
	denials := repo_hygiene.deny with input as {
		"workflows": {},
		"files": {".github/workflows/reusable-auto-merge.yaml": `jobs:
  enable-auto-merge:
    steps:
      - run: echo "${{ github.event.pull_request.head.sha }}"`},
	}
	count(denials) >= 1
}

test_auto_merge_reusable_payload_metadata_allowed if {
	count(repo_hygiene.deny) == 0 with input as {
		"workflows": {},
		"files": {".github/workflows/reusable-auto-merge.yaml": `jobs:
  enable-auto-merge:
    steps:
      - env:
          PR_AUTHOR: ${{ github.event.pull_request.user.login }}
          PR_NUMBER: ${{ github.event.pull_request.number }}
        run: |
          declare -a trusted_authors=("renovate[bot]" "dependabot[bot]")
          gh pr merge "${PR_NUMBER}" --repo "${{ github.repository }}" --auto --squash`},
	}
}

# endregion --- [ pull_request_target guard ] ---------------------------------------------- #

# region ------ [ versions.tf required_version pinning ] ----------------------------------- #

# Repos without Terraform code are still allowed to use the workflow
# pinning subset of this policy.
test_missing_versions_tf_allowed if {
	count(repo_hygiene.deny) == 0 with input as {
		"workflows": {},
		"files": {},
	}
}

# Missing required_version is denied.
test_missing_required_version_denied if {
	denials := repo_hygiene.deny with input as {
		"workflows": {},
		"files": {"terraform/versions.tf": `terraform { }`},
	}
	count(denials) >= 1
}

# A commented exact required_version does not satisfy the invariant.
test_required_version_comment_spoof_denied if {
	denials := repo_hygiene.deny with input as {
		"workflows": {},
		"files": {"terraform/versions.tf": `terraform {
  # required_version = "= 1.15.1"
  required_version = ">= 1.15.1"
}`},
	}
	count(denials) >= 1
}

# endregion --- [ versions.tf required_version pinning ] ----------------------------------- #

# region ------ [ Provider version pinning ] ----------------------------------------------- #

# A pessimistic constraint operator is denied.
test_pessimistic_operator_denied if {
	denials := repo_hygiene.deny with input as {
		"workflows": {},
		"files": {"terraform/versions.tf": `terraform { required_version = "= 1.15.1" }
provider "null" { version = "~> 3.2" }`},
	}
	count(denials) >= 1
}

# An exact provider pin with `=` passes — using the synthetic providers
# this framework actually consumes, so the test reflects real config.
test_exact_provider_pin_allowed if {
	count(repo_hygiene.deny) == 0 with input as {
		"workflows": {},
		"files": {"terraform/versions.tf": `terraform {
  required_version = "= 1.15.1"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "= 3.2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "= 3.8.1"
    }
  }
}`},
	}
}

# A provider version range is denied.
test_provider_range_denied if {
	denials := repo_hygiene.deny with input as {
		"workflows": {},
		"files": {"terraform/versions.tf": `terraform {
  required_version = "= 1.15.1"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.0"
    }
  }
}`},
	}
	count(denials) >= 1
}

# An unprefixed provider version is denied.
test_provider_unprefixed_version_denied if {
	denials := repo_hygiene.deny with input as {
		"workflows": {},
		"files": {"terraform/versions.tf": `terraform {
  required_version = "= 1.15.1"
  required_providers {
    time = {
      source  = "hashicorp/time"
      version = "0.13.1"
    }
  }
}`},
	}
	count(denials) >= 1
}

# endregion --- [ Provider version pinning ] ----------------------------------------------- #

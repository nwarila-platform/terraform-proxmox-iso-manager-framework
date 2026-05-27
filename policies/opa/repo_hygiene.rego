# repo_hygiene - repository hygiene policy for Terraform-family repos.
#
# Encodes repository-level invariants that are visible from source files:
# workflow `uses:` SHA-pinning, privileged-trigger boundaries, exact
# `required_version` pins in versions.tf, and exact `=` operator on provider
# versions. Terraform plan-aware policy belongs in a separate package.
#
# Rules trace to:
#   - template-tier ADR-template/0001 in the owning Terraform template
#     ("Pin Terraform and Provider Versions Exactly") mandates the
#     exact-pin rules below for every Terraform-runner consumer.
#   - org ADR-0004 §"SHA-pin retention check" requires
#     github-actions.pinDigests in every type-template's renovate
#     baseline, paired with these workflow-level checks.
#
# Input shape (assembled by tooling, not Terraform plan output):
#   {
#     "workflows": {
#       "<filename>": [
#         {"line": <int>, "uses": "<ref>"},
#         ...
#       ]
#     },
#     "files": { "<path>": "<contents>" }  # includes workflow files
#   }

package repo_hygiene

import rego.v1

# region ------ [ Regex constants ] -------------------------------------------------------- #

# A 40-character lowercase hex SHA-1 string. GitHub Actions `uses:`
# pins should be the full commit hash, not a short SHA.
sha_re := `^[0-9a-f]{40}$`

# Exact pin shape for terraform { required_version = "= X.Y.Z" }.
# Matches `= 1.15.4` but rejects `>= 1.15.4`, `~> 1.15`, `1.15.4`, etc.
exact_required_version_re := `^\s*required_version\s*=\s*"=\s*[0-9]+\.[0-9]+\.[0-9]+"\s*$`

# Any provider version line — used to find candidates for further checks.
provider_version_line_re := `^\s*version\s*=\s*"[^"]+"\s*$`

# Exact pin shape for a provider version line.
exact_provider_version_line_re := `^\s*version\s*=\s*"=\s*[0-9]+\.[0-9]+\.[0-9]+"\s*$`

# PR-controlled content markers that must not appear in workflows running in
# pull_request_target context or in reusables intentionally called by them.
unsafe_pr_target_ref_fragments := {
	"uses: actions/checkout@",
	"github.event.pull_request.head",
	"github.event.pull_request.title",
	"github.event.pull_request.body",
	"github.event.pull_request.commits_url",
	"github.event.pull_request.diff_url",
	"github.event.pull_request.patch_url",
	"github.head_ref",
	"gh pr checkout",
	"gh pr diff",
	"gh pr view",
	"git checkout",
	"git fetch",
	"git switch",
}

pull_request_target_allowed_workflows := {
	".github/workflows/auto-merge.yaml",
}

auto_merge_reusable := ".github/workflows/reusable-auto-merge.yaml"

# endregion --- [ Regex constants ] -------------------------------------------------------- #

# region ------ [ Workflow uses: pinning predicates ] -------------------------------------- #

is_local_ref(ref) if startswith(ref, "./")

is_docker_digest(ref) if {
	startswith(ref, "docker://")
	contains(ref, "@sha256:")
}

is_sha_pinned(ref) if {
	not is_local_ref(ref)
	not startswith(ref, "docker://")
	contains(ref, "@")
	parts := split(ref, "@")
	count(parts) == 2
	regex.match(sha_re, parts[1])
}

is_acceptable(ref) if is_sha_pinned(ref)
is_acceptable(ref) if is_local_ref(ref)
is_acceptable(ref) if is_docker_digest(ref)

# endregion --- [ Workflow uses: pinning predicates ] -------------------------------------- #

# region ------ [ Helpers ] ---------------------------------------------------------------- #

# Lines from `path` with leading/trailing whitespace stripped, blank
# lines and `#`/`//` comment-only lines excluded. Used by content rules
# below so a commented-out exact pin doesn't satisfy the invariant.
uncommented_lines(path) := lines if {
	content := input.files[path]
	lines := [trim_space(line) |
		line := split(content, "\n")[_]
		trim_space(line) != ""
		not startswith(trim_space(line), "#")
		not startswith(trim_space(line), "//")
	]
}

uncommented_line_records(path) := records if {
	content := input.files[path]
	raw_lines := split(content, "\n")
	records := [{"line": idx + 1, "text": text} |
		some idx
		raw := raw_lines[idx]
		text := trim_space(raw)
		text != ""
		not startswith(text, "#")
		not startswith(text, "//")
	]
}

has_versions_tf if {
	_ := input.files["terraform/versions.tf"]
}

workflow_file(path) if {
	startswith(path, ".github/workflows/")
}

has_pull_request_target_trigger(path) if {
	workflow_file(path)
	record := uncommented_line_records(path)[_]
	text := record.text
	regex.match(`^pull_request_target\s*:`, text)
}

protected_pull_request_target_workflow(path) if {
	has_pull_request_target_trigger(path)
}

protected_pull_request_target_workflow(path) if {
	path == auto_merge_reusable
	_ := input.files[path]
}

# endregion --- [ Helpers ] ---------------------------------------------------------------- #

# region ------ [ Deny rules: workflow uses: pinning ] ------------------------------------- #

deny contains msg if {
	some workflow, _ in input.workflows
	use := input.workflows[workflow][_]
	not is_acceptable(use.uses)
	msg := sprintf(
		"%s:%d - `uses: %s` is not SHA-pinned; replace `@<tag>` with `@<40-char-sha>`",
		[workflow, use.line, use.uses],
	)
}

# endregion --- [ Deny rules: workflow uses: pinning ] ------------------------------------- #

# region ------ [ Deny rules: pull_request_target guard ] ---------------------------------- #

deny contains msg if {
	some path
	_ := input.files[path]
	has_pull_request_target_trigger(path)
	not pull_request_target_allowed_workflows[path]
	msg := sprintf("%s must not use pull_request_target; only auto-merge.yaml is allowed to run in that context", [path])
}

deny contains msg if {
	some path
	_ := input.files[path]
	protected_pull_request_target_workflow(path)
	record := uncommented_line_records(path)[_]
	line_no := record.line
	text := record.text
	line := lower(text)
	fragment := unsafe_pr_target_ref_fragments[_]
	contains(line, fragment)
	msg := sprintf(
		"%s:%d - pull_request_target auto-merge guard forbids PR-controlled content reads: %s",
		[path, line_no, fragment],
	)
}

# endregion --- [ Deny rules: pull_request_target guard ] ---------------------------------- #

# region ------ [ Deny rules: terraform/versions.tf content ] ------------------------------ #

# terraform/versions.tf must contain an exact `required_version = "= X.Y.Z"` line.
has_exact_required_version if {
	line := uncommented_lines("terraform/versions.tf")[_]
	regex.match(exact_required_version_re, line)
}

deny contains msg if {
	has_versions_tf
	not has_exact_required_version
	msg := "terraform/versions.tf must pin required_version with `= X.Y.Z` (template-tier ADR-template/0001)"
}

# Pessimistic constraint operator (~>) is forbidden in versions.tf.
deny contains msg if {
	has_versions_tf
	line := uncommented_lines("terraform/versions.tf")[_]
	contains(line, "~>")
	msg := "terraform/versions.tf must not use `~>`; provider versions require exact `=` pins (template-tier ADR-template/0001)"
}

# Every provider version line in terraform/versions.tf must use an exact `=` pin.
deny contains msg if {
	has_versions_tf
	line := uncommented_lines("terraform/versions.tf")[_]
	regex.match(provider_version_line_re, line)
	not regex.match(exact_provider_version_line_re, line)
	msg := sprintf("terraform/versions.tf provider version must use exact `= X.Y.Z` pin: %s", [line])
}

# endregion --- [ Deny rules: terraform/versions.tf content ] ------------------------------ #

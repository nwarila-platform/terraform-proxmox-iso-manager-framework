tflint {
  required_version = "= 0.62.0"
}

config {
  format = "compact"
  call_module_type = "all"
}

# region ------ [ Plugin: terraform (built-in best-practice rules) ] ----------------------- #

plugin "terraform" {
  enabled = true
  preset  = "all"
  version = "0.14.1"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
}

# endregion --- [ Plugin: terraform (built-in best-practice rules) ] ----------------------- #

# region ------ [ Rule overrides ] --------------------------------------------------------- #

# This framework uses synthetic providers (null/random/local/time/tls)
# whose resources legitimately have many optional attributes that the
# `terraform_unused_declarations` rule does not consider in context.
# Disable the noisy unused-declarations rule for these synthetic
# resources; real frameworks should leave it enabled.

rule "terraform_unused_declarations" {
  enabled = true
}

# Module-style frameworks prefer documentation comments over inline
# descriptions on every variable; the `terraform_documented_outputs`
# rule already enforces output descriptions, which is the more useful
# of the pair.

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

# This framework's variables.tf uses the packer-aligned mega-object
# pattern with very long type definitions. The 80-char line-length rule
# forces awkward wrapping; disabled in favor of the editor ruler at 96.

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

# This child module uses resources.tf as its primary resource file per
# repo ADR 0001 instead of a catch-all main.tf.

rule "terraform_standard_module_structure" {
  enabled = false
}

# endregion --- [ Rule overrides ] --------------------------------------------------------- #

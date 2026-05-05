# Start from ../minimal/main.tf and add the argument below to module "iso" only during
# deliberate adoption or recovery.
#
# The default false value stops Terraform if a same-name ISO exists outside state.
# Set true only after an operator confirms the unmanaged ISO should be replaced.

# overwrite_unmanaged = true

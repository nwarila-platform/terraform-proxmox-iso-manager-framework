# Start from ../minimal/main.tf and add BOTH arguments below to module "iso" only during
# deliberate adoption or recovery.
#
# The default false value stops Terraform if a same-name ISO exists outside state.
# Set true only after an operator confirms the unmanaged ISO should be replaced.
# adopt_unmanaged_confirmation MUST equal iso_pin.filename, or the resource precondition
# fails closed - forcing the operator to name the exact file being deleted.

# overwrite_unmanaged          = true
# adopt_unmanaged_confirmation = "Rocky-9.6-x86_64-dvd.iso"  # must equal iso_pin.filename

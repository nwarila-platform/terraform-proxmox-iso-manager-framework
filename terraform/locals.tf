locals {
  # Storage-prefixed path consumable by Packer's proxmox-iso plugin iso_file field, e.g.
  # "cephFS:iso/Rocky-9.6-x86_64-dvd.iso". Computed here so outputs.tf stays
  # declaration-only.
  iso_path = "${var.storage}:iso/${var.iso_pin.filename}"
}

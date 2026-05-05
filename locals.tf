locals {

  # Define the managed ISO. The git history of the consumer's iso_pin assignment IS the
  # long-lived audit trail; this object only assembles those inputs into the shape the
  # bpg/proxmox provider's proxmox_download_file resource expects.
  iso = {

    /* Required Parameters */
    content_type = "iso"
    datastore_id = var.storage
    node_name    = var.node
    url          = var.iso_pin.url
    file_name    = var.iso_pin.filename

    /* Integrity Verification */
    checksum           = var.iso_pin.sha256
    checksum_algorithm = "sha256"

    /* Optional Parameters */
    overwrite = var.overwrite
  }

  # Storage-prefixed path consumable by Packer's proxmox-iso plugin iso_file field, e.g.
  # "cephFS:iso/Rocky-9.6-x86_64-dvd.iso". Computed here so outputs.tf stays declaration-only.
  iso_path = "${var.storage}:iso/${var.iso_pin.filename}"
}

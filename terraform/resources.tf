resource "proxmox_download_file" "iso" {

  /* Required Parameters */
  content_type = "iso"
  datastore_id = var.storage
  node_name    = var.node
  url          = var.iso_pin.url
  file_name    = var.iso_pin.filename

  /* Integrity Verification */
  checksum           = var.iso_pin.sha256
  checksum_algorithm = "sha256"
  verify             = true

  /* Optional Parameters */
  upload_timeout      = var.upload_timeout
  overwrite           = var.overwrite
  overwrite_unmanaged = var.overwrite_unmanaged

  lifecycle {
    # Destructive-recovery friction: overwrite_unmanaged deletes a same-named
    # unmanaged file. Require the operator to name the exact file so the flag
    # cannot be flipped on by accident or carried over from another instance.
    precondition {
      condition     = !var.overwrite_unmanaged || var.adopt_unmanaged_confirmation == var.iso_pin.filename
      error_message = "overwrite_unmanaged=true requires adopt_unmanaged_confirmation to equal iso_pin.filename (the exact file being adopted)."
    }
  }
}

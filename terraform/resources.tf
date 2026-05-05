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

  /* Optional Parameters */
  overwrite = var.overwrite
}

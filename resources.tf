resource "proxmox_download_file" "iso" {

  /* Required Parameters */
  content_type = local.iso.content_type
  datastore_id = local.iso.datastore_id
  node_name    = local.iso.node_name
  url          = local.iso.url
  file_name    = local.iso.file_name

  /* Integrity Verification */
  checksum           = local.iso.checksum
  checksum_algorithm = local.iso.checksum_algorithm

  /* Optional Parameters */
  overwrite = local.iso.overwrite
}

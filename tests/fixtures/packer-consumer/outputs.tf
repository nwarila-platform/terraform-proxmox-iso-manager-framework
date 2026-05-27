output "boot_iso" {
  description = "Packer-compatible boot_iso object."
  value = {
    iso_checksum         = "sha256:${module.iso.iso_sha256}"
    iso_file             = module.iso.iso_path
    iso_urls             = null
    cd_label             = null
    index                = 0
    iso_download_pve     = false
    iso_storage_pool     = null
    iso_target_extension = null
    iso_target_path      = null
    keep_cdrom_device    = false
    type                 = "scsi"
    unmount              = true
  }
}

output "additional_iso_files" {
  description = "Packer-compatible additional ISO file list. Empty for this single-ISO module."
  value       = []
}

output "packer_vars_hcl" {
  description = "Example content a consumer can write to build.pkrvars.hcl before running packer build."
  value       = <<-EOT
    boot_iso = {
      iso_checksum         = "sha256:${module.iso.iso_sha256}"
      iso_file             = "${module.iso.iso_path}"
      iso_urls             = null
      cd_label             = null
      index                = 0
      iso_download_pve     = false
      iso_storage_pool     = null
      iso_target_extension = null
      iso_target_path      = null
      keep_cdrom_device    = false
      type                 = "scsi"
      unmount              = true
    }

    additional_iso_files = []
  EOT
}

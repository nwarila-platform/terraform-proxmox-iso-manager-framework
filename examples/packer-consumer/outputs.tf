output "boot_iso" {
  description = <<-EOT
    Boot ISO object aligned with the downstream
    nwarila-platform/proxmox-packer-framework `boot_iso` variable type. Render this
    object into an auto-loaded pkrvars file (e.g. `iso.auto.pkrvars.hcl`) using
    `templatefile()` and `local_file`; see docs/how-to/use-from-a-packer-template.md.

    ISO-lifecycle fields (`iso_checksum`, `iso_file`, `iso_urls`, `iso_download_pve`,
    `iso_storage_pool`, `iso_target_extension`, `iso_target_path`) are owned by this
    module. The consumer-policy fields (`cd_label`, `index`, `keep_cdrom_device`,
    `type`, `unmount`) take sensible defaults matching the proxmox-packer-framework
    examples; consumers needing other values should override after the module call.
  EOT
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
  description = "Additional ISO file objects for proxmox-packer-framework. Empty because this module owns only the boot ISO."
  value       = []
}

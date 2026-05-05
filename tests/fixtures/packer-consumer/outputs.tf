output "iso_file" {
  description = "Packer-compatible ISO path."
  value       = module.iso.iso_path
}

output "iso_checksum" {
  description = "Packer-compatible ISO checksum string."
  value       = "sha256:${module.iso.iso_sha256}"
}

output "packer_vars_hcl" {
  description = "Example content a consumer can write to build.pkrvars.hcl before running packer build."
  value       = <<-EOT
    iso_file     = "${module.iso.iso_path}"
    iso_checksum = "sha256:${module.iso.iso_sha256}"
  EOT
}

output "iso_file" {
  description = "Packer-compatible ISO path."
  value       = module.iso.iso_path
}

output "iso_checksum" {
  description = "Packer-compatible ISO checksum string."
  value       = "sha256:${module.iso.iso_sha256}"
}

output "iso_id" {
  description = <<-EOT
    Proxmox file ID for the managed ISO, in the form "<datastore>:<volume_id>". This is the
    canonical identifier the bpg/proxmox provider uses to reference the file in subsequent
    resources.
  EOT
  value       = proxmox_download_file.iso.id
}

output "iso_path" {
  description = <<-EOT
    Storage-prefixed path consumable by Packer's proxmox-iso plugin `iso_file` field, e.g.
    "cephFS:iso/Rocky-9.6-x86_64-dvd.iso". Pass this directly into the consumer template
    repo's Packer configuration.
  EOT
  value       = local.iso_path
}

output "iso_sha256" {
  description = <<-EOT
    SHA-256 digest of the managed ISO, echoed back from input. Useful for downstream
    consumers (e.g. SLSA provenance generators, audit log emitters) that want to record
    which exact ISO a build consumed.
  EOT
  value       = var.iso_pin.sha256
}

output "iso_url" {
  description = <<-EOT
    Non-tokenized upstream URL the ISO was downloaded from. Returned only when
    expose_iso_url = true; otherwise null. Always marked sensitive so it is redacted from
    CLI output. Prefer iso_sha256 + iso_filename for provenance correlation.
  EOT
  value       = var.expose_iso_url ? var.iso_pin.url : null
  sensitive   = true
}

output "iso_filename" {
  description = "On-disk filename of the managed ISO. Echoed back for downstream pathing."
  value       = var.iso_pin.filename
}

output "family" {
  description = "Template family discriminator, echoed back for downstream label/output use."
  value       = var.family
}

output "node" {
  description = "Proxmox node where the download was performed."
  value       = var.node
}

output "storage" {
  description = "Proxmox storage datastore the ISO landed on."
  value       = var.storage
}

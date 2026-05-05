# ============================================================================
# main.tf
#
# Manages a single ISO on a Proxmox VE storage. Idempotent: subsequent applies
# with an unchanged iso_pin are no-ops; bumping the sha256 (or url, or
# filename) triggers a re-download of the new ISO.
#
# Consumer contract:
#
#   module "iso" {
#     source = "git::https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework.git?ref=v1.0.0"
#
#     family   = "rocky9"
#     iso_pin  = {
#       url      = "https://dl.rockylinux.org/.../Rocky-9.6-x86_64-dvd.iso"
#       sha256   = "8ff2a47e..."
#       filename = "Rocky-9.6-x86_64-dvd.iso"
#     }
#     node     = "tcnhq-prxmx01"
#     storage  = "cephFS"
#   }
#
# Architecture context:
# - Templates are the durable build artifact (N=3 retention on Proxmox).
# - ISOs are short-lived build inputs (N=1 on Proxmox).
# - The git history of the consumer's iso_pin assignment IS the long-lived
#   audit trail; rolling back to an older ISO is a `git checkout` + `terraform
#   apply` away.
# ============================================================================

resource "proxmox_download_file" "iso" {
  content_type       = "iso"
  datastore_id       = var.storage
  node_name          = var.node
  url                = var.iso_pin.url
  file_name          = var.iso_pin.filename
  checksum           = var.iso_pin.sha256
  checksum_algorithm = "sha256"
  overwrite          = var.overwrite
}

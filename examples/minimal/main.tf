terraform {
  required_version = "= 1.15.1"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "= 0.105.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
}

variable "proxmox_endpoint" {
  description = "Proxmox API endpoint. Credentials should be supplied through provider-supported environment variables or caller-specific configuration."
  type        = string
  default     = "https://proxmox.example.test:8006/"
}

module "iso" {
  source = "../../terraform"

  family = "rocky9"
  iso_pin = {
    url      = "https://dl.rockylinux.org/pub/rocky/9.6/isos/x86_64/Rocky-9.6-x86_64-dvd.iso"
    sha256   = "8ff2a47e2f3bfe442617fceb7ef289b7b1d2d0502089dbbd505d5368b2b3a90f"
    filename = "Rocky-9.6-x86_64-dvd.iso"
  }
  node    = "tcnhq-prxmx01"
  storage = "cephFS"
}

output "iso_file" {
  description = "Packer-compatible ISO path."
  value       = module.iso.iso_path
}

output "iso_checksum" {
  description = "Packer-compatible ISO checksum string."
  value       = "sha256:${module.iso.iso_sha256}"
}

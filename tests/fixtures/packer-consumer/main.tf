provider "proxmox" {
  endpoint = var.proxmox_endpoint
}

variable "proxmox_endpoint" {
  description = "Proxmox API endpoint placeholder for validation-only fixtures."
  type        = string
  default     = "https://proxmox.example.test:8006/"
}

module "iso" {
  source = "../../../terraform"

  family = "rocky9"

  iso_pin = {
    url      = "https://dl.rockylinux.org/pub/rocky/9.6/isos/x86_64/Rocky-9.6-x86_64-dvd.iso"
    sha256   = "8ff2a47e2f3bfe442617fceb7ef289b7b1d2d0502089dbbd505d5368b2b3a90f"
    filename = "Rocky-9.6-x86_64-dvd.iso"
  }

  node    = "tcnhq-prxmx01"
  storage = "cephFS"
}

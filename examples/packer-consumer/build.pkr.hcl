variable "iso_file" {
  type = string
}

variable "iso_checksum" {
  type = string
}

source "proxmox-iso" "example" {
  iso_file     = var.iso_file
  iso_checksum = var.iso_checksum

  node = "pve-node-01"

  # A real consumer repo supplies its full Proxmox builder settings here and owns the
  # Packer plugin pinning policy for that root template project.
}

build {
  sources = ["source.proxmox-iso.example"]
}

terraform {
  required_version = "= 1.9.8"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "= 0.98.1"
    }
  }
}

variable "family" {
  description = <<-EOT
    Template family discriminator (e.g. "rocky9", "ubuntu24"). Provenance-only: this
    value is NOT consumed by any resource in this module — it is echoed back through the
    `family` output so consumers (typically Packer template repos) can correlate the
    managed ISO with the template family it feeds. Must match Proxmox tag character
    constraints (lowercase letters, digits, hyphens, dots, underscores) so consumers can
    pass it directly into Proxmox tags downstream.
  EOT
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9._-]+$", var.family))
    error_message = "The family value must consist of lowercase letters, digits, hyphens, dots, and underscores only (matches Proxmox tag character constraints)."
  }
}

variable "iso_pin" {
  description = <<-EOT
    Pin specifying the exact ISO this module will manage on Proxmox storage. The url is a
    non-tokenized HTTPS URL with a host and path, and it may not contain whitespace, query
    strings, or fragments. The url is fetched once on first apply (or when sha256 changes);
    the sha256 is enforced server-side by the Proxmox download endpoint after the file
    lands. The filename is the on-disk name in the target storage's iso/ directory.

    The consumer's git repository is the long-lived audit trail for this pin: replacing the
    pin in the consumer's HCL records the ISO change in git history with full diffability.
  EOT
  type = object({
    url      = string
    sha256   = string
    filename = string
  })

  validation {
    condition     = can(regex("^https://[A-Za-z0-9.-]+(:[0-9]{1,5})?/[^\\s?#]+$", var.iso_pin.url))
    error_message = "iso_pin.url must be a non-tokenized https:// URL with a host and path, and must not contain whitespace, query strings, or fragments."
  }

  validation {
    condition     = can(regex("^[0-9a-f]{64}$", var.iso_pin.sha256))
    error_message = "iso_pin.sha256 must be a 64-character lowercase hex SHA-256 digest."
  }

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]+\\.iso$", var.iso_pin.filename))
    error_message = "iso_pin.filename must be a simple filename ending in .iso (no path components, no whitespace)."
  }
}

variable "node" {
  description = <<-EOT
    Proxmox node name on which the download is performed. Required by the bpg/proxmox
    provider's proxmox_download_file resource. For shared/cluster
    storage like cephFS, any node works because the resulting file is cluster-visible; pick
    one consistently to keep the download localized.
  EOT
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]+$", var.node))
    error_message = "The node value must consist of letters, digits, hyphens, dots, and underscores only."
  }
}

variable "storage" {
  description = <<-EOT
    Proxmox storage datastore where the ISO will be placed (e.g. "cephFS", "local"). The
    storage MUST have ISO content type enabled in its Proxmox configuration.
  EOT
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]+$", var.storage))
    error_message = "The storage value must consist of letters, digits, hyphens, dots, and underscores only."
  }
}

variable "upload_timeout" {
  description = <<-EOT
    Timeout in seconds for the Proxmox download-url operation. Defaults to one hour so
    large installer ISOs can be fetched reliably on homelab or WAN-backed storage without
    weakening transport verification.
  EOT
  type        = number
  default     = 3600

  validation {
    condition     = var.upload_timeout >= 60 && var.upload_timeout <= 86400
    error_message = "upload_timeout must be between 60 and 86400 seconds."
  }
}

variable "overwrite" {
  description = <<-EOT
    When true, allow the provider to replace the managed file when its size changes outside
    Terraform or the upstream URL reports a different size. Defaults to false for pinned ISO
    inputs: once Terraform owns the file, the provider does not re-check upstream size on
    refresh. This does not take ownership of unmanaged pre-existing files; use
    overwrite_unmanaged for that explicit recovery path.
  EOT
  type        = bool
  default     = false
}

variable "overwrite_unmanaged" {
  description = <<-EOT
    When true, delete and replace an unmanaged file that already exists at the target
    Proxmox storage path. Defaults to false so the module fails closed if a same-named ISO
    exists outside Terraform state. Set true only during deliberate adoption/recovery.
  EOT
  type        = bool
  default     = false
}

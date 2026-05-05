variable "family" {
  description = <<-EOT
    Template family discriminator (e.g. "rocky9", "ubuntu24"). Echoed back as an output for
    downstream provenance and label correlation. Must match Proxmox tag character constraints
    (lowercase letters, digits, hyphens, dots, underscores).
  EOT
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9._-]+$", var.family))
    error_message = "The family value must consist of lowercase letters, digits, hyphens, dots, and underscores only (matches Proxmox tag character constraints)."
  }
}

variable "iso_pin" {
  description = <<-EOT
    Pin specifying the exact ISO this module will manage on Proxmox storage. The url is
    fetched once on first apply (or when sha256 changes); the sha256 is enforced server-side
    by the Proxmox download endpoint after the file lands. The filename is the on-disk name
    in the target storage's iso/ directory.

    The consumer's git repository is the long-lived audit trail for this pin: replacing the
    pin in the consumer's HCL records the ISO change in git history with full diffability.
  EOT
  type = object({
    url      = string
    sha256   = string
    filename = string
  })

  validation {
    condition     = can(regex("^https://", var.iso_pin.url))
    error_message = "iso_pin.url must be an https:// URL. Plain http and other schemes are rejected."
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
    condition     = length(trimspace(var.node)) > 0
    error_message = "The node value must not be empty."
  }
}

variable "storage" {
  description = <<-EOT
    Proxmox storage datastore where the ISO will be placed (e.g. "cephFS", "local"). The
    storage MUST have ISO content type enabled in its Proxmox configuration.
  EOT
  type        = string

  validation {
    condition     = length(trimspace(var.storage)) > 0
    error_message = "The storage value must not be empty."
  }
}

variable "overwrite" {
  description = <<-EOT
    When true, replace any pre-existing file at the target path even if a SHA mismatch is
    NOT detected. Defaults to false: the typical desired behavior is "never re-download
    something that's already there." Set to true only when forcing a re-pull, e.g. recovering
    from a corrupted file the SHA pre-check missed.
  EOT
  type        = bool
  default     = false
}

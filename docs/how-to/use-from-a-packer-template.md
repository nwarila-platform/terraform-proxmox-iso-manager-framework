# How to use this module from a Packer template repository

This guide walks through importing `terraform-proxmox-iso-manager-framework` from a Packer
template repository (e.g. `secure-rockylinux9-template`). The module's job is to download
and SHA-verify a single ISO; the calling Terraform configuration emits a Packer
`pkrvars.hcl` file that points Packer at the verified ISO.

## Prerequisites

- A Proxmox VE cluster reachable via the bpg/proxmox provider.
- A storage datastore on Proxmox with ISO content type enabled (e.g. `cephFS`, `local`).
- A Proxmox API token with the privileges required by `proxmox_download_file`.
- Terraform `= 1.15.1` exactly. Use `tfenv` or `asdf` if you manage multiple versions
  on one workstation. Per [org ADR-0005](../decision-records/org/0005-pin-terraform-and-provider-versions-exactly.md),
  any other Terraform version causes `terraform init` to fail.

## Step 1: Pin the module in your Terraform configuration

In your Packer template repo's Terraform code:

```hcl
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
  endpoint  = "https://proxmox.example.test:8006/"
  api_token = var.proxmox_api_token
  insecure  = false
}

module "iso" {
  source = "git::https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework.git//terraform?ref=v1.0.0"

  family = "rocky9"
  iso_pin = {
    url      = "https://dl.rockylinux.org/pub/rocky/9.6/isos/x86_64/Rocky-9.6-x86_64-dvd.iso"
    sha256   = "8ff2a47e2f3bfe442617fceb7ef289b7b1d2d0502089dbbd505d5368b2b3a90f"
    filename = "Rocky-9.6-x86_64-dvd.iso"
  }
  node    = "pve-node-01"
  storage = "cephFS"
}
```

The `//terraform` segment in the module `source` is non-optional. It tells Terraform to
look for the module HCL inside the repository's `terraform/` subdirectory rather than at
the root. Omitting it produces a `terraform init` failure with no clear error.

## Step 2: Emit a Packer pkrvars.hcl file

```hcl
resource "local_file" "packer_vars" {
  filename = "${path.root}/build.pkrvars.hcl"
  content  = <<-EOT
    iso_file       = "${module.iso.iso_path}"
    iso_checksum   = "sha256:${module.iso.iso_sha256}"
    proxmox_node   = "${module.iso.node}"
  EOT
}
```

`module.iso.iso_path` is the `<storage>:iso/<filename>` form that Proxmox's Packer
plugin expects directly.

## Step 3: Apply Terraform, then run Packer

```bash
terraform init
terraform apply
packer build -var-file=build.pkrvars.hcl proxmox-template.pkr.hcl
```

The first `terraform apply` downloads the ISO and SHA-verifies it server-side. Subsequent
applies with the same `iso_pin` are no-ops. Bumping any field of `iso_pin` triggers a
fresh download on the next apply.

## Bumping the ISO

When upstream releases a new ISO version:

1. Fetch the new SHA256 from a trusted upstream channel (e.g. the upstream's signed
   `CHECKSUM` file, **not** the same mirror as the URL — see [threat-model.md](../explanation/threat-model.md)
   for why this matters).
2. Update the `iso_pin` object in your Terraform code: new `url`, new `sha256`, new
   `filename`.
3. Commit the change. The git history of your `iso_pin` assignment **is** the long-lived
   audit trail of which ISOs your build has consumed over time.
4. Run `terraform apply` to download and SHA-verify the new ISO.
5. Run `packer build` against the regenerated `build.pkrvars.hcl` to produce the new
   Packer template.

## Bumping the module itself

When this module ships a new version:

1. Update `?ref=v1.0.0` to the new tag in your `module "iso"` block.
2. Update `required_version = "= 1.15.1"` and `version = "= 0.105.0"` if the new module
   version pins different versions. The new module's README documents the required
   versions.
3. Run `terraform init -upgrade` and `terraform plan`; review the diff.
4. Run `terraform apply`.

## Troubleshooting

- **`terraform init` fails with "required Terraform version is = 1.15.1"**: install
  Terraform 1.15.1 exactly. This is intentional — see
  [org ADR-0005](../decision-records/org/0005-pin-terraform-and-provider-versions-exactly.md).
- **`proxmox_download_file` fails with checksum mismatch**: the SHA in `iso_pin` does
  not match the upstream file. Either upstream changed the file (in which case re-fetch
  the SHA) or the URL is serving something different than expected. The integrity check
  is working as designed — do not bypass it without understanding why it triggered.
- **`proxmox_download_file` returns 401 / 403**: the API token lacks
  `Datastore.AllocateSpace` or related privileges. See the bpg/proxmox provider docs.
- **`module "iso"` source URL fails with "module not found"**: check that `//terraform`
  is present in the source string. Without it, Terraform tries to find the module at the
  repository root and reports "no module configuration files found".

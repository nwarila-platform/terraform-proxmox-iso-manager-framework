# How to use this module from a Packer template repository

This guide walks through importing `terraform-proxmox-iso-manager-framework` from a Packer
template repository (e.g. `secure-rockylinux9-template`). The module's job is to download
and SHA-verify a single ISO; the calling Terraform configuration emits a Packer
`pkrvars.hcl` file that points Packer at the verified ISO.

## Prerequisites

- A Proxmox VE cluster reachable via the bpg/proxmox provider.
- A storage datastore on Proxmox with ISO content type enabled (e.g. `cephFS`, `local`).
- A Proxmox API token scoped to least privilege (see below).
- The exact Terraform version pinned in [`../../terraform/versions.tf`](../../terraform/versions.tf).
  Use `tfenv` or `asdf` if you manage multiple versions on one workstation.
  Any other Terraform version causes `terraform init` to fail.

## Least-privilege Proxmox access

`proxmox_download_file` needs exactly these privileges:

- `Datastore.AllocateTemplate` on the target storage (write the ISO into the
  storage's `iso/` content directory).
- `Sys.Audit` and `Sys.Modify` on the target node (run and observe the
  download task).

Requirements for consumers:

- **MUST** use a dedicated API token per environment, scoped to only the
  privileges above on only the target node and storage. Create a role
  (e.g. `IsoDownloader`) containing exactly those three privileges and assign
  it to the token on the specific `/storage/<datastore>` and `/nodes/<node>`
  paths.
- **MUST NOT** reuse a broad VM-admin token or a `root@pam` credential for
  this module. The module's blast radius should be limited to ISO download;
  a token that can also create/destroy VMs or modify cluster config expands
  the impact of a compromised CI runner well beyond this module's purpose.
- **MUST** store Terraform state in a remote backend with locking and
  restricted read access. Local state is acceptable only for disposable local
  development. State can contain the echoed `iso_url` and resource metadata;
  treat it as sensitive.

## Step 1: Pin the module in your Terraform configuration

In your Packer template repo's Terraform code, use the exact Terraform and provider pins
from [`../../terraform/versions.tf`](../../terraform/versions.tf), then configure the
provider and module call:

```hcl
provider "proxmox" {
  endpoint  = "https://proxmox.example.test:8006/"
  api_token = var.proxmox_api_token
  insecure  = false
}

module "iso" {
  source = "git::https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework.git//terraform?ref=<release-tag>"

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

Use non-tokenized ISO URLs. Query strings, fragments, and embedded credentials are
rejected because Terraform outputs and state include the echoed `iso_url` for provenance.

## Step 2: Emit a Packer pkrvars.hcl file

Render the module's flat outputs into a `boot_iso` object literal and an
`additional_iso_files` list that match the typed variables declared by
[`nwarila-platform/proxmox-packer-framework`](https://github.com/nwarila-platform/proxmox-packer-framework)
in `packer/variables.pkr.hcl`. Auto-loaded pkrvars files (`*.auto.pkrvars.hcl`) are the
recommended carrier.

```hcl
resource "local_file" "packer_vars" {
  filename = "${path.root}/iso.auto.pkrvars.hcl"
  content  = <<-EOT
    boot_iso = {
      iso_checksum         = "sha256:${module.iso.iso_sha256}"
      iso_file             = "${module.iso.iso_path}"
      iso_urls             = null
      cd_label             = null
      index                = 0
      iso_download_pve     = false
      iso_storage_pool     = null
      iso_target_extension = null
      iso_target_path      = null
      keep_cdrom_device    = false
      type                 = "scsi"
      unmount              = true
    }

    additional_iso_files = []
  EOT
}
```

`module.iso.iso_path` is the `<storage>:iso/<filename>` form that the proxmox-packer-framework
expects in `boot_iso.iso_file`. The ISO-lifecycle fields (`iso_checksum`, `iso_file`,
`iso_urls`, `iso_download_pve`, `iso_storage_pool`, `iso_target_*`) are fixed by this
module's contract; the consumer-policy fields (`cd_label`, `index`, `keep_cdrom_device`,
`type`, `unmount`) default to the values used by the proxmox-packer-framework examples
and should be overridden in your consumer repo when needed. `additional_iso_files` is
empty because this module manages one boot ISO and no secondary ISO attachments.

## Step 3: Apply Terraform, then run Packer

```bash
terraform init
terraform apply
packer build proxmox-template.pkr.hcl
```

Packer auto-loads any `*.auto.pkrvars.hcl` file in the working directory, so `iso.auto.pkrvars.hcl`
is consumed without an explicit `-var-file` flag.

The first `terraform apply` downloads the ISO and SHA-verifies it server-side. Subsequent
applies with the same `iso_pin` are no-ops. Bumping any field of `iso_pin` triggers a
fresh download on the next apply.

## Bumping the ISO

When upstream releases a new ISO version:

1. Fetch the new SHA-256 from a trusted upstream channel (e.g. the upstream's signed
   `CHECKSUM` file, **not** the same mirror as the URL — see [threat-model.md](../explanation/threat-model.md)
   for why this matters).
2. Update the `iso_pin` object in your Terraform code: new `url`, new `sha256`, new
   `filename`.
3. Commit the change. The git history of your `iso_pin` assignment **is** the long-lived
   audit trail of which ISOs your build has consumed over time.
4. Run `terraform apply` to download and SHA-verify the new ISO.
5. Run `packer build` against the regenerated `iso.auto.pkrvars.hcl` to produce the new
   Packer template.

## Bumping the module itself

When this module ships a new version:

1. Update `?ref=<old-release-tag>` to the new tag in your `module "iso"` block.
2. Update the Terraform and provider pins if the new module version changes them. The new
   module's README documents the required versions.
3. Run `terraform init -upgrade` and `terraform plan`; review the diff.
4. Run `terraform apply`.

## Troubleshooting

- **`terraform init` fails with a required Terraform version error**: install the exact
  Terraform version pinned by the module in [`../../terraform/versions.tf`](../../terraform/versions.tf).
- **`proxmox_download_file` fails with checksum mismatch**: the SHA in `iso_pin` does
  not match the upstream file. Either upstream changed the file (in which case re-fetch
  the SHA) or the URL is serving something different than expected. The integrity check
  is working as designed — do not bypass it without understanding why it triggered.
- **`proxmox_download_file` returns 401 / 403**: the API token lacks
  `Datastore.AllocateTemplate` on the storage or `Sys.Audit` / `Sys.Modify`
  on the node. See the Least-privilege Proxmox access section above.
- **`module "iso"` source URL fails with "module not found"**: check that `//terraform`
  is present in the source string. Without it, Terraform tries to find the module at the
  repository root and reports "no module configuration files found".

# Terraform Reference

This file is partially generated from [`../../terraform/`](../../terraform/) by
`terraform-docs`. Manual notes stay outside the markers; generated provider, resource,
input, and output tables stay inside the markers.

## Security Notes

The module intentionally rejects tokenized, presigned, or credential-bearing ISO URLs.
Query strings, fragments, whitespace, non-HTTPS schemes, missing hosts, missing paths, and
embedded credentials are rejected before planning. Terraform state, plans, logs, and
outputs are not safe places for bearer tokens.

`iso_url` is kept as an output only because the URL contract rejects those common
secret-bearing shapes. Consumers must still avoid putting secrets in path segments.

## Version Pins

Exact Terraform and provider pins live in [`../../terraform/versions.tf`](../../terraform/versions.tf).
The generated tables below intentionally avoid duplicating those version numbers.

<!-- BEGIN_TF_DOCS -->
## Resources

| Name | Type |
| ---- | ---- |
| [proxmox_download_file.iso](https://registry.terraform.io/providers/bpg/proxmox/0.105.0/docs/resources/download_file) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| family | Template family discriminator (e.g. "rocky9", "ubuntu24"). Provenance-only: this<br/>value is NOT consumed by any resource in this module - it is echoed back through the<br/>`family` output so consumers (typically Packer template repos) can correlate the<br/>managed ISO with the template family it feeds. Must match Proxmox tag character<br/>constraints (lowercase letters, digits, hyphens, dots, underscores) so consumers can<br/>pass it directly into Proxmox tags downstream. | `string` | n/a | yes |
| iso\_pin | Pin specifying the exact ISO this module will manage on Proxmox storage. The url is a<br/>non-tokenized HTTPS URL with a host and path, and it may not contain whitespace, query<br/>strings, fragments, or embedded credentials. The url is fetched once on first apply (or<br/>when sha256 changes); the sha256 is enforced server-side by the Proxmox download<br/>endpoint after the file lands. The filename is the on-disk name in the target storage's<br/>iso/ directory.<br/><br/>The consumer's git repository is the long-lived audit trail for this pin: replacing the<br/>pin in the consumer's HCL records the ISO change in git history with full diffability. | <pre>object({<br/>    url      = string<br/>    sha256   = string<br/>    filename = string<br/>  })</pre> | n/a | yes |
| node | Proxmox node name on which the download is performed. Required by the bpg/proxmox<br/>provider's proxmox\_download\_file resource. For shared/cluster<br/>storage like cephFS, any node works because the resulting file is cluster-visible; pick<br/>one consistently to keep the download localized. | `string` | n/a | yes |
| overwrite | When true, allow the provider to replace the managed file when its size changes outside<br/>Terraform or the upstream URL reports a different size. Defaults to false for pinned ISO<br/>inputs: once Terraform owns the file, the provider does not re-check upstream size on<br/>refresh. This does not take ownership of unmanaged pre-existing files; use<br/>overwrite\_unmanaged for that explicit recovery path. | `bool` | `false` | no |
| overwrite\_unmanaged | When true, delete and replace an unmanaged file that already exists at the target<br/>Proxmox storage path. Defaults to false so the module fails closed if a same-named ISO<br/>exists outside Terraform state. Set true only during deliberate adoption/recovery. | `bool` | `false` | no |
| storage | Proxmox storage datastore where the ISO will be placed (e.g. "cephFS", "local"). The<br/>storage MUST have ISO content type enabled in its Proxmox configuration. | `string` | n/a | yes |
| upload\_timeout | Timeout in seconds for the Proxmox download-url operation. Defaults to one hour so<br/>large installer ISOs can be fetched reliably on homelab or WAN-backed storage without<br/>weakening transport verification. | `number` | `3600` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| family | Template family discriminator, echoed back for downstream label/output use. |
| iso\_filename | On-disk filename of the managed ISO. Echoed back for downstream pathing. |
| iso\_id | Proxmox file ID for the managed ISO, in the form "<datastore>:<volume\_id>". This is the<br/>canonical identifier the bpg/proxmox provider uses to reference the file in subsequent<br/>resources. |
| iso\_path | Storage-prefixed path consumable by Packer's proxmox-iso plugin `iso_file` field, e.g.<br/>"cephFS:iso/Rocky-9.6-x86\_64-dvd.iso". Pass this directly into the consumer template<br/>repo's Packer configuration. |
| iso\_sha256 | SHA-256 digest of the managed ISO, echoed back from input. Useful for downstream<br/>consumers (e.g. SLSA provenance generators, audit log emitters) that want to record<br/>which exact ISO a build consumed. |
| iso\_url | Non-tokenized upstream URL the ISO was downloaded from. Echoed back for provenance recording. |
| node | Proxmox node where the download was performed. |
| storage | Proxmox storage datastore the ISO landed on. |
<!-- END_TF_DOCS -->

## Validation Notes

Every constrained input has Terraform test coverage in
[`../../terraform/tests/validation.tftest.hcl`](../../terraform/tests/validation.tftest.hcl).
Validation runs at plan time before provider operations.

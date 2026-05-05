# Support

## Scope

This repository supports the `terraform-proxmox-iso-manager-framework` module and the
repository automation around it. This includes the module contract, validation, CI/CD, and
the developer workflow needed to work on it safely.

## Out of Scope

The following are **not** supported through this repository:

- Troubleshooting Proxmox VE environments.
- Debugging the `bpg/proxmox` Terraform provider — file those upstream at
  [bpg/terraform-provider-proxmox](https://github.com/bpg/terraform-provider-proxmox).
- Issues with the upstream ISO source (e.g. `dl.rockylinux.org` outages or wrong checksums).
- Custom Terraform code that wraps this module — own that in your downstream project.

## Getting Help

When opening an issue, include:

- the `?ref=` value your consumer pins
- the exact error message
- a minimal reproduction snippet
- Terraform, provider, and Proxmox VE versions

## Where to Ask

- **Bugs**: see [bug report template](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/issues/new?template=bug_report.yml)
- **Features / contract changes**: see [feature request template](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/issues/new?template=feature_request.yml)
- **Security**: see the repository's [Security Policy](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/security/policy) (inherited from [`nwarila-platform/.github`](https://github.com/nwarila-platform/.github/blob/main/SECURITY.md))

# Minimal Example

This fixture shows the smallest normal consumer shape: configure the Proxmox provider,
call the module from `../../terraform`, and pass `module.iso.iso_path` to downstream
tooling.

It is intentionally not a runnable public demo because `terraform apply` requires a real
Proxmox endpoint, storage datastore, and credentials supplied by the operator.

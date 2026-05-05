# Adoption And Recovery Example

This fixture documents the dangerous path deliberately.

Use `overwrite_unmanaged = true` only when an operator has confirmed that a same-named
ISO already present in Proxmox storage should be deleted and replaced by the pinned file.
Normal consumers should leave this flag at its default `false` value so unmanaged files
fail closed.

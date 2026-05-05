# Failure Cases

These are examples of inputs the module rejects before provider operations start.

## Tokenized Or Signed URL

```hcl
iso_pin = {
  url      = "https://example.test/Rocky.iso?token=secret"
  sha256   = "0000000000000000000000000000000000000000000000000000000000000000"
  filename = "Rocky.iso"
}
```

Query strings are rejected because `iso_url` is an output and Terraform plans/state can
expose values embedded in URLs.

## Path Traversal Filename

```hcl
iso_pin = {
  url      = "https://example.test/Rocky.iso"
  sha256   = "0000000000000000000000000000000000000000000000000000000000000000"
  filename = "../Rocky.iso"
}
```

Filenames must be simple ISO filenames, not paths.

## Unmanaged Overwrite During Normal Operation

```hcl
module "iso" {
  source = "../../terraform"

  # ...

  overwrite_unmanaged = true
}
```

This is valid only for deliberate adoption or recovery. Normal consumers should omit it
so the default `false` value fails closed.

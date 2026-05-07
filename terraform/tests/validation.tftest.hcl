# Coverage of every validation block in variables.tf. Uses mock_provider so no
# real Proxmox endpoint is required; validation blocks fire before provider
# initialisation either way.
#
# Layout:
#   - One file-scope variables block establishes a known-valid baseline. Each
#     run block overrides exactly one variable to exercise one validation rule.
#   - "happy path" runs assert that valid inputs produce expected outputs.
#   - "rejects_*" runs use expect_failures to assert that the expected variable
#     validation fires.

mock_provider "proxmox" {}

variables {
  family  = "rocky9"
  node    = "test-node"
  storage = "test-storage"
  iso_pin = {
    url      = "https://example.test/foo.iso"
    sha256   = "0000000000000000000000000000000000000000000000000000000000000000"
    filename = "foo.iso"
  }
}

# ----- Happy path -----

run "valid_inputs_pass_all_validations" {
  command = plan

  assert {
    condition     = output.family == "rocky9"
    error_message = "family output should echo back the input value"
  }

  assert {
    condition     = output.iso_path == "test-storage:iso/foo.iso"
    error_message = "iso_path should be '<storage>:iso/<filename>'"
  }

  assert {
    condition     = output.iso_sha256 == "0000000000000000000000000000000000000000000000000000000000000000"
    error_message = "iso_sha256 output should echo back the input sha256"
  }

  assert {
    condition     = output.iso_filename == "foo.iso"
    error_message = "iso_filename output should echo back the input filename"
  }
}

run "accepts_valid_iso_pin" {
  command = plan

  assert {
    condition     = output.iso_url == "https://example.test/foo.iso"
    error_message = "iso_url should echo back a valid non-tokenized HTTPS URL"
  }
}

run "default_safety_flags_fail_closed" {
  command = plan

  assert {
    condition     = proxmox_download_file.iso.overwrite == false
    error_message = "overwrite should default to false"
  }

  assert {
    condition     = proxmox_download_file.iso.overwrite_unmanaged == false
    error_message = "overwrite_unmanaged should default to false"
  }
}

run "verify_is_always_true" {
  command = plan

  assert {
    condition     = proxmox_download_file.iso.verify == true
    error_message = "TLS verification should always be enabled for Proxmox download-url operations"
  }
}

run "upload_timeout_default_is_safe" {
  command = plan

  assert {
    condition     = proxmox_download_file.iso.upload_timeout == 3600
    error_message = "upload_timeout should default to one hour"
  }
}

run "accepts_upload_timeout_default" {
  command = plan

  assert {
    condition     = proxmox_download_file.iso.upload_timeout == 3600
    error_message = "upload_timeout should use the documented default when omitted"
  }
}

# ----- null required input validation -----

run "rejects_null_family" {
  command = plan

  variables {
    family = null
  }

  expect_failures = [var.family]
}

run "rejects_null_iso_pin" {
  command = plan

  variables {
    iso_pin = null
  }

  expect_failures = [var.iso_pin]
}

run "rejects_null_node" {
  command = plan

  variables {
    node = null
  }

  expect_failures = [var.node]
}

run "rejects_null_storage" {
  command = plan

  variables {
    storage = null
  }

  expect_failures = [var.storage]
}

# ----- family validation -----

run "rejects_uppercase_family" {
  command = plan
  variables {
    family = "Rocky9"
  }
  expect_failures = [var.family]
}

run "rejects_family_with_spaces" {
  command = plan
  variables {
    family = "rocky 9"
  }
  expect_failures = [var.family]
}

run "rejects_family_with_slash" {
  command = plan
  variables {
    family = "rocky/9"
  }
  expect_failures = [var.family]
}

run "rejects_empty_family" {
  command = plan
  variables {
    family = ""
  }
  expect_failures = [var.family]
}

# ----- iso_pin.url validation -----

run "rejects_http_url" {
  command = plan
  variables {
    iso_pin = {
      url      = "http://example.test/foo.iso"
      sha256   = "0000000000000000000000000000000000000000000000000000000000000000"
      filename = "foo.iso"
    }
  }
  expect_failures = [var.iso_pin]
}

run "rejects_ftp_url" {
  command = plan
  variables {
    iso_pin = {
      url      = "ftp://example.test/foo.iso"
      sha256   = "0000000000000000000000000000000000000000000000000000000000000000"
      filename = "foo.iso"
    }
  }
  expect_failures = [var.iso_pin]
}

run "rejects_file_url" {
  command = plan
  variables {
    iso_pin = {
      url      = "file:///tmp/foo.iso"
      sha256   = "0000000000000000000000000000000000000000000000000000000000000000"
      filename = "foo.iso"
    }
  }
  expect_failures = [var.iso_pin]
}

run "rejects_https_url_without_host" {
  command = plan
  variables {
    iso_pin = {
      url      = "https:///foo.iso"
      sha256   = "0000000000000000000000000000000000000000000000000000000000000000"
      filename = "foo.iso"
    }
  }
  expect_failures = [var.iso_pin]
}

run "rejects_https_url_without_path" {
  command = plan
  variables {
    iso_pin = {
      url      = "https://example.test"
      sha256   = "0000000000000000000000000000000000000000000000000000000000000000"
      filename = "foo.iso"
    }
  }
  expect_failures = [var.iso_pin]
}

run "rejects_url_with_whitespace" {
  command = plan
  variables {
    iso_pin = {
      url      = "https://example.test/foo bar.iso"
      sha256   = "0000000000000000000000000000000000000000000000000000000000000000"
      filename = "foo.iso"
    }
  }
  expect_failures = [var.iso_pin]
}

run "rejects_url_with_query_string_token" {
  command = plan
  variables {
    iso_pin = {
      url      = "https://example.test/foo.iso?token=secret"
      sha256   = "0000000000000000000000000000000000000000000000000000000000000000"
      filename = "foo.iso"
    }
  }
  expect_failures = [var.iso_pin]
}

run "rejects_url_with_query_string" {
  command = plan
  variables {
    iso_pin = {
      url      = "https://example.test/foo.iso?mirror=primary"
      sha256   = "0000000000000000000000000000000000000000000000000000000000000000"
      filename = "foo.iso"
    }
  }
  expect_failures = [var.iso_pin]
}

run "rejects_url_with_fragment" {
  command = plan
  variables {
    iso_pin = {
      url      = "https://example.test/foo.iso#sha256"
      sha256   = "0000000000000000000000000000000000000000000000000000000000000000"
      filename = "foo.iso"
    }
  }
  expect_failures = [var.iso_pin]
}

run "rejects_url_with_embedded_credentials" {
  command = plan
  variables {
    iso_pin = {
      url      = "https://user:pass@example.test/foo.iso"
      sha256   = "0000000000000000000000000000000000000000000000000000000000000000"
      filename = "foo.iso"
    }
  }
  expect_failures = [var.iso_pin]
}

# ----- iso_pin.sha256 validation -----

run "rejects_short_sha" {
  command = plan
  variables {
    iso_pin = {
      url      = "https://example.test/foo.iso"
      sha256   = "abcdef"
      filename = "foo.iso"
    }
  }
  expect_failures = [var.iso_pin]
}

run "rejects_uppercase_sha" {
  command = plan
  variables {
    iso_pin = {
      url      = "https://example.test/foo.iso"
      sha256   = "ABCDEF0000000000000000000000000000000000000000000000000000000000"
      filename = "foo.iso"
    }
  }
  expect_failures = [var.iso_pin]
}

run "rejects_non_hex_sha" {
  command = plan
  variables {
    iso_pin = {
      url      = "https://example.test/foo.iso"
      sha256   = "ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg0"
      filename = "foo.iso"
    }
  }
  expect_failures = [var.iso_pin]
}

# ----- iso_pin.filename validation -----

run "rejects_filename_without_iso_extension" {
  command = plan
  variables {
    iso_pin = {
      url      = "https://example.test/foo.iso"
      sha256   = "0000000000000000000000000000000000000000000000000000000000000000"
      filename = "foo.img"
    }
  }
  expect_failures = [var.iso_pin]
}

run "rejects_filename_with_path_traversal" {
  command = plan
  variables {
    iso_pin = {
      url      = "https://example.test/foo.iso"
      sha256   = "0000000000000000000000000000000000000000000000000000000000000000"
      filename = "../foo.iso"
    }
  }
  expect_failures = [var.iso_pin]
}

run "rejects_filename_with_subdirectory" {
  command = plan
  variables {
    iso_pin = {
      url      = "https://example.test/foo.iso"
      sha256   = "0000000000000000000000000000000000000000000000000000000000000000"
      filename = "subdir/foo.iso"
    }
  }
  expect_failures = [var.iso_pin]
}

run "rejects_filename_with_spaces" {
  command = plan
  variables {
    iso_pin = {
      url      = "https://example.test/foo.iso"
      sha256   = "0000000000000000000000000000000000000000000000000000000000000000"
      filename = "foo bar.iso"
    }
  }
  expect_failures = [var.iso_pin]
}

# ----- node validation -----

run "rejects_empty_node" {
  command = plan
  variables {
    node = ""
  }
  expect_failures = [var.node]
}

run "rejects_whitespace_node" {
  command = plan
  variables {
    node = "   "
  }
  expect_failures = [var.node]
}

run "rejects_node_with_slash" {
  command = plan
  variables {
    node = "cluster/node"
  }
  expect_failures = [var.node]
}

run "rejects_node_with_colon" {
  command = plan
  variables {
    node = "cluster:node"
  }
  expect_failures = [var.node]
}

# ----- storage validation -----

run "rejects_empty_storage" {
  command = plan
  variables {
    storage = ""
  }
  expect_failures = [var.storage]
}

run "rejects_whitespace_storage" {
  command = plan
  variables {
    storage = "  "
  }
  expect_failures = [var.storage]
}

run "rejects_storage_with_slash" {
  command = plan
  variables {
    storage = "pool/iso"
  }
  expect_failures = [var.storage]
}

run "rejects_storage_with_colon" {
  command = plan
  variables {
    storage = "pool:iso"
  }
  expect_failures = [var.storage]
}

# ----- upload_timeout validation -----

run "rejects_upload_timeout_below_minimum" {
  command = plan
  variables {
    upload_timeout = 59
  }
  expect_failures = [var.upload_timeout]
}

run "rejects_upload_timeout_too_low" {
  command = plan
  variables {
    upload_timeout = 1
  }
  expect_failures = [var.upload_timeout]
}

run "rejects_upload_timeout_above_maximum" {
  command = plan
  variables {
    upload_timeout = 86401
  }
  expect_failures = [var.upload_timeout]
}

run "rejects_upload_timeout_too_high" {
  command = plan
  variables {
    upload_timeout = 90000
  }
  expect_failures = [var.upload_timeout]
}

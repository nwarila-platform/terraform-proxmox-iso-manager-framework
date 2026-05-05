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

package iso_manager

import rego.v1

valid_input := {
  "iso_pins": [
    {"url": "https://example.test/Rocky.iso"},
  ],
  "module_settings": [
    {"path": "terraform/resources.tf", "overwrite_unmanaged": false},
    {"path": "examples/adoption-recovery/main.tf", "overwrite_unmanaged": true},
  ],
  "files": {
    "terraform/resources.tf": "checksum_algorithm = \"sha256\"\nverify             = true\n",
    ".github/workflows/release-evidence.yaml": "name: Release Evidence\n",
  },
}

test_valid_input_allows if {
  messages := deny with input as valid_input
  count(messages) == 0
}

test_rejects_query_string if {
  messages := deny with input as object.union(valid_input, {
    "iso_pins": [{"url": "https://example.test/Rocky.iso?token=secret"}],
  })
  some msg in messages
  contains(msg, "query string")
}

test_rejects_fragment if {
  messages := deny with input as object.union(valid_input, {
    "iso_pins": [{"url": "https://example.test/Rocky.iso#sha256"}],
  })
  some msg in messages
  contains(msg, "fragment")
}

test_rejects_non_https if {
  messages := deny with input as object.union(valid_input, {
    "iso_pins": [{"url": "http://example.test/Rocky.iso"}],
  })
  some msg in messages
  contains(msg, "HTTPS")
}

test_rejects_embedded_credentials if {
  messages := deny with input as object.union(valid_input, {
    "iso_pins": [{"url": "https://user:pass@example.test/Rocky.iso"}],
  })
  some msg in messages
  contains(msg, "embedded credentials")
}

test_rejects_overwrite_unmanaged_outside_exception if {
  messages := deny with input as object.union(valid_input, {
    "module_settings": [{"path": "examples/minimal/main.tf", "overwrite_unmanaged": true}],
  })
  some msg in messages
  contains(msg, "overwrite_unmanaged")
}

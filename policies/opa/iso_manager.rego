package iso_manager

import rego.v1

deny contains msg if {
  pin := input.iso_pins[_]
  not startswith(pin.url, "https://")
  msg := sprintf("ISO URL must use HTTPS: %s", [pin.url])
}

deny contains msg if {
  pin := input.iso_pins[_]
  contains(pin.url, "?")
  msg := sprintf("ISO URL must not contain a query string: %s", [pin.url])
}

deny contains msg if {
  pin := input.iso_pins[_]
  contains(pin.url, "#")
  msg := sprintf("ISO URL must not contain a fragment: %s", [pin.url])
}

deny contains msg if {
  pin := input.iso_pins[_]
  regex.match("^https://[^/]*@", pin.url)
  msg := sprintf("ISO URL must not contain embedded credentials: %s", [pin.url])
}

deny contains msg if {
  setting := input.module_settings[_]
  setting.overwrite_unmanaged == true
  not startswith(setting.path, "examples/adoption-recovery/")
  msg := sprintf("overwrite_unmanaged=true is limited to adoption recovery examples: %s", [setting.path])
}

deny contains msg if {
  resources := input.files["terraform/resources.tf"]
  not regex.match("checksum_algorithm\\s*=\\s*\"sha256\"", resources)
  msg := "terraform/resources.tf must require checksum_algorithm = \"sha256\""
}

deny contains msg if {
  resources := input.files["terraform/resources.tf"]
  not regex.match("verify\\s*=\\s*true", resources)
  msg := "terraform/resources.tf must set verify = true"
}

deny contains msg if {
  not input.files[".github/workflows/release-evidence.yml"]
  msg := "release evidence workflow must exist"
}

deny contains msg if {
  not input.files[".github/workflows/graph-regression.yml"]
  msg := "graph regression workflow must exist"
}

# Changelog

## [1.2.0](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/compare/v1.1.2...v1.2.0) (2026-05-27)


### Features

* **ci:** reusable CodeQL + bump pins to 2f343e5 ([#31](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/issues/31)) ([5b9cf63](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/commit/5b9cf6304b119d036e3a32b6930432d769ac2986))
* consume nwarila/terraform-template@aeb3d18 ([#18](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/issues/18)) ([e7a7c96](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/commit/e7a7c966cf8375832d84f56adabd09d03a534bd9))
* consume reusable IaC security workflow; pin all to 7fdf7bc ([#25](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/issues/25)) ([ec0c31b](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/commit/ec0c31b46a0d4b0af0158a3b293df9e1cb633e25))
* **security:** adopt OpenSSF Scorecard + bump pin to 9d354ff ([#40](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/issues/40)) ([cb8913a](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/commit/cb8913a77662beaf4aca73da8be4201cdf57ff97))


### Bug Fixes

* **ci:** restore mode: full input on pr-validation caller ([#43](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/issues/43)) ([2b76a61](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/commit/2b76a61097ed0d2c0edef9a71a7c8f340d1a385d))
* **security:** grant required permissions at caller job level ([#26](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/issues/26)) ([7a6ec64](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/commit/7a6ec648f43f771f7b45629fd612ca75f204703b))
* **test:** remove broken null-rejection tests for nullable=false vars ([#20](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/issues/20)) ([30e2e34](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/commit/30e2e3486cea57a1a23cddf2b671c46231237b82))

## [1.1.2](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/compare/v1.1.1...v1.1.2) (2026-05-05)


### Bug Fixes

* **ci:** auto-dispatch release-evidence after release-please publishes ([#16](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/issues/16)) ([5a9a5f4](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/commit/5a9a5f415f53678b61452fa85a356c7ca32dd094))

## [1.1.1](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/compare/v1.1.0...v1.1.1) (2026-05-05)


### Bug Fixes

* **lint:** allow duplicate headings under different parents in CHANGELOG ([#14](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/issues/14)) ([fd9fb1b](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/commit/fd9fb1b3129e5587833b46271e78d7e84bf3a3e4))

## [1.1.0](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/compare/v1.0.2...v1.1.0) (2026-05-05)


### Features

* add release evidence, graph validation, and policy gates ([db09e2b](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/commit/db09e2b3cb6969ae8e66513b3de0fe8f0777b267))


### Bug Fixes

* **ci:** satisfy new docs-diff and opa-test gates ([e74178b](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/commit/e74178b2a576172defe689cfa7ea27e1144ebd45))

## [1.0.2](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/compare/v1.0.1...v1.0.2) (2026-05-05)


### Bug Fixes

* harden module contract with runnable examples ([7e34a0e](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/commit/7e34a0e0afaa283f2041f7110871d596e3bd68bb))

## [1.0.1](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/compare/v1.0.0...v1.0.1) (2026-05-05)


### Maintenance

* align generated changelog formatting with markdownlint ([975df29](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/commit/975df2987bab2bab63efafd0becd555b84346533))

## 1.0.0 (2026-05-05)

### Features

* finalize iso-manager hardening and inherited defaults ([9c1e074](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/commit/9c1e074727af60913f9c8a80d6a33f0c1d7f6721))
* initial repo bootstrap + iso-manager module ([#1](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/issues/1)) ([18c7c70](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework/commit/18c7c700538f9910c29c820e377394547b46a678))

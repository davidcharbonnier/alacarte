# @alacarte/api

## [0.5.0](https://github.com/davidcharbonnier/alacarte/compare/v0.4.0...v0.5.0) (2025-10-21)


### Features

* **api:** Implement image upload and storage to S3 compatible storage ([4ecfac6](https://github.com/davidcharbonnier/alacarte/commit/4ecfac64f2ac0484054a01a228d52458377754b0))
* **api:** Make image download a user API endpoint ([8a70b26](https://github.com/davidcharbonnier/alacarte/commit/8a70b26dc345361c4058f4fb290f682555d7d664))


### Bug Fixes

* **api:** Add GCS compatibility for image storage ([b6af916](https://github.com/davidcharbonnier/alacarte/commit/b6af9165ede8540bf076481bc5abd4fb75eea34f))
* **api:** Move image management endpoints into item type groups ([73d57a8](https://github.com/davidcharbonnier/alacarte/commit/73d57a85a4be2a7fca16e11da87daabe1c75342e))
* **api:** Support EXIF orientation before storing image ([83a05b7](https://github.com/davidcharbonnier/alacarte/commit/83a05b741905b66a415f640f180aea529d58680c))

## [0.4.0](https://github.com/davidcharbonnier/alacarte/compare/api-v0.3.1...api-v0.4.0) (2025-10-17)


### Features

* add wine item type to api and improve seeding process by supporting json file upload ([c064fa8](https://github.com/davidcharbonnier/alacarte/commit/c064fa8bee1c6f7f7e91fc03486eeb1b1e87d6dc))
* migrate wine color to enum type, add support for checkboxes and dropdown in forms and fix some issues for wine display ([0116dc4](https://github.com/davidcharbonnier/alacarte/commit/0116dc468c5a71727855834f4958cf77bebc49a2))

## 0.3.1

### Patch Changes

- [#13](https://github.com/davidcharbonnier/alacarte/pull/13) [`e67c9ee`](https://github.com/davidcharbonnier/alacarte/commit/e67c9ee46c1cd8d71d8e15380ca8d8aa93182023) Thanks [@davidcharbonnier](https://github.com/davidcharbonnier)! - Fixing CI workflow for releasing

## 0.3.0

### Minor Changes

- [#11](https://github.com/davidcharbonnier/alacarte/pull/11) [`934b3d2`](https://github.com/davidcharbonnier/alacarte/commit/934b3d2ccefa1f3bcaf7b7545e4d6ee5d9db06ad) Thanks [@davidcharbonnier](https://github.com/davidcharbonnier)! - Add wine item type

## 0.2.4

## 0.2.3

### Patch Changes

- [`89621b4`](https://github.com/davidcharbonnier/alacarte/commit/89621b42d651d8139954004cf27065d482e93039) - Fixed release workflow detection to trigger on Version PR merge

## 0.2.2

### Patch Changes

- [`68a01bf`](https://github.com/davidcharbonnier/alacarte/commit/68a01bf99f3aafedfef53bd8e34d5ecee449301e) - Fixed release workflow detection logic

## 0.2.1

### Patch Changes

- [`7b8b305`](https://github.com/davidcharbonnier/alacarte/commit/7b8b3056c8a890a2be3b07e2ef3b83e522a26500) - Fix release workflow

## 0.2.0

### Minor Changes

- [`3bcd723`](https://github.com/davidcharbonnier/alacarte/commit/3bcd723f82deff365cbb2b9cd3a89e85f43d4c1b) - Migrated to monorepo structure with Changesets and Turborepo for better version management and CI/CD

# @alacarte/client

## [0.5.0](https://github.com/davidcharbonnier/alacarte/compare/v0.4.0...v0.5.0) (2025-10-21)


### Features

* **client:** Implement image display, cache and upload ([d4cca13](https://github.com/davidcharbonnier/alacarte/commit/d4cca1327b12b2b262d784c556279955a0f01f49))
* **client:** Implement image removal ([5b374c6](https://github.com/davidcharbonnier/alacarte/commit/5b374c67899d978387f1b6d70624dd5c545735b4))


### Bug Fixes

* **client:** Removing duplicated screen for generic item form ([8af8cf8](https://github.com/davidcharbonnier/alacarte/commit/8af8cf8853c674288e1b3d4c5af7dcd8fb52b743))

## [0.4.0](https://github.com/davidcharbonnier/alacarte/compare/client-v0.3.1...client-v0.4.0) (2025-10-17)


### Features

* add wine item type to client ([d53e76f](https://github.com/davidcharbonnier/alacarte/commit/d53e76fb0314600f7aca8d9ad30df57959e31afd))
* migrate wine color to enum type, add support for checkboxes and dropdown in forms and fix some issues for wine display ([0116dc4](https://github.com/davidcharbonnier/alacarte/commit/0116dc468c5a71727855834f4958cf77bebc49a2))


### Bug Fixes

* adding smart caching for items, ratings and community stats ([8fbb62d](https://github.com/davidcharbonnier/alacarte/commit/8fbb62dfd5bcfde1edcc807e3883c6c227d87e6a))
* capitalize sentences or words in form text fields ([5897c0c](https://github.com/davidcharbonnier/alacarte/commit/5897c0c854991ebc1578510fd079b0a0cfb1ba2a))
* change fab to rate an item to a button into personal rating section in the item detail screen ([9c1f2ce](https://github.com/davidcharbonnier/alacarte/commit/9c1f2cea403ce83b2423518d01b4c684cae0d45f))
* ensure back button save the correct selected tab ([caa7d78](https://github.com/davidcharbonnier/alacarte/commit/caa7d7810c88aa2c34c5b038aa162ee24830f26c))
* implement a notification helper and replace all notifications with helper calls ([eaadce3](https://github.com/davidcharbonnier/alacarte/commit/eaadce3a87f22541e3f0308de96715d4f03218fe))
* implement floating points grades with update on the grade form input to use a slider ([e47d075](https://github.com/davidcharbonnier/alacarte/commit/e47d075fca5cb6558ea8942e8bfc7287ec760df8))
* improve performances in api calls by using http2 and issuing parallel calls ([737541e](https://github.com/davidcharbonnier/alacarte/commit/737541ef4272069937319b501c39674d37beb213))
* show all items tab by default instead of personal list ([e7f8743](https://github.com/davidcharbonnier/alacarte/commit/e7f874349077843a8de216f169f88933fb6f0ecc))
* sort lists alphabetically ([c62a12a](https://github.com/davidcharbonnier/alacarte/commit/c62a12a85af1d5c578a95ea8023c40e9adf47a5c))
* update fab on item list and item detail screens to avoid overlapping on content ([810427d](https://github.com/davidcharbonnier/alacarte/commit/810427da991086f7d8317241f90317711254a0dc))

## 0.3.1

### Patch Changes

- [#13](https://github.com/davidcharbonnier/alacarte/pull/13) [`e67c9ee`](https://github.com/davidcharbonnier/alacarte/commit/e67c9ee46c1cd8d71d8e15380ca8d8aa93182023) Thanks [@davidcharbonnier](https://github.com/davidcharbonnier)! - Fixing CI workflow for releasing

## 0.3.0

### Minor Changes

- [#11](https://github.com/davidcharbonnier/alacarte/pull/11) [`934b3d2`](https://github.com/davidcharbonnier/alacarte/commit/934b3d2ccefa1f3bcaf7b7545e4d6ee5d9db06ad) Thanks [@davidcharbonnier](https://github.com/davidcharbonnier)! - Add wine item type

## 0.2.4

### Patch Changes

- [#8](https://github.com/davidcharbonnier/alacarte/pull/8) [`4149e6e`](https://github.com/davidcharbonnier/alacarte/commit/4149e6e9abbf174c7182e3b725c122fed4518a10) Thanks [@davidcharbonnier](https://github.com/davidcharbonnier)! - Improve performances and streamline notifications

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

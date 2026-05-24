# [2.1.0](https://github.com/davidcharbonnier/alacarte/compare/api-v2.0.0...api-v2.1.0) (2026-05-24)


### Features

* **api:** add GetTypeStats endpoint with pagination support ([9a536c3](https://github.com/davidcharbonnier/alacarte/commit/9a536c3beecb01abb673a0a47b43c6b475703e27))
* **client:** implement server-side pagination, search, and type stats ([952d392](https://github.com/davidcharbonnier/alacarte/commit/952d3927daa19d2022080e5a68235fda48ccc1db))

# [1.4.0](https://github.com/davidcharbonnier/alacarte/compare/api-v1.3.1...api-v1.4.0) (2026-05-22)


### Bug Fixes

* **admin:** resolve react query stale-data bug in schema editor ([d4316e3](https://github.com/davidcharbonnier/alacarte/commit/d4316e32e80fd6d12986bc717a5b4e47a368e22f))
* **admin:** update admin pages and layout for dynamic schemas ([6fd3e49](https://github.com/davidcharbonnier/alacarte/commit/6fd3e49ae530b366ed36ca2545b8c0d0b562f1fe))
* **admin:** update generic components to use dynamic schema api ([6fa05bd](https://github.com/davidcharbonnier/alacarte/commit/6fa05bd8a209e2194007f5a5c79f1204d403135b))
* **api:** add unique_fields and display to schema responses ([c25ce69](https://github.com/davidcharbonnier/alacarte/commit/c25ce692c9a10518640ccf24ede315a1301e0e69))
* **api:** add utf8mb4 collation to mysql connection and config ([d2303c4](https://github.com/davidcharbonnier/alacarte/commit/d2303c4c9bba01701277c6b9b12a959d6fc00ffc))
* **api:** address code review issues for dynamic item schema system ([5d3cc89](https://github.com/davidcharbonnier/alacarte/commit/5d3cc89b4ca680971920c1cedb9a46b8bc78da67))
* **api:** address code review issues for dynamic item schema system ([49affc6](https://github.com/davidcharbonnier/alacarte/commit/49affc6a08baf30328498a6240adc46b65412ccc))
* **api:** address pr review issues for dynamic item schema system ([076a306](https://github.com/davidcharbonnier/alacarte/commit/076a306a6de22384cf21019884a1db5426cd8700))
* **api:** create eav rows on migration and fix refreshschema version pointer ([5a98ab4](https://github.com/davidcharbonnier/alacarte/commit/5a98ab4d7c03c724a275ab38fb512a5d2c52393e))
* **api:** disable fk checks during automigrate to support pre-migration backups ([aa0c58b](https://github.com/davidcharbonnier/alacarte/commit/aa0c58b79caf99f1f146eb0c215866a6581d3362))
* **api:** fix build errors ([4bfb43e](https://github.com/davidcharbonnier/alacarte/commit/4bfb43e0cf227753eb317adb37c920a597ea8c17))
* **api:** handle json marshal errors and fix schema update timestamps ([8e98e81](https://github.com/davidcharbonnier/alacarte/commit/8e98e81358ec51ba65b80a2027e3717fedc86388))
* **api:** improve schema field parsing and add uniqueness check to query builder ([ad54bc9](https://github.com/davidcharbonnier/alacarte/commit/ad54bc94189d458917d6ff436d4341c130c49b77))
* **api:** prevent 304 not modified when if-none-match header is absent ([b76979f](https://github.com/davidcharbonnier/alacarte/commit/b76979fe7ea8abf2362cb651e6f5216457bf902e))
* **api:** resolve dynamic schema migration and api issues ([f83d0db](https://github.com/davidcharbonnier/alacarte/commit/f83d0dbd053f25a11d4f67eaff1cc6f4ea0f825e))
* **api:** resolve schema cache and field orphan issues from PR [#47](https://github.com/davidcharbonnier/alacarte/issues/47) review ([0a74c4f](https://github.com/davidcharbonnier/alacarte/commit/0a74c4fe29383ea4ac4b6d995a688ea31f06df9c))
* **api:** resolve transaction bypass, migration type, and query issues ([b7a4145](https://github.com/davidcharbonnier/alacarte/commit/b7a414502804be583f8b77ca4ceaf6652c95ce82))
* **api:** update go version in dockerfile ([2c4bffa](https://github.com/davidcharbonnier/alacarte/commit/2c4bffa683c28c160cf2e876ea0c64f966e27edb))
* **api:** update ratings in place during migration instead of creating duplicates ([65a2958](https://github.com/davidcharbonnier/alacarte/commit/65a295800ab866e2496541f3b5211a3653644985))
* **client:** add name as first-class field on dynamic item model ([ac06778](https://github.com/davidcharbonnier/alacarte/commit/ac06778408af42970ec28a2c3b45ffe788c52d6b))
* **client:** remove duplicate name field and add half-star rating display ([8ec5618](https://github.com/davidcharbonnier/alacarte/commit/8ec5618ad7c000f2588b405a5ae984b88c77cd46))


### Features

* **admin/client:** add badge field support to schema display ([939d2c4](https://github.com/davidcharbonnier/alacarte/commit/939d2c4d1d2dbde32b0ccae4297acdb043967eb2))
* **admin:** add schema management ui and api client ([fe41ed5](https://github.com/davidcharbonnier/alacarte/commit/fe41ed5254c9f846ee8dc729cb7067ccd0cbd66b))
* **api:** add generic seed and validate endpoints for dynamic items ([b00e72c](https://github.com/davidcharbonnier/alacarte/commit/b00e72c160b71a5b2a9804d05debb27b35ae9f70))
* **api:** add name as first-class field on item model ([4d3fe78](https://github.com/davidcharbonnier/alacarte/commit/4d3fe78d319efdeb5548597e0f0134388a30f683))
* **api:** add self-healing migration with cloud run job support ([70a5aed](https://github.com/davidcharbonnier/alacarte/commit/70a5aed8ffb8721563fb4a9e2991adbdbbf28a87))
* **api:** implement dynamic schema system foundation ([f1e6578](https://github.com/davidcharbonnier/alacarte/commit/f1e65789085e340648730b477835d0565f434db5))
* **api:** migrate rating from polymorphic to foreign key with cascade ([81c4c98](https://github.com/davidcharbonnier/alacarte/commit/81c4c983adc092816de891a6413474695af5623c))


### BREAKING CHANGES

* **api:** items table now requires name column

## [1.3.1](https://github.com/davidcharbonnier/alacarte/compare/api-v1.3.0...api-v1.3.1) (2026-02-15)


### Bug Fixes

* **ci:** update triggers for release then publish ([1f14cc7](https://github.com/davidcharbonnier/alacarte/commit/1f14cc76b076634cd44fb45c85807e35897ec775))

# [1.3.0](https://github.com/davidcharbonnier/alacarte/compare/api-v1.2.0...api-v1.3.0) (2026-02-15)


### Bug Fixes

* **admin:** make test pass ([dc02e2d](https://github.com/davidcharbonnier/alacarte/commit/dc02e2dca3c4f4d911fec7835bfe55a4576f68fe))
* **admin:** syncing package-lock.json and fix npm ci command in ([0a005f1](https://github.com/davidcharbonnier/alacarte/commit/0a005f1c618230409bc3bd9ff94ce33fac69b706))
* **admin:** update release rules to filter by app ([caa0d17](https://github.com/davidcharbonnier/alacarte/commit/caa0d17006b1fbe8709e601f06bd0e361c8ff747))
* **api:** make test pass ([ab843f0](https://github.com/davidcharbonnier/alacarte/commit/ab843f07c81b58f001b982bc80519d30d8b67462))
* **api:** update release rules to filter by app ([0b1498c](https://github.com/davidcharbonnier/alacarte/commit/0b1498c4e8ab869b78b0b7a7182d8955d6c4bb0c))
* **ci:** comment out PR with build artifacts only when all 3 builds ([f935d86](https://github.com/davidcharbonnier/alacarte/commit/f935d86c41da297bcba00f302cbef5f57a853f31))
* **ci:** filter changelog generation by app and remove npm cache when ([2dc5dcb](https://github.com/davidcharbonnier/alacarte/commit/2dc5dcb9baec8a9d951b96362846e60cc036a0c2))
* **ci:** fixing concurrency issues on version workflow ([43ca2bb](https://github.com/davidcharbonnier/alacarte/commit/43ca2bb12e150f6e566c5ebe53f6c770b163734b))
* **ci:** make test pass ([4631ea3](https://github.com/davidcharbonnier/alacarte/commit/4631ea3e6bbc57f2722c8c7bd6f585c59eb6b2ef))
* **ci:** make test pass ([f85e9dc](https://github.com/davidcharbonnier/alacarte/commit/f85e9dce798a92405b3c1247b6dad1202631407f))
* **ci:** renamed docker images with correct name ([5801bc1](https://github.com/davidcharbonnier/alacarte/commit/5801bc11910d7addf376c31df178b9a916152b27))
* **ci:** update change detection ([b200d20](https://github.com/davidcharbonnier/alacarte/commit/b200d2071132bea33b4a8a536d1084741b68a741))
* **ci:** update npm ci commands for version workflow ([ada7ce0](https://github.com/davidcharbonnier/alacarte/commit/ada7ce03a5219d9baa55da974ae23adf787e48d2))
* **client:** make test pass ([3530ec7](https://github.com/davidcharbonnier/alacarte/commit/3530ec78165e60fd229a7272f35e61ac86d9a9d6))
* **client:** update release rules to filter by app ([6080ba3](https://github.com/davidcharbonnier/alacarte/commit/6080ba3698e6ef38d27f0159fc289762724cd922))


### Features

* **admin:** set correct package version and cleanup changelog ([2a471d6](https://github.com/davidcharbonnier/alacarte/commit/2a471d662c94e3a4daf66f745cf4c3bdb806bfc5))
* **api:** set correct package version and cleanup changelog ([45c71d2](https://github.com/davidcharbonnier/alacarte/commit/45c71d27246891a963d998e75764122ef3176fb4))
* **ci:** refactor ci ([5a6f34d](https://github.com/davidcharbonnier/alacarte/commit/5a6f34dfae463d2707f132f2e5ad9223fc9c6d83))
* **ci:** remove cleanup snapshot workflow ([2955add](https://github.com/davidcharbonnier/alacarte/commit/2955add7ef6df894a6ec3f0ae1f569ff8aa946a9))
* **client:** set correct package version and cleanup changelog ([5ff1947](https://github.com/davidcharbonnier/alacarte/commit/5ff19479296c6c934c4c71e08fa7dd7bb0bca914))

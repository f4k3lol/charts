# Changelog

## [2.0.0](https://github.com/f4k3lol/charts/compare/tpl-1.2.0...tpl-v2.0.0) (2026-05-17)


### ⚠ BREAKING CHANGES

* every resource is renamed on upgrade. Plan as a redeploy: helm uninstall + helm install (or delete the old release's resources and reinstall), since helm cannot rename in place. Selectors are unaffected (they rely on labels).

### Features

* resource names equal the values map key ([950d6ae](https://github.com/f4k3lol/charts/commit/950d6aeba4d9fdd4d2d78cdfe7e5186533e5b7a8))

## [1.2.0](https://github.com/f4k3lol/charts/compare/tpl-1.1.0...tpl-v1.2.0) (2026-05-17)


### Features

* tpl-evaluate stringData/data in secret and configMap ([3d534ae](https://github.com/f4k3lol/charts/commit/3d534ae19d566b862a7e0e47d2925e842905b8ee))

## [1.1.0](https://github.com/f4k3lol/charts/compare/tpl-1.0.0...tpl-v1.1.0) (2026-05-17)


### Features

* allow opaque top-level helmfile key in values schema ([75f604f](https://github.com/f4k3lol/charts/commit/75f604fc94ac23dcc28d4024a528ce63ebfaa004))

## [1.0.0](https://github.com/f4k3lol/charts/compare/tpl-v0.0.1...tpl-v1.0.0) (2026-05-12)


### Features

* tpl chart v1.0.0 ([fa90b6d](https://github.com/f4k3lol/charts/commit/fa90b6d5c83e95ca3a4936695871eb610bb73289))

## 1.0.1

### Changed

- Switched `README.md` to English (Chinese version preserved as `README_CN.md`).
- Rewrote `CHANGELOG.md` in English.
- Changed `pubspec.yaml` `description` to English-only.

### Added

- Added `example/` directory with CLI usage examples and programmatic API demo.
- Added library-level dartdoc to `lib/fluzer.dart`.

### Fixed

- Improved pub.dev score: removed `analyzer` from direct dependencies (was constrained by `codemod_recipe` to `^10.0.1`, blocking the latest version). The two codemod transform files now import `analyzer` as a transitive dependency with `depend_on_referenced_packages` suppressed.

## 1.0.0

Initial release.

### Added

- `fluzer create <name>`: Generate a Flutter Zero project in one step (supports local path, remote zip, and template registry sources).
- `fluzer new <feature>`: Generate a feature module in an existing project with automatic DI registration injection.
- `fluzer version`: Check the latest CLI and template versions with update notifications.
- `fluzer cache list|clean`: View or clear the local template cache.
- Built-in China mirror fallback (ghfast.top / api.gitproxy.dev) for improved domestic access stability.
- Colored log output and clear command help messages.

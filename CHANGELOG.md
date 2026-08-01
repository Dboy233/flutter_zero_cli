## 1.1.0

### Added

- **`fluzer gen-l10n`**: runs `flutter gen-l10n` and auto-generates a type-safe localization access layer.
  - Parses `l10n.yaml` (`arb-dir` / `output-dir` / `output-class`, with fallback probing) and the generated `AppLocalizations` abstract class (brace-counting class-body scanner).
  - Generates `l10n_code.dart`: the `L10nCode` value object with typed factory constructors, symmetric `toString`/`parse` serialization, `==`/`hashCode`, and immutable `Map<String, String>` parameters.
  - Generates `l10n_code_ext.dart`: `typeS()`/`typeE()`/`typeI()`/`typeW()` toast-type markers and a `toToastEffect()` shortcut for emitting effects directly from BLoCs.
  - Generates `l10n_toast_effect_helper.dart`: a centralized switch dispatcher covering every ARB key, deserializing parameters by declared type (`int.tryParse`, `DateTime.tryParse`, ...).
  - Auto-wires `L10nToastEffectHelper` into `defaultToastHandle` via an AST-based patch with three-state detection (template / already-wired / customized), idempotent on repeated runs. Flags: `--skip-handle-patch`, `--force-handle-patch`.
  - Generated sources are formatted with `dart_style` and tagged with the CLI version.

### Fixed

- Placeholder types declared in ARB (e.g. `"type": "int"`) no longer break generation: parameter types are preserved end-to-end instead of being hardcoded as `Object`; unparseable parameter declarations now fail loudly with `FormatException` instead of being silently dropped.
- `L10nCode.parse` tolerates malformed input (e.g. incomplete percent-encoding) instead of throwing inside the effect chain.
- Factory parameters named `code`/`parameters` are renamed (`codeParam`/`parametersParam`) to avoid shadowing class members; map keys remain unchanged.

## 1.0.1

### Changed

- Switched `README.md` to English (Chinese version preserved as `README_CN.md`).
- Rewrote `CHANGELOG.md` in English.
- Changed `pubspec.yaml` `description` to English-only.

### Added

- Added `example/` directory with CLI usage examples and programmatic API demo.
- Added library-level dartdoc to `lib/fluzer.dart`.

### Fixed

- Improved pub.dev score: widened `analyzer` constraint from `^10.2.0` to `>=10.0.1 <15.0.0` so the constraint supports the latest version (the actual resolved version is still capped at 10.x by `codemod_recipe`'s transitive `^10.0.1`).

## 1.0.0

Initial release.

### Added

- `fluzer create <name>`: Generate a Flutter Zero project in one step (supports local path, remote zip, and template registry sources).
- `fluzer new <feature>`: Generate a feature module in an existing project with automatic DI registration injection.
- `fluzer version`: Check the latest CLI and template versions with update notifications.
- `fluzer cache list|clean`: View or clear the local template cache.
- Built-in China mirror fallback (ghfast.top / api.gitproxy.dev) for improved domestic access stability.
- Colored log output and clear command help messages.

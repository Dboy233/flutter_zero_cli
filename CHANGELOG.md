## 1.1.3

### Changed

- `create`, `new` and `gen-l10n` now perform a silent version-update check at startup (via the new `VersionCheckMixin`): a cached hit with an available update shows a one-line hint instantly, otherwise the check runs behind a spinner only when the cache is stale. No update or unreachable network degrades silently without blocking the command.
- The `version` command now wraps its network update check in `runWithSpinner`, giving a live "checking for updates…" progress indication instead of blocking silently.

## 1.1.2

### Added

- Concurrent mirror-racing HTTP client for template downloads: the direct URL now races against configured GitHub mirror prefixes; the first successful response wins and the rest are cancelled, removing the sequential wait for direct-timeout-then-mirror fallback.

### Changed

- Logging overhaul: removed the `LogPolicy` abstraction — visibility is now driven solely by `Logger.level`. Every command step is wrapped in `runWithSpinner` for a live progress indicator; in `--log` mode the spinner is suppressed and child-command output is streamed live instead.
- The download progress bar now appears only in `--log` mode (verbose); in the default mode the step spinner conveys progress, avoiding duplicate/overlapping output.
- Internal refactors with no user-facing behavior change: `TemplateSourceResolver` is now the single public template-source API (top-level helpers removed); the `gen-l10n` parameter-type switch was replaced by an extensible `L10nParamType` registry (OCP); config/version/util packages were restructured to remove cyclic dependencies.

### Fixed

- Fixed a Windows CI crash where the global `Directory.current` was restored to a temporary directory already deleted by a parallel test, failing the `NewCommand` full-flow test. Commands and the CLI entry point now accept an explicit `workingDirectory` instead of mutating global cwd.
- Improved cross-platform test stability on the Linux/macOS/Windows CI matrix: `Platform.resolvedExecutable` replaces the `'dart'` string command, `path.join` replaces hardcoded separators, and temporary-directory deletion now retries under Windows file locking.

## 1.1.1

### Added

- **Version compatibility gate** for `new` and `gen-l10n` commands: the CLI now validates the running CLI version against the project template's required minimum (the `minCliVersion` field in `flutter_zero_config.yaml`) before proceeding. Incompatible versions are rejected with a clear upgrade prompt. A `--skip-version-check` flag bypasses the gate for debugging only.
- `new` command now pins the exact template version declared in the project config (`flutter_zero_config.yaml` `version`) when resolving the download source, instead of always picking the latest CLI-compatible template.
- `ProjectConfig` gains a `minCliVersion` field and an `isCliCompatible(currentCliVersion)` helper. Legacy projects without `minCliVersion` default to `"0.0.0"` (accepted by any CLI).

### Fixed

- `SemanticVersion` lacked value equality (`==` / `hashCode`), causing unreliable version comparisons; value equality is now implemented.

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

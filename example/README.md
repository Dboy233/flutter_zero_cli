# fluzer example

Example usage of the `fluzer` CLI tool for scaffolding Flutter Zero projects.

## Install

```bash
dart pub global activate fluzer
```

## Create a new project

Generate a new Flutter Zero project from the template:

```bash
fluzer create my_app
cd my_app
flutter run
```

## Generate a feature module

Inside a Flutter Zero project, generate a new feature module with
automatic DI registration:

```bash
fluzer new user
```

This creates the full module structure under `lib/features/user/` and
injects the DI registration into `injection_base.dart` automatically.

## Check for updates

```bash
fluzer version
```

## Manage template cache

```bash
# List cached template versions
fluzer cache list

# Clear the local template cache
fluzer cache clean
```

## Verbose output

Pass `--verbose` (or `-v`) for detailed error output with stack traces:

```bash
fluzer create my_app --verbose
```

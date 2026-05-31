# Contributing to audio_output_device_check

Thanks for contributing.

## Requirements

- Flutter SDK managed with `fvm`
- Dart SDK compatible with `pubspec.yaml`

## Setup

```bash
fvm flutter pub get
```

## Development Workflow

1. Create branch from `main`.
2. Make small focused changes.
3. Add/update tests for behavior changes.
4. Run checks locally before opening PR.

## Local Checks

```bash
fvm dart format .
fvm flutter analyze
fvm flutter test
fvm flutter pub publish --dry-run
```

## Pull Request Guidelines

- Keep PR scope narrow.
- Explain problem, approach, and impact.
- Include test evidence.
- Update `README.md` and `CHANGELOG.md` when API/behavior changes.

## Commit Message Convention

Use Conventional Commits when possible:

- `feat:` new feature
- `fix:` bug fix
- `docs:` documentation
- `refactor:` internal change
- `test:` tests
- `chore:` maintenance

## Reporting Bugs

Please include:

- Flutter version (`fvm flutter --version`)
- Platform/device info
- Reproduction steps
- Expected vs actual behavior
- Logs/errors

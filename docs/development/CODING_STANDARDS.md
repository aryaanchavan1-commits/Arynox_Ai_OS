# Arynox OS Coding Standards

## General Principles

1. **Readability over cleverness** — Code is written once, read many times
2. **No commented-out code** — Delete it, git history has the original
3. **No unnecessary comments** — Code should be self-documenting
4. **Consistent naming** — Follow language conventions
5. **Test everything** — Every module must have unit, integration, and E2E tests

## Rust

- Use `cargo fmt` and `cargo clippy` before every commit
- Follow the Rust API Guidelines
- Use `Result<T, Error>` for fallible functions, not panics
- Use `thiserror` for error types, `anyhow` for application-level errors
- Prefer `tracing` over `log` or `println`
- All public items must have doc comments
- Module structure: `mod.rs` re-exports, private impls in sibling files

## Flutter/Dart

- Use `dart format` before every commit
- Use `flutter analyze` — zero warnings
- Follow Effective Dart guidelines
- Use Riverpod for state management
- Use Freezed for immutable data classes
- Use JsonSerializable for JSON serialization
- Widgets should be `const` where possible
- Prefer `ConsumerWidget` over `StatelessWidget` when using providers
- Separate business logic into providers, not in widgets

## Python

- Use `black` formatting, `ruff` linting
- Type hints required on all function signatures
- Use `pydantic` for configuration models
- Use `async/await` for all I/O operations
- Logging via `logging` module, never `print`
- Docstrings on all public functions and classes

## Git

- Conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
- One commit per logical change
- Branch naming: `feat/module-name`, `fix/issue-description`
- PR description must explain what and why

## CI Pipeline

All pushes must pass:
1. `cargo test` (all Rust crates)
2. `cargo clippy -- -D warnings`
3. `flutter test`
4. `flutter analyze`
5. `ruff check ai-python/`
6. `black --check ai-python/`

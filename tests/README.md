# Arynox OS Testing

## Test Structure

```
tests/
├── unit/              # Per-module unit tests
│   ├── wm/            # Window manager tests
│   ├── ai/            # AI runtime tests
│   ├── packages/      # Package manager tests
│   └── ...
├── integration/       # Cross-module integration tests
│   ├── ai/            # AI provider integration
│   └── ...
└── e2e/               # End-to-end system tests
```

## Running Tests

```bash
# Run all Rust tests
cargo test --workspace

# Run specific crate tests
cargo test -p arynox-compositor

# Run Flutter tests
cd src/desktop && flutter test
cd src/settings && flutter test

# Run Python tests
cd ai-python && pytest

# Run integration tests
cargo test --test integration_ai

# Run E2E tests
cd tests/e2e && cargo test
```

## Coverage Requirements

| Module | Line Coverage | Branch Coverage |
|--------|--------------|-----------------|
| Core services (Rust) | ≥85% | ≥75% |
| UI components (Flutter) | ≥70% | ≥60% |
| AI Runtime (Python) | ≥80% | ≥70% |

## Test Categories

### Unit Tests
- Test individual functions and methods
- Mock external dependencies (D-Bus, network, filesystem)
- Fast execution (<100ms per test)

### Integration Tests
- Test module interactions via D-Bus
- Test AI provider connection handling
- Test file system operations
- Test device detection pipeline

### E2E Tests
- Full boot to desktop flow
- Application launch and window management
- AI assistant conversation flow
- Package install/remove/update
- System settings modification
- Device hotplug simulation

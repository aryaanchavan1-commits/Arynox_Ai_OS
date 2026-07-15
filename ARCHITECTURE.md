# Arynox OS Architecture

## Overview

Arynox OS is an AI-native Linux-compatible operating system targeting desktop PCs, laptops, Raspberry Pi, ARM tablets, and future Arynox hardware. It is built with a layered, modular architecture where each component is independently testable and replaceable.

## Design Principles

1. **AI-Native** — AI is a core platform capability, not an application
2. **Beauty & Polish** — Every pixel is intentional; fluid animations, glass effects, rounded UI
3. **Performance** — Boot under 10s, GPU-accelerated compositing, lazy resource loading
4. **Security** — Encrypted storage, sandboxed apps, TPM-backed Secure Boot, encrypted API key storage
5. **Privacy** — All AI processing user-owned; local-first; user controls data flow
6. **Modularity** — Every subsystem is independently replaceable via well-defined D-Bus APIs
7. **Compatibility** — Runs Linux binaries, Wayland-native apps, Flatpak/Snap/AppImage

## System Stack

```
┌─────────────────────────────────────────────────────────┐
│                     User Applications                     │
│  (Flutter, GTK, Qt, Electron, Terminal, Games, etc.)   │
├─────────────────────────────────────────────────────────┤
│            Arynox Desktop Environment (Flutter)           │
│  Shell | Taskbar | Dock | Launcher | Notifications |    │
│  Control Center | Widgets | Workspaces | Gestures       │
├─────────────────────────────────────────────────────────┤
│              Arynox Window Manager (Rust)                 │
│   Wayland Compositor | Tiling | Snap | Virtual Desktops  │
├─────────────────────────────────────────────────────────┤
│           Arynox System Services (Rust/C)                 │
│  Device Manager | Network | Security | Updates | Cloud  │
├─────────────────────────────────────────────────────────┤
│               AI Runtime (Python/Rust)                    │
│  Hub | Assistant | Copilot | Agent | Providers           │
├─────────────────────────────────────────────────────────┤
│           Arynox Core Daemons (Rust)                      │
│  Session Manager | Policy Kit | Portal | Notifications   │
├─────────────────────────────────────────────────────────┤
│               Linux Kernel + systemd                      │
│  BTRFS | Wayland | PipeWire | NetworkManager | BlueZ    │
│  Secure Boot | TPM | GPU Drivers | Device Mapper        │
└─────────────────────────────────────────────────────────┘
```

## Technology Choices

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| Kernel | Linux LTS | Mature, hardware support, driver ecosystem |
| Init | systemd | Industry standard, service management, journald |
| Display Server | Wayland | Modern, secure, GPU-accelerated |
| Sound | PipeWire | Low-latency, professional audio, screen capture |
| Networking | NetworkManager | Universal, VPN, modem support |
| Bluetooth | BlueZ | Standard Linux Bluetooth stack |
| Filesystem | BTRFS | Snapshots, compression, subvolumes, checksums |
| Desktop UI | Flutter | Rich widget library, Material + custom, multi-platform, performant |
| Window Manager | Rust (smithay) | Memory-safe, fast, direct Wayland protocol access |
| Core Services | Rust | Memory safety, zero-cost abstractions, async |
| AI Runtime | Python | Rich ML/AI ecosystem, PyTorch, ONNX, transformers |
| IPC | D-Bus | Standard Linux IPC, peer-to-peer communication |
| Database | SQLite | Embedded, reliable, zero-configuration |
| Package Base | Debian/Ubuntu | Largest software ecosystem for Linux |

## Directory Structure

```
ArynoxOS/
├── ARCHITECTURE.md          # This file
├── README.md                # Project overview
├── docs/                    # All documentation
│   ├── architecture/        # Architecture decision records
│   ├── api/                 # Public API specifications
│   ├── modules/             # Module-specific documentation
│   └── development/         # Developer guides, coding standards
├── src/                     # Source code by module
│   ├── kernel/              # Kernel patches, modules, config
│   ├── boot/                # Bootloader, initramfs, systemd units
│   ├── desktop/             # Flutter desktop shell
│   ├── wm/                  # Wayland compositor (Rust)
│   ├── settings/            # Settings app (Flutter)
│   ├── ai/                  # AI subsystem
│   │   ├── runtime/         # Python AI runtime daemon
│   │   ├── hub/             # Intelligence Hub UI (Flutter)
│   │   ├── assistant/       # AI Assistant (Flutter + Python)
│   │   ├── copilot/         # AI Copilot IPC service
│   │   └── agent/           # AI Agent service
│   ├── files/               # File Manager (Flutter + Rust)
│   ├── devices/             # Device Manager (Rust)
│   ├── packages/            # Package Manager (Rust)
│   ├── software/            # Software Center (Flutter)
│   ├── network/             # Network Manager UI (Flutter)
│   ├── security/            # Security framework (Rust)
│   ├── cloud/               # Cloud sync services (Rust)
│   ├── devtools/            # Developer tools (mixed)
│   ├── updates/             # OTA update system (Rust)
│   ├── installer/           # System installer (Flutter)
│   └── recovery/            # Recovery environment
├── core/                    # Core Rust libraries and daemons
├── ai-python/               # Python AI runtime package
├── shell/                   # System shell scripts
├── flutter/                 # Shared Flutter widgets, themes, design system
├── tests/                   # All tests
│   ├── unit/                # Unit tests per module
│   ├── integration/         # Integration tests
│   └── e2e/                 # End-to-end system tests
├── ci/                      # CI/CD configuration
├── config/                  # Default system configuration files
├── resources/               # Static assets
│   ├── icons/               # System icons
│   ├── themes/              # Theme definitions
│   ├── wallpapers/          # Default wallpapers
│   ├── fonts/               # System fonts
│   └── sounds/              # System sounds
└── scripts/                 # Build, dev, and utility scripts
```

## IPC Architecture

All inter-process communication uses **D-Bus** with well-defined XML introspection interfaces.

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  Flutter UI  │────▶│  Core Daemon │────▶│  System Bus  │
│  (desktop)   │     │  (Rust)      │     │              │
└─────────────┘     └──────────────┘     └──────┬───────┘
                                                 │
                    ┌────────────────────────────┼────────────────────┐
                    │                            │                    │
            ┌───────▼──────┐           ┌────────▼───────┐  ┌────────▼───────┐
            │ AI Runtime   │           │ Device Manager │  │ Network Mgr UI │
            │ (Python)     │           │ (Rust)         │  │ (Flutter)      │
            └──────────────┘           └────────────────┘  └────────────────┘
```

## Data Flow: AI Request

```
User Input (text/voice/image)
        │
        ▼
  Flutter UI (Assistant/Copilot)
        │
        ▼
  D-Bus → AI Runtime Daemon (Python)
        │
        ├──→ Provider Adapter (Groq/OpenAI/Ollama/...)
        │       │
        │       ▼
        │   External API / Local Model
        │       │
        │       ▼
        ├──→ Response Processor
        │       │
        │       ▼
        ├──→ Memory Store (SQLite)
        │
        ▼
  D-Bus → Flutter UI
```

## Data Flow: Device Hotplug

```
Kernel udev event
        │
        ▼
  Device Manager (Rust) detects hardware
        │
        ├──→ Identifies device (USB vendor/class/etc.)
        ├──→ Loads driver if needed (kmod)
        ├──→ Updates D-Bus device tree
        │
        ▼
  Flutter UI receives D-Bus signal
        │
        ▼
  Notification shown | Device appears in manager
```

## Data Flow: File Search with AI

```
User types query in File Manager search bar
        │
        ▼
  File Manager (Flutter) sends query to AI Runtime
        │
        ▼
  AI Runtime interprets natural language → structured query
        │
        ▼
  File Manager executes search (indexed DB + filesystem)
        │
        ▼
  Results displayed with AI relevance ranking
```

## Security Architecture

```
┌──────────────────────────────────────────┐
│            User Session                   │
│  ┌──────────┐  ┌──────────┐              │
│  │ App A    │  │ App B    │  ...          │
│  │ sandbox  │  │ sandbox  │              │
│  └────┬─────┘  └────┬─────┘              │
│       │              │                    │
│  ┌────▼──────────────▼─────┐              │
│  │   Arynox Policy Engine  │              │
│  │  (Permissions, caps)    │              │
│  └────────────┬────────────┘              │
│               │                           │
├───────────────┼───────────────────────────┤
│               ▼                           │
│  ┌──────────────────────────┐             │
│  │  System Security Daemon  │             │
│  │  Secure Boot | TPM | LSM │            │
│  └──────────────────────────┘             │
└───────────────────────────────────────────┘
```

## Build System

- **Cargo** for Rust components (workspace with member crates)
- **Flutter/Dart** for UI components
- **Meson** for C/C++ components
- **Poetry** for Python AI runtime
- **GitHub Actions** for CI/CD
- Cross-compilation targets: x86_64, aarch64

## Module Dependency Graph

```
Boot → Desktop Environment → Window Manager
                                      │
                    ┌─────────────────┼─────────────────┐
                    ▼                 ▼                  ▼
             Settings App     File Manager        Device Manager
                    │                 │                  │
                    ▼                 ▼                  ▼
            Intelligence Hub    Network Manager     Security Framework
                    │                 │                  │
                    ▼                 ▼                  ▼
              AI Runtime ─────▶  AI Assistant ◀─── Cloud Services
                    │                 │
                    ▼                 ▼
              AI Copilot          AI Agent
                    │
                    ▼
            Package Manager → Software Center
                    │
                    ▼
            Developer Tools → OTA Updates → Installer → Recovery
```

## Versioning

- Semantic Versioning (MAJOR.MINOR.PATCH)
- Pre-release tags: alpha, beta, rc
- Cadence: Major every 12 months, Minor every 3 months, Patches as needed

## Development Workflow

1. Each module has an `ARCH.md` in `docs/modules/<module>/`
2. Each module has `src/<module>/` with its own `Cargo.toml` or `pubspec.yaml`
3. Tests live in `tests/<type>/<module>/`
4. CI enforces: `cargo test`, `flutter test`, `cargo clippy`, `dart analyze`
5. All changes must pass review with architecture alignment check

---

*This document is the authoritative source for Arynox OS architecture. All module design must conform to these principles.*

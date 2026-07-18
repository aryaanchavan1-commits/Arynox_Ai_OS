# Arynox OS Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Arynox OS 0.1.0                       │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────┐   │
│  │  User Space (Wayland/Weston)                    │   │
│  │  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐  │   │
│  │  │Desktop│ │Files │ │Network│ │Settings│ │ AI  │  │   │
│  │  │ Shell │ │Manager│ │Manager│ │  App  │ │ Hub │  │   │
│  │  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘  │   │
│  │  11 Flutter Apps (Linux desktop)                 │   │
│  └─────────────────────────────────────────────────┘   │
│                           │                              │
│  ┌─────────────────────────────────────────────────┐   │
│  │  System Daemons (Rust)                          │   │
│  │  ┌────────┐ ┌────────┐ ┌────────┐ ┌──────────┐  │   │
│  │  │ Session│ │  WM    │ │ Security│ │   AI     │  │   │
│  │  │ Manager│ │Daemon  │ │ Daemon │ │  Runtime │  │   │
│  │  └────────┘ └────────┘ └────────┘ └──────────┘  │   │
│  │  15 Rust daemons with D-Bus IPC                  │   │
│  └─────────────────────────────────────────────────┘   │
│                           │                              │
│  ┌─────────────────────────────────────────────────┐   │
│  │  systemd (PID 1)                                │   │
│  │  ┌──────────┐ ┌──────────┐ ┌────────────────┐  │   │
│  │  │NetworkMgr│ │   SSH    │ │  pipewire      │  │   │
│  │  │  ModemMgr│ │  chrony  │ │  wireplumber   │  │   │
│  │  └──────────┘ └──────────┘ └────────────────┘  │   │
│  └─────────────────────────────────────────────────┘   │
│                           │                              │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Linux Kernel 7.0.0-14-generic (Ubuntu)         │   │
│  │  ext4, virtio, drm, squashfs, network drivers   │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## Rust Daemons (15)

All daemons use D-Bus for IPC via `zbus` crate and `tokio` async runtime.

### Core Daemons

| # | Crate | Path | Service | Purpose |
|---|-------|------|---------|---------|
| 1 | `arynox-session` | `core/arynox-session/` | `arynox-session.service` | Session lifecycle manager. Handles user login sessions, environment setup, seat management. |
| 2 | `arynox-boot-check` | `core/arynox-boot-check/` | `arynox-boot-complete.service` | Boot health monitor. Validates filesystems, checks hardware, signals boot completion. |
| 3 | `arynox-tpm` | `core/arynox-tpm/` | — | TPM-based LUKS disk unlock daemon. Provides measured boot attestation. |

### System Service Daemons

| # | Crate | Path | Service | Purpose |
|---|-------|------|---------|---------|
| 4 | `wm` | `src/wm/` | — | Window manager daemon. Manages Wayland compositor state, window rules, multi-monitor. |
| 5 | `files` | `src/files/` | — | File system daemon. Monitors mounts, provides file search, manages trash/backup. |
| 6 | `devices` | `src/devices/` | — | Device manager daemon. Hotplug handling, device profiles, power management. |
| 7 | `packages` | `src/packages/` | — | Package management daemon. APT wrapper, Flatpak integration, update scheduling. |
| 8 | `network` | `src/network/` | — | Network daemon. VPN management, firewall rules, connection profiles. |
| 9 | `security` | `src/security/` | — | Security daemon. AppArmor profiles, audit logging, threat detection. |
| 10 | `cloud` | `src/cloud/` | — | Cloud sync daemon. Backup to remote storage, file sync, restore. |
| 11 | `updates` | `src/updates/` | — | System update daemon. OS updates, firmware updates, reboot scheduling. |
| 12 | `installer` | `src/installer/` | — | OS installer daemon. Disk partitioning, system deployment, recovery. |
| 13 | `recovery` | `src/recovery/` | — | Recovery daemon. System restore, snapshot management, factory reset. |
| 14 | `devtools` | `src/devtools/` | — | Developer tools daemon. Log viewer, performance monitor, debugger interface. |

### AI Daemon

| # | Crate | Path | Service | Purpose |
|---|-------|------|---------|---------|
| 15 | `ai-runtime` | `src/ai/runtime/` | `arynox-ai-runtime.service` | AI runtime orchestrator. Manages Ollama, model lifecycle, inference scheduling. |

### D-Bus IPC Architecture

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│ Flutter App │────▶│ D-Bus System │◀────│  Rust Daemon │
│ (GUI)       │     │    Bus       │     │  (Backend)   │
└─────────────┘     └──────────────┘     └──────────────┘
                           │
                    ┌──────┴──────┐
                    │ AI Runtime  │
                    │  (Python)   │
                    └─────────────┘
```

## Flutter Apps (11)

### Desktop Apps

| # | App | Path | Purpose |
|---|-----|------|---------|
| 1 | **Desktop Shell** | `src/desktop/` | Main GUI shell — dock, launcher, control center, notifications |
| 2 | **File Manager** | `src/files/` | File browser, search, trash, network mounts |
| 3 | **Network Manager** | `src/network/` | WiFi, Ethernet, VPN configuration |
| 4 | **Settings** | `src/settings/` | System settings — display, sound, accounts, privacy |
| 5 | **Software Center** | `src/software/` | App browser, install/uninstall, updates |
| 6 | **Devices** | `src/devices/` | Hardware manager — Bluetooth, printers, input devices |
| 7 | **Installer** | `src/installer/` | OS installation wizard, disk setup, user creation |

### Dev Tools

| # | App | Path | Purpose |
|---|-----|------|---------|
| 8 | **DevTools** | `src/devtools/` | Developer dashboard — logs, performance, terminal |

### AI Apps

| # | App | Path | Purpose |
|---|-----|------|---------|
| 9 | **AI Hub** | `src/ai/hub/` | AI model manager — download, configure, run models |
| 10 | **AI Assistant** | `src/ai/assistant/` | Conversational AI assistant with vision |
| 11 | **AI Copilot** | `src/ai/copilot/` | Coding copilot — code generation, review, debugging |

## AI Runtime

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  AI Agent    │────▶│   Ollama     │◀────│  AI Models   │
│  (Port 8080) │     │  (Port 11434)│     │  Qwen2.5 3B  │
│  REST API    │     │              │     │  Moondream2  │
│              │     │              │     │  SmolVLM     │
└──────────────┘     └──────────────┘     └──────────────┘
       │
       ├── /chat     → Reasoning (Qwen2.5 3B)
       ├── /analyze  → Vision (Moondream2)
       ├── /detect   → Detection (SmolVLM)
       └── /browse   → Web + Summary

First-boot download: arynox-ai-download.service
  → Downloads Ollama + models (~8-10 GB total)
  → Runs once, marks /var/lib/arynox-ai/download-complete
```

## Boot Process

```
BIOS/UEFI
   │
   ▼
GRUB (serial console, timeout 3s)
   │
   ▼
Linux Kernel 7.0.0-14-generic
  root=/dev/vda1 console=ttyS0 apparmor=0
   │
   ▼
systemd (PID 1)
   │
   ├── sysinit.target — mount fs, udev, modules
   ├── basic.target   — dbus, systemd-logind
   ├── NetworkManager — network connectivity
   ├── multi-user.target
   │   ├── SSH server
   │   ├── arynox-boot-complete.service
   │   ├── arynox-ai-download.service (first boot only)
   │   └── getty@tty1 (auto-login: arynox)
   │
   └── graphical.target
       └── Weston Wayland Compositor (tty1)
           └── Desktop Shell + App Launcher
```

## Build Process

```
build.sh  (one-command build)
   │
   ├── cargo build --release
   │   └── 15 Rust daemons → target/release/
   │
   ├── flutter build linux --release (×11)
   │   └── Flutter apps → build/flutter-apps/
   │
   ├── scripts/build-full-os.sh
   │   ├── debootstrap → root filesystem
   │   ├── apt-get install → packages
   │   ├── Copy Rust daemons + Flutter apps
   │   ├── Install AI runtime (Python)
   │   └── mksquashfs → filesystem.squashfs
   │
   └── scripts/build-usb-image.sh
       ├── Partition + format ext4
       ├── unsquashfs rootfs
       ├── Install kernel
       ├── grub-install + update-grub
       └── Bootable USB image (6 GB)
```

## Directory Layout

```
/
├── boot/
│   ├── vmlinuz-7.0.0-14-generic
│   └── grub/grub.cfg
├── etc/
│   ├── systemd/system/
│   │   ├── weston.service
│   │   ├── ollama.service
│   │   ├── arynox-ai-download.service
│   │   ├── arynox-ai-runtime.service
│   │   ├── arynox-boot-complete.service
│   │   ├── arynox-compositor.service
│   │   └── arynox-session.service
│   └── default/grub
├── usr/
│   ├── lib/arynox/          — Rust daemon binaries
│   ├── share/arynox/        — Flutter app bundles
│   ├── local/bin/
│   │   ├── arynox-ai-agent  — AI REST API server
│   │   └── launch-arynox-app
│   └── local/lib/arynox-ai/ — Model download scripts
├── home/arynox/
│   └── .config/weston.ini   — Weston desktop config
└── var/lib/arynox-ai/
    └── download-complete    — AI download marker
```

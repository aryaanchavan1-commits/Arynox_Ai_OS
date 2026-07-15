# Arynox OS

**AI-Native Operating System**

Created by **Aryan Chavan**
Arynox Technologies (C) 2026

## Overview

Arynox OS is a next-generation operating system designed for the AI era. It features:

- **14 system daemons** written in Rust (session management, compositor, files, devices, packages, security, cloud, network, updates, recovery, installer, dev tools, boot check, TPM)
- **Multi-provider AI runtime** supporting Groq, OpenAI, Anthropic, Gemini, and Ollama
- **D-Bus service architecture** for inter-process communication
- **UEFI + BIOS boot** via GRUB
- **Initramfs-based recovery environment**

## Building

```bash
cargo build --release
bash scripts/build-all.sh
```

ISO output: `release/arynox-os-0.1.0-amd64.iso`

## Testing

```bash
qemu-system-x86_64 -cdrom release/arynox-os-0.1.0-amd64.iso -m 2G -nographic
```

## Architecture

See ARCHITECTURE.md for the full system design.

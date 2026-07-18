# Arynox AI OS

**AI-Native Operating System** — A complete Linux desktop OS with integrated AI runtime, 14 Rust system daemons, 11 Flutter applications, and automated AI model deployment.

Created by **Aryan Chavan** — a full desktop OS from debootstrap rootfs to bootable USB.

## Features

### System
- **Boot**: BIOS/GRUB or QEMU direct-kernel boot
- **Display**: Weston Wayland compositor + XWayland (Firefox, desktop apps)
- **Services**: systemd (PID 1), udev, dbus, NetworkManager, SSH, pipewire
- **Kernel**: Ubuntu 7.0.0-14-generic (all drivers built-in, serial console)
- **Root**: ext4 partition, ~3 GB base + ~8-10 GB AI models

### AI Runtime (auto-downloads on first boot)
| Model | Purpose | Size |
|-------|---------|------|
| Ollama + Qwen2.5 (3B) | Reasoning, coding, chat | ~2.5 GB |
| Moondream2 | Vision, face/object detection | ~3 GB |
| SmolVLM 500M | Vision-language, OCR, scene understanding | ~1 GB |

### Applications
- **14 Rust daemons** — System services (connection, monitoring, AI orchestration)
- **11 Flutter apps** — Desktop GUI apps (AI Hub, Assistant, Copilot, Settings, etc.)
- **Python AI agent** — REST API on port 8080, auto-model download

## Quick Start

### Prerequisites
- WSL2 with Ubuntu 26.04 (resolute)
- 20 GB free disk space
- Rust 1.97+, Flutter 3.44+, Python 3.12+

### Build

```bash
# 1. Clone the repo
git clone https://github.com/aryaanchavan1-commits/Arynox_Ai_OS.git
cd Arynox_Ai_OS

# 2. Build everything (requires root for debootstrap)
sudo bash build.sh
```

This produces `build/arynox-usb.img` (6 GB, bootable).

### Boot with QEMU

```bash
# Headless (serial console)
qemu-system-x86_64 -m 4G -nographic \
  -drive file=build/arynox-usb.img,format=raw,if=virtio

# With GUI (VNC)
qemu-system-x86_64 -m 4G -vga virtio -vnc :0 \
  -drive file=build/arynox-usb.img,format=raw,if=virtio
# Connect VNC client to localhost:5900

# Direct kernel boot (faster, no GRUB needed)
qemu-system-x86_64 -m 4G -nographic \
  -kernel build/vmlinuz-7.0.0-14-generic \
  -drive file=build/root.img,format=raw,if=virtio \
  -append 'console=ttyS0,115200n8 root=/dev/vda rw nokaslr apparmor=0'
```

### Boot from USB

```bash
# Write to physical USB drive (replace /dev/sdX)
sudo dd if=build/arynox-usb.img of=/dev/sdX bs=4M status=progress
```

### Credentials
- **Username**: `arynox`
- **Password**: `arynox`
- **Root/Sudo**: Passwordless sudo for user `arynox`

## Architecture

```
src/
  boot/           systemd units, D-Bus configs
  desktop/        Flutter desktop shell apps
  ai/             Flutter AI apps (hub, assistant, copilot)
ai-python/        Python AI runtime + model downloader
scripts/
  build-full-os.sh     Build rootfs + squashfs
  build-usb-image.sh   Create bootable USB image
  build-initramfs.sh   (legacy) CD-ROM initramfs
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Boot hangs at `apparmor.service` | Kernel includes `apparmor=0` |
| Weston fails (no GPU) | Use `-vga virtio -vnc :0` for GPU emulation |
| Network not working in QEMU | Add `-netdev user,id=net0 -device virtio-net,netdev=net0` |
| AI models not downloading | Boot with network, run `sudo systemctl start arynox-ai-download` |

## License

MIT License — see [LICENSE](LICENSE)

Copyright (c) 2026 Aryan Chavan

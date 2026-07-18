#!/bin/bash
set -euo pipefail
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"

echo "=========================================="
echo "  Arynox OS Release Build v0.1.0"
echo "  Created by Aryan Chavan"
echo "=========================================="
echo ""

BOOT_USAGE=$(cat << 'EOF'
=== HOW TO BOOT ARYNOX OS ===

Option 1: QEMU with kernel + disk (RECOMMENDED)
  qemu-system-x86_64 \
    -m 4G \
    -vga virtio -vnc :0 \
    -kernel build/vmlinuz-arynox \
    -drive file=build/root.img,format=raw,if=virtio \
    -append 'console=ttyS0,115200n8 nokaslr root=/dev/vda rw'

Option 2: Direct disk boot (if GRUB installed on image)
  qemu-system-x86_64 \
    -m 4G \
    -vga virtio -vnc :0 \
    -drive file=build/arynox-usb.img,format=raw,if=virtio

Option 3: Write to USB drive
  dd if=build/arynox-usb.img of=/dev/sdX bs=4M status=progress

CREDENTIALS:
  Username: arynox
  Password: arynox
  Root/Sudo: passwordless sudo for user arynox

SERVICES:
  - SSH: ssh arynox@localhost -p 22
  - Network: auto-configured via NetworkManager
  - Weston (Wayland): auto-starts on graphical boot
  - AI Agent: systemd service (auto-downloads models on first boot)

AI MODELS (first boot download):
  - Ollama + Llama 3.2 (3B): general AI/reasoning/coding
  - Moondream2: vision/face/object detection
  - SmolVLM 500M: vision-language tasks
  - Total: ~8-10GB (automatic download on network connect)
EOF
)

echo "$BOOT_USAGE"
echo ""
echo "Build artifacts:"
ls -lh "$PROJECT/build/root.img" 2>/dev/null || echo "  root.img: not built (run build-full-os.sh first)"
ls -lh "$PROJECT/build/filesystem.squashfs" 2>/dev/null || echo "  squashfs: not built"
ls -lh "$PROJECT/build/vmlinuz-*" 2>/dev/null || echo "  kernel: not built"
echo ""
echo "Release files:"
ls -lh "$PROJECT/release/" 2>/dev/null || echo "  (none)"

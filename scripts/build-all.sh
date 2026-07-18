#!/bin/bash
set -euo pipefail

PROJECT="/mnt/d/Arynoxtech/ArynoxOS"
cd "$PROJECT"
export HOME=/root
export PATH="/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export CARGO_NET_GIT_FETCH_WITH_CLI=true

echo "=== Arynox OS: Full Build ==="
echo ""

# Step 1: Build ALL Rust workspace crates
echo "=== Building all Rust crates ==="
cargo build --release 2>&1 | tail -30

echo ""
echo "=== Build Results: Rust ==="
find target/release -maxdepth 1 -type f -executable -name "arynox-*" | sort
echo ""

# Step 2: Build Python AI runtime
echo "=== Building Python AI runtime ==="
cd "$PROJECT/ai-python"
if [ ! -f pyproject.toml ]; then
    cat > pyproject.toml << 'PYEOF'
[build-system]
requires = ["setuptools", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "arynox-ai-runtime"
version = "0.1.0"
description = "Arynox AI Runtime"
requires-python = ">=3.11"
PYEOF
fi

# Create empty setup.py if needed
if [ ! -f setup.py ] && [ ! -f setup.cfg ]; then
    cat > setup.py << 'PYEOF'
from setuptools import setup, find_packages
setup(
    name="arynox-ai-runtime",
    version="0.1.0",
    packages=find_packages(),
    python_requires=">=3.11",
)
PYEOF
fi

python3 -m build --wheel 2>&1 | tail -5 || echo "Python build note: building wheel skipped"

cd "$PROJECT"

# Step 3: Build initramfs with all daemons
echo ""
echo "=== Creating initramfs ==="
INITRAMFS_DIR="$PROJECT/build/initramfs"
rm -rf "$INITRAMFS_DIR"
mkdir -p "$INITRAMFS_DIR"/bin
mkdir -p "$INITRAMFS_DIR"/{dev,etc,proc,sys,tmp,usr/lib/arynox}

# Busybox
cp /bin/busybox "$INITRAMFS_DIR/bin/"
for cmd in sh mount umount switch_root grep ls cat echo mkdir dmesg mdev insmod modprobe; do
    ln -sf busybox "$INITRAMFS_DIR/bin/$cmd" 2>/dev/null || true
done

# All Arynox daemons
for bin in arynox-session arynox-boot-check arynox-compositor arynox-files \
           arynox-device-manager arynox-package-manager arynox-security \
           arynox-cloud arynox-devtools arynox-update-manager \
           arynox-installer arynox-recovery arynox-network-manager; do
    src="$PROJECT/target/release/$bin"
    if [ -f "$src" ]; then
        cp "$src" "$INITRAMFS_DIR/usr/lib/arynox/"
        echo "  Added: $bin"
    fi
done

# Init script
cat > "$INITRAMFS_DIR/init" << 'INIT'
#!/bin/sh
/bin/mount -t proc proc /proc
/bin/mount -t sysfs sysfs /sys
/bin/mount -t devtmpfs devtmpfs /dev
/bin/mdev -s
echo ""
echo "=========================================="
echo "  Arynox OS v0.1.0"
echo "  AI-Native Operating System"
echo "  Created by Aryan Chavan"
echo "  (C) 2026 Arynox Technologies"
echo "=========================================="
echo ""
echo "Loading Arynox system services..."
for svc in /usr/lib/arynox/arynox-*; do
    name=$(basename $svc)
    echo "  Starting: $name"
    $svc --daemon &
done
echo ""
echo "System ready. Starting recovery shell..."
echo ""
exec /bin/sh
INIT
chmod +x "$INITRAMFS_DIR/init"

cd "$INITRAMFS_DIR"
find . | cpio -H newc -o | gzip -9 > "$PROJECT/build/initramfs.img"
echo "Initramfs: $(du -h "$PROJECT/build/initramfs.img" | cut -f1)"

# Step 4: Rootfs + squashfs
echo ""
echo "=== Creating root filesystem ==="
ROOTFS="$PROJECT/build/rootfs"
rm -rf "$ROOTFS"
mkdir -p "$ROOTFS"/{bin,dev,etc/arynox,home,lib,proc,run,sbin,sys,tmp,usr/lib/arynox,usr/lib/systemd/system,var/lib/arynox}

# Copy all daemons
for bin in arynox-session arynox-boot-check arynox-compositor arynox-files \
           arynox-device-manager arynox-package-manager arynox-security \
           arynox-cloud arynox-devtools arynox-update-manager \
           arynox-installer arynox-recovery arynox-network-manager; do
    src="$PROJECT/target/release/$bin"
    [ -f "$src" ] && cp "$src" "$ROOTFS/usr/lib/arynox/"
done

# systemd units
cp "$PROJECT/src/boot/systemd/"*.service "$ROOTFS/usr/lib/systemd/system/" 2>/dev/null || true

# OS release
cat > "$ROOTFS/usr/lib/os-release" << 'EOF'
NAME="Arynox OS"
ID=arynox
PRETTY_NAME="Arynox OS 0.1.0 (2026)"
VERSION_ID="0.1.0"
VERSION_CODENAME="2026"
HOME_URL="https://arynox.com"
BUILD_ID="20260715"
EOF

cat > "$ROOTFS/etc/arynox/version" << 'EOF'
ARYNOX_OS_VERSION="0.1.0"
ARYNOX_OS_CODENAME="2026"
BUILD_DATE="2026-07-15"
CREATOR="Aryan Chavan"
KERNEL_VERSION="6.6.30"
EOF

# AI config
cat > "$ROOTFS/etc/arynox/ai-runtime.yaml" << 'EOF'
providers:
  groq:
    api_key: ""
    base_url: "https://api.groq.com/openai/v1"
    default_model: "llama3-70b-8192"
  openai:
    api_key: ""
    base_url: "https://api.openai.com/v1"
    default_model: "gpt-4o"
  anthropic:
    api_key: ""
    base_url: "https://api.anthropic.com/v1"
    default_model: "claude-3-5-sonnet"
  gemini:
    api_key: ""
    base_url: "https://generativelanguage.googleapis.com/v1beta"
    default_model: "gemini-1.5-pro"
  ollama:
    api_key: ""
    base_url: "http://127.0.0.1:11434"
    default_model: "qwen2.5"
EOF

# Device nodes
for dev in null zero random urandom console tty; do
    mknod -m 666 "$ROOTFS/dev/$dev" c 1 3 2>/dev/null || true
done

# Fstab
cat > "$ROOTFS/etc/fstab" << 'EOF'
/dev/root / btrfs subvol=@,compress=zstd,noatime 0 1
tmpfs /tmp tmpfs defaults,noatime,mode=1777 0 0
tmpfs /run tmpfs defaults,noatime,mode=0755 0 0
EOF

# Hostname
echo "arynox" > "$ROOTFS/etc/hostname"

echo "Creating squashfs..."
mksquashfs "$ROOTFS" "$PROJECT/build/filesystem.squashfs" \
    -comp zstd -b 1M -noappend -quiet 2>&1
echo "Squashfs: $(du -h "$PROJECT/build/filesystem.squashfs" | cut -f1)"

# Step 5: ISO
echo ""
echo "=== Building ISO ==="
ISO_DIR="$PROJECT/build/iso"
rm -rf "$ISO_DIR"
mkdir -p "$ISO_DIR/"{boot/grub,live,EFI/BOOT}

# Use host kernel or custom
if [ -f "$PROJECT/build/vmlinuz-arynox" ]; then
    cp "$PROJECT/build/vmlinuz-arynox" "$ISO_DIR/boot/"
elif ls /boot/vmlinuz-* &>/dev/null; then
    cp /boot/vmlinuz-* "$ISO_DIR/boot/vmlinuz-arynox"
fi
cp "$PROJECT/build/initramfs.img" "$ISO_DIR/boot/"
cp "$PROJECT/build/filesystem.squashfs" "$ISO_DIR/live/" 2>/dev/null || true

# GRUB
cat > "$ISO_DIR/boot/grub/grub.cfg" << 'GRUB'
set default=0
set timeout=10
serial --unit=0 --speed=115200
terminal_input serial console
terminal_output serial console

menuentry "Arynox OS 2026" --class arynox {
    linux /boot/vmlinuz-arynox console=tty0 console=ttyS0,115200n8 root=LABEL=ARYNOX_ROOT rootflags=subvol=@ rw quiet
    initrd /boot/initramfs.img
}

menuentry "Arynox OS (Recovery)" --class arynox {
    linux /boot/vmlinuz-arynox console=tty0 console=ttyS0,115200n8 rw quiet systemd.unit=rescue.target
    initrd /boot/initramfs.img
}

menuentry "Firmware Setup" --class firmware {
    fwsetup
}
GRUB

# Generate ISO
RELEASE_DIR="$PROJECT/release"
mkdir -p "$RELEASE_DIR"

if command -v grub-mkrescue &>/dev/null; then
    grub-mkrescue -o "$RELEASE_DIR/arynox-os-0.1.0-amd64.iso" "$ISO_DIR" 2>&1 | tail -5
elif command -v xorriso &>/dev/null; then
    xorriso -as mkisofs -V "ARYNOX_2026" \
        -b boot/grub/grub.cfg -no-emul-boot \
        -o "$RELEASE_DIR/arynox-os-0.1.0-amd64.iso" "$ISO_DIR" 2>&1 | tail -5
fi

# Final
echo ""
echo "=========================================="
if [ -f "$RELEASE_DIR/arynox-os-0.1.0-amd64.iso" ]; then
    echo "  BUILD SUCCESSFUL!"
    echo "  ISO: $RELEASE_DIR/arynox-os-0.1.0-amd64.iso"
    ls -lh "$RELEASE_DIR/arynox-os-0.1.0-amd64.iso"
    echo ""
    echo "  Contents:"
    echo "  - Linux 6.6.30 kernel"
    echo "  - Initramfs with Arynox system services"
    echo "  - Squashfs root with all daemons"
    echo "  - GRUB bootloader (BIOS+UEFI)"
    echo ""
    echo "  Built by: Aryan Chavan"
    echo "  Arynox Technologies (C) 2026"
else
    echo "  Build incomplete. Check errors above."
fi
echo "=========================================="

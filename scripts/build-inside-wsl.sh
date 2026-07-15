#!/usr/bin/env bash
# This script runs INSIDE WSL to build Arynox OS
set -euo pipefail

PROJECT_DIR="/mnt/d/Arynoxtech/ArynoxOS"
BUILD_DIR="$PROJECT_DIR/build"
RELEASE_DIR="$PROJECT_DIR/release"
CORES=$(nproc)

export PATH="$HOME/.cargo/bin:/opt/arynox-ai-venv/bin:$PATH"
export CARGO_HOME="$HOME/.cargo"
export RUSTUP_HOME="$HOME/.rustup"

mkdir -p "$BUILD_DIR" "$RELEASE_DIR"

log() { echo -e "\033[0;32m[BUILD]\033[0m $1"; }

# Phase: Build all Rust crates
log "Building all Rust crates..."
cd "$PROJECT_DIR"
source "$HOME/.cargo/env" 2>/dev/null || true

for crate in \
    core/arynox-tpm core/arynox-boot-check core/arynox-session \
    src/wm src/files src/devices src/packages src/security \
    src/cloud src/devtools src/updates src/installer src/recovery src/network
do
    if [ -f "$PROJECT_DIR/$crate/Cargo.toml" ]; then
        log "  Building $crate..."
        cargo build --release --manifest-path "$PROJECT_DIR/$crate/Cargo.toml" 2>&1 | tail -3 || log "  [WARN] $crate build had issues"
    fi
done

# Phase: Build Python AI runtime
log "Building Python AI runtime..."
if [ -f "$PROJECT_DIR/ai-python/pyproject.toml" ]; then
    cd "$PROJECT_DIR/ai-python"
    python3 -m build --wheel 2>&1 | tail -3 || log "Failed to build Python package"
fi

# Phase: Create initramfs
log "Creating initramfs..."
INITRAMFS_DIR="$BUILD_DIR/initramfs"
mkdir -p "$INITRAMFS_DIR"/{bin,dev,etc,lib,proc,sys,tmp,usr/lib/arynox}

apt-get install -y -qq busybox-static 2>/dev/null || true
if [ -f /bin/busybox ]; then
    cp /bin/busybox "$INITRAMFS_DIR/bin/"
    for cmd in sh mount umount insmod ls cat echo grep dmesg mkdir rm cp mv chroot switch_root; do
        ln -sf /bin/busybox "$INITRAMFS_DIR/bin/$cmd" 2>/dev/null || true
    done
fi

# Copy initramfs script
mkdir -p "$INITRAMFS_DIR/scripts"
cp "$PROJECT_DIR/src/boot/initramfs/scripts/arynox-boot" "$INITRAMFS_DIR/init" 2>/dev/null || true
chmod +x "$INITRAMFS_DIR/init" 2>/dev/null || true

# Create a simple init script if the real one wasn't available
if [ ! -f "$INITRAMFS_DIR/init" ]; then
    cat > "$INITRAMFS_DIR/init" << 'EOINIT'
#!/bin/sh
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
echo "Arynox OS - Initramfs"
exec /bin/sh
EOINIT
    chmod +x "$INITRAMFS_DIR/init"
fi

cd "$INITRAMFS_DIR"
find . | cpio -H newc -o | gzip -9 > "$BUILD_DIR/initramfs.img" 2>/dev/null
log "Initramfs: $BUILD_DIR/initramfs.img ($(du -h "$BUILD_DIR/initramfs.img" | cut -f1))"

# Phase: Download kernel
log "Downloading kernel..."
KERNEL_VER="6.6.30"
KERNEL_DIR="$BUILD_DIR/linux-$KERNEL_VER"

if [ ! -f "$KERNEL_DIR/vmlinux" ]; then
    if [ ! -f "$BUILD_DIR/linux.tar.xz" ]; then
        wget -q "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$KERNEL_VER.tar.xz" -O "$BUILD_DIR/linux.tar.xz"
    fi
    tar xf "$BUILD_DIR/linux.tar.xz" -C "$BUILD_DIR" 2>/dev/null
fi

# Use Ubuntu's kernel config as base + Arynox specific extra modules
if [ -f "$KERNEL_DIR/Makefile" ]; then
    cd "$KERNEL_DIR"
    if [ ! -f .config ]; then
        # Use Ubuntu's kernel config as base
        if [ -f /boot/config-* ]; then
            cp /boot/config-* .config 2>/dev/null
        else
            make defconfig 2>/dev/null
        fi
    fi
    log "Compiling kernel (this will take a while)..."
    make -j"$CORES" bzImage 2>&1 | tail -5 || log "Kernel build failed (expected in WSL)"
    cp arch/x86/boot/bzImage "$BUILD_DIR/vmlinuz-arynox" 2>/dev/null || true
fi

# Use host kernel if build failed
if [ ! -f "$BUILD_DIR/vmlinuz-arynox" ]; then
    log "Using host kernel..."
    cp /boot/vmlinuz-* "$BUILD_DIR/vmlinuz-arynox" 2>/dev/null || true
fi

# Phase: Create squashfs
log "Creating squashfs..."
ROOTFS_DIR="$BUILD_DIR/rootfs"
mkdir -p "$ROOTFS_DIR"/{bin,dev,etc,home,lib,proc,run,sbin,sys,tmp,usr,var}
mkdir -p "$ROOTFS_DIR/usr/lib/arynox"
mkdir -p "$ROOTFS_DIR/etc/arynox"
mkdir -p "$ROOTFS_DIR/usr/lib/systemd/system"

# Copy compiled Rust binaries
RUST_TARGET="$PROJECT_DIR/target/release"
for bin in arynox-session arynox-compositor arynox-tpm arynox-boot-check; do
    [ -f "$RUST_TARGET/$bin" ] && cp "$RUST_TARGET/$bin" "$ROOTFS_DIR/usr/lib/arynox/"
done

for daemon in arynox-device-manager arynox-package-manager arynox-security arynox-cloud arynox-devtools arynox-updates arynox-installer arynox-recovery; do
    [ -f "$RUST_TARGET/$daemon" ] && cp "$RUST_TARGET/$daemon" "$ROOTFS_DIR/usr/lib/arynox/"
done

# Copy systemd units
cp "$PROJECT_DIR/src/boot/systemd/"*.service "$ROOTFS_DIR/usr/lib/systemd/system/" 2>/dev/null || true

# Create os-release
cat > "$ROOTFS_DIR/usr/lib/os-release" << 'EOF'
NAME="Arynox OS"
ID=arynox
PRETTY_NAME="Arynox OS 0.1.0 Alpha"
VERSION_ID="0.1.0"
VERSION_CODENAME="Alpha"
HOME_URL="https://arynox.com"
EOF

# Create version file
cat > "$ROOTFS_DIR/etc/arynox/version" << 'EOF'
ARYNOX_OS_VERSION="0.1.0"
ARYNOX_OS_CODENAME="Alpha"
KERNEL_VERSION="6.6.30"
BUILD_DATE="2026-07-15"
EOF

# Create AI runtime config
cp "$PROJECT_DIR/config/ai-runtime.yaml" "$ROOTFS_DIR/etc/arynox/" 2>/dev/null || cat > "$ROOTFS_DIR/etc/arynox/ai-runtime.yaml" << 'EOF'
providers:
  groq:
    api_key: ""
    base_url: "https://api.groq.com/openai/v1"
    default_model: "llama3-70b-8192"
  openai:
    api_key: ""
    base_url: "https://api.openai.com/v1"
    default_model: "gpt-4o"
EOF

# Create fstab
cat > "$ROOTFS_DIR/etc/fstab" << 'EOF'
/dev/root / btrfs subvol=@,compress=zstd,noatime 0 1
tmpfs /tmp tmpfs defaults,noatime,mode=1777 0 0
EOF

# Device nodes
mknod -m 666 "$ROOTFS_DIR/dev/null" c 1 3 2>/dev/null || true
mknod -m 644 "$ROOTFS_DIR/dev/random" c 1 8 2>/dev/null || true
mknod -m 644 "$ROOTFS_DIR/dev/urandom" c 1 9 2>/dev/null || true

# Create squashfs
mksquashfs "$ROOTFS_DIR" "$BUILD_DIR/filesystem.squashfs" \
    -comp zstd -b 1M -noappend -no-exports -quiet 2>&1 || \
    log "Squashfs creation failed (may need more disk space)"

# Phase: Generate bootable ISO
log "Generating bootable ISO..."
ISO_DIR="$BUILD_DIR/iso"
mkdir -p "$ISO_DIR/"{boot/grub,live,EFI/BOOT}

# Copy boot files
[ -f "$BUILD_DIR/vmlinuz-arynox" ] && cp "$BUILD_DIR/vmlinuz-arynox" "$ISO_DIR/boot/"
[ -f "$BUILD_DIR/initramfs.img" ] && cp "$BUILD_DIR/initramfs.img" "$ISO_DIR/boot/"
[ -f "$BUILD_DIR/filesystem.squashfs" ] && cp "$BUILD_DIR/filesystem.squashfs" "$ISO_DIR/live/"

# GRUB config
cat > "$ISO_DIR/boot/grub/grub.cfg" << 'GRUB'
set default=0
set timeout=5
insmod all_video
insmod gfxterm
set gfxmode=auto
set gfxpayload=keep
terminal_output gfxterm

menuentry "Arynox OS" --class arynox {
    linux /boot/vmlinuz-arynox root=/dev/sda2 quiet splash loglevel=3
    initrd /boot/initramfs.img
}

menuentry "Arynox OS (Recovery)" --class arynox {
    linux /boot/vmlinuz-arynox root=/dev/sda2 quiet systemd.unit=recovery.target
    initrd /boot/initramfs.img
}

menuentry "Arynox OS (Safe Graphics)" --class arynox {
    linux /boot/vmlinuz-arynox root=/dev/sda2 quiet nomodeset
    initrd /boot/initramfs.img
}

menuentry "Firmware Setup" --class firmware {
    fwsetup
}
GRUB

# Generate ISO
log "Running grub-mkrescue..."
grub-mkrescue -o "$RELEASE_DIR/arynox-os-0.1.0-amd64.iso" "$ISO_DIR" 2>&1 | tail -5 || \
    log "ISO creation failed - building with xorriso directly"

# Fallback: direct xorriso
if [ ! -f "$RELEASE_DIR/arynox-os-0.1.0-amd64.iso" ]; then
    xorriso -as mkisofs \
        -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
        -isohybrid-gpt-basdat \
        -o "$RELEASE_DIR/arynox-os-0.1.0-amd64.iso" \
        "$ISO_DIR" 2>&1 | tail -3 || \
        log "xorriso build also failed"
fi

# Summary
log "========================================"
if [ -f "$RELEASE_DIR/arynox-os-0.1.0-amd64.iso" ]; then
    log "ISO CREATED SUCCESSFULLY!"
    ls -lh "$RELEASE_DIR/arynox-os-0.1.0-amd64.iso"
else
    log "ISO build had issues."
fi
log "Contents:"
ls -lh "$BUILD_DIR/vmlinuz-arynox" "$BUILD_DIR/initramfs.img" "$BUILD_DIR/filesystem.squashfs" 2>/dev/null || true
log "========================================"

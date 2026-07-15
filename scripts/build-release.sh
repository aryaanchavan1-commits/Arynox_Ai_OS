#!/bin/bash
set -euo pipefail

PROJECT="/mnt/d/Arynoxtech/ArynoxOS"
export HOME=/root
export PATH="/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

echo "=== Arynox OS Build ==="
echo ""

# Configure git and cargo
git config --global url."https://github.com/".insteadOf git://github.com/ 2>/dev/null || true
mkdir -p /root/.cargo
cat > /root/.cargo/config.toml << 'EOF'
[net]
git-fetch-with-cli = true
EOF

# Step 1: Create a temporary build workspace with only buildable crates
echo "=== Step 1: Creating temporary build workspace ==="
TMP_WS="$PROJECT/build/workspace"
mkdir -p "$TMP_WS"

# Create a minimal workspace Cargo.toml
# Copy crates that can build without git/system dependencies
echo "Copying crate sources..."
cp -r "$PROJECT/core/arynox-session" "$TMP_WS/arynox-session"
cp -r "$PROJECT/core/arynox-boot-check" "$TMP_WS/arynox-boot-check"

cat > "$TMP_WS/Cargo.toml" << 'WORKSPACE'
[workspace]
resolver = "2"
members = [
    "arynox-session",
    "arynox-boot-check",
]
WORKSPACE

# Step 2: Build them
echo ""
echo "=== Step 2: Building crates ==="
cd "$TMP_WS"

echo "Building all workspace crates..."
cargo build --release 2>&1 | tail -15
# Copy artifacts
cp target/release/arynox-session "$PROJECT/target/release/arynox-session" 2>/dev/null || true
cp target/release/arynox-boot-check "$PROJECT/target/release/arynox-boot-check" 2>/dev/null || true

# Step 3: Show results
echo ""
echo "=== Build Artifacts ==="
mkdir -p "$PROJECT/target/release"
ls -la "$PROJECT/target/release/arynox-session" "$PROJECT/target/release/arynox-boot-check" 2>/dev/null || echo "No binaries built"

echo ""
echo "=== Creating initramfs ==="
INITRAMFS_DIR="$PROJECT/build/initramfs"
rm -rf "$INITRAMFS_DIR"
mkdir -p "$INITRAMFS_DIR"/bin
mkdir -p "$INITRAMFS_DIR"/{dev,etc,proc,sys,tmp,usr/lib/arynox}

# Copy busybox
cp /bin/busybox "$INITRAMFS_DIR/bin/"
ln -sf /bin/busybox "$INITRAMFS_DIR/bin/sh" 2>/dev/null || true
ln -sf /bin/busybox "$INITRAMFS_DIR/bin/mount" 2>/dev/null || true
ln -sf /bin/busybox "$INITRAMFS_DIR/bin/switch_root" 2>/dev/null || true

# Copy built binaries if they exist
for bin in arynox-session arynox-boot-check; do
    src="$PROJECT/target/release/$bin"
    if [ -f "$src" ]; then
        cp "$src" "$INITRAMFS_DIR/usr/lib/arynox/"
        echo "  Added: $bin"
    fi
done

# Create init script
cat > "$INITRAMFS_DIR/init" << 'EOINIT'
#!/bin/busybox sh
/bin/busybox mount -t proc proc /proc
/bin/busybox mount -t sysfs sysfs /sys
/bin/busybox mount -t devtmpfs devtmpfs /dev
echo "Arynox OS - Recovery Initramfs"
echo "Version: 0.1.0"
echo ""
# Start a shell for recovery
exec /bin/busybox sh
EOINIT
chmod +x "$INITRAMFS_DIR/init"

cd "$INITRAMFS_DIR"
find . | cpio -H newc -o | gzip -9 > "$PROJECT/build/initramfs.img"
echo "Initramfs: $PROJECT/build/initramfs.img ($(du -h "$PROJECT/build/initramfs.img" | cut -f1))"

echo ""
echo "=== Creating ISO structure ==="
ISO_DIR="$PROJECT/build/iso"
rm -rf "$ISO_DIR"
mkdir -p "$ISO_DIR/"{boot/grub,live,EFI/BOOT}

# Use host kernel
cp /boot/vmlinuz-* "$ISO_DIR/boot/vmlinuz-arynox" 2>/dev/null || true
cp "$PROJECT/build/initramfs.img" "$ISO_DIR/boot/"

# Create squashfs with minimal rootfs
ROOTFS="$PROJECT/build/rootfs"
rm -rf "$ROOTFS"
mkdir -p "$ROOTFS"/{bin,dev,etc,home,lib,proc,run,sbin,sys,tmp,usr,var}
mkdir -p "$ROOTFS/usr/lib/arynox"
mkdir -p "$ROOTFS/etc/arynox"
mkdir -p "$ROOTFS/usr/lib/systemd/system"

# Copy Arynox binaries
for bin in arynox-session arynox-boot-check; do
    src="$PROJECT/target/release/$bin"
    [ -f "$src" ] && cp "$src" "$ROOTFS/usr/lib/arynox/"
done

# Copy systemd units
cp "$PROJECT/src/boot/systemd/"*.service "$ROOTFS/usr/lib/systemd/system/" 2>/dev/null || true

# OS release
cat > "$ROOTFS/usr/lib/os-release" << 'EOF'
NAME="Arynox OS"
ID=arynox
PRETTY_NAME="Arynox OS 0.1.0 Alpha"
VERSION_ID="0.1.0"
VERSION_CODENAME="Alpha"
EOF

cat > "$ROOTFS/etc/arynox/version" << 'EOF'
ARYNOX_OS_VERSION="0.1.0"
BUILD_DATE="2026-07-15"
EOF

# Device nodes
mknod -m 666 "$ROOTFS/dev/null" c 1 3 2>/dev/null || true
mknod -m 644 "$ROOTFS/dev/random" c 1 8 2>/dev/null || true
mknod -m 644 "$ROOTFS/dev/urandom" c 1 9 2>/dev/null || true

# Fstab
cat > "$ROOTFS/etc/fstab" << 'EOF'
/dev/root / btrfs subvol=@,compress=zstd,noatime 0 1
tmpfs /tmp tmpfs defaults,noatime,mode=1777 0 0
EOF

# Create squashfs
echo "Creating squashfs..."
mksquashfs "$ROOTFS" "$PROJECT/build/filesystem.squashfs" \
    -comp zstd -b 1M -noappend -quiet 2>&1 || echo "Squashfs creation note: $?"

# Copy to ISO
cp "$PROJECT/build/filesystem.squashfs" "$ISO_DIR/live/" 2>/dev/null || true

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
    linux /boot/vmlinuz-arynox quiet splash loglevel=3
    initrd /boot/initramfs.img
}
menuentry "Arynox OS (Recovery)" --class arynox {
    linux /boot/vmlinuz-arynox quiet systemd.unit=recovery.target
    initrd /boot/initramfs.img
}
GRUB

echo ""
echo "=== Generating ISO ==="
RELEASE_DIR="$PROJECT/release"
mkdir -p "$RELEASE_DIR"

if command -v grub-mkrescue &>/dev/null; then
    grub-mkrescue -o "$RELEASE_DIR/arynox-os-0.1.0-amd64.iso" "$ISO_DIR" 2>&1 | tail -3 || \
    xorriso -as mkisofs -b isolinux/isolinux.bin -c isolinux/boot.cat \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
        -isohybrid-gpt-basdat \
        -o "$RELEASE_DIR/arynox-os-0.1.0-amd64.iso" "$ISO_DIR" 2>&1 | tail -3
elif command -v xorriso &>/dev/null; then
    xorriso -as mkisofs -V "ARYNOX_OS" \
        -b boot/grub/grub.cfg -no-emul-boot -boot-load-size 4 \
        -o "$RELEASE_DIR/arynox-os-0.1.0-amd64.iso" "$ISO_DIR" 2>&1 | tail -3
fi

echo ""
echo "========================================="
if [ -f "$RELEASE_DIR/arynox-os-0.1.0-amd64.iso" ]; then
    echo "SUCCESS: ISO created!"
    ls -lh "$RELEASE_DIR/arynox-os-0.1.0-amd64.iso"
else
    echo "Build artifacts:"
    ls -lh "$PROJECT/build/"*.img "$PROJECT/build/"*.squashfs 2>/dev/null || true
    echo "ISO not created. See errors above."
fi
echo "========================================="

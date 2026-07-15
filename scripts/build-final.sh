#!/bin/bash
set -euo pipefail

PROJECT="/mnt/d/Arynoxtech/ArynoxOS"
export HOME=/root
export PATH="/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

echo "=== Arynox OS Final Build ==="
echo ""

# Ensure built binaries are available
echo "Copying built binaries..."
mkdir -p "$PROJECT/target/release"
cp "$PROJECT/build/workspace/target/release/arynox-session" "$PROJECT/target/release/arynox-session" 2>/dev/null || true
cp "$PROJECT/build/workspace/target/release/arynox-boot-check" "$PROJECT/target/release/arynox-boot-check" 2>/dev/null || true

# Check binaries
echo "Binaries:"
ls -lh "$PROJECT/target/release/arynox-session" "$PROJECT/target/release/arynox-boot-check" 2>/dev/null || echo "Missing binaries!"
echo ""

# Initramfs
echo "=== Creating initramfs ==="
INITRAMFS_DIR="$PROJECT/build/initramfs"
rm -rf "$INITRAMFS_DIR"
mkdir -p "$INITRAMFS_DIR"/bin
mkdir -p "$INITRAMFS_DIR"/{dev,etc,proc,sys,tmp,usr/lib/arynox}

cp /bin/busybox "$INITRAMFS_DIR/bin/"
ln -sf busybox "$INITRAMFS_DIR/bin/sh"
ln -sf busybox "$INITRAMFS_DIR/bin/mount"
ln -sf busybox "$INITRAMFS_DIR/bin/switch_root"
ln -sf busybox "$INITRAMFS_DIR/bin/grep"
ln -sf busybox "$INITRAMFS_DIR/bin/ls"
ln -sf busybox "$INITRAMFS_DIR/bin/cat"
ln -sf busybox "$INITRAMFS_DIR/bin/echo"
ln -sf busybox "$INITRAMFS_DIR/bin/mkdir"
ln -sf busybox "$INITRAMFS_DIR/bin/dmesg"
ln -sf busybox "$INITRAMFS_DIR/bin/mdev"

# Copy Arynox binaries into initramfs
for bin in arynox-session arynox-boot-check; do
    src="$PROJECT/target/release/$bin"
    if [ -f "$src" ]; then
        cp "$src" "$INITRAMFS_DIR/usr/lib/arynox/"
        echo "  Added: $bin ($(du -h "$src" | cut -f1))"
    fi
done

# Create /etc/init.d/rcS
mkdir -p "$INITRAMFS_DIR/etc/init.d"
cat > "$INITRAMFS_DIR/etc/init.d/rcS" << 'EOF'
#!/bin/sh
/bin/mount -t proc proc /proc
/bin/mount -t sysfs sysfs /sys
/bin/mount -t devtmpfs devtmpfs /dev
/bin/mdev -s
echo "Arynox OS - Initramfs v0.1.0"
EOF
chmod +x "$INITRAMFS_DIR/etc/init.d/rcS"

# Create init script
cat > "$INITRAMFS_DIR/init" << 'EOF'
#!/bin/sh
/bin/mount -t proc proc /proc
/bin/mount -t sysfs sysfs /sys
/bin/mount -t devtmpfs devtmpfs /dev
/bin/mdev -s

echo "========================"
echo " Arynox OS v0.1.0"
echo " AI-Native Operating System"
echo "========================"
echo ""

# Attempt to mount root and switch
if [ -e /dev/sda2 ]; then
    /bin/mount -t btrfs -o subvol=@ /dev/sda2 /mnt/root 2>/dev/null && \
    exec /bin/switch_root /mnt/root /usr/lib/arynox/arynox-session
fi

# Fallback to recovery shell
echo ""
echo "Starting recovery shell..."
echo ""
exec /bin/sh
EOF
chmod +x "$INITRAMFS_DIR/init"

cd "$INITRAMFS_DIR"
find . | cpio -H newc -o | gzip -9 > "$PROJECT/build/initramfs.img"
echo "Initramfs: $(du -h "$PROJECT/build/initramfs.img" | cut -f1)"

# Kernel
echo ""
echo "=== Kernel ==="
KERNEL_SRC="$PROJECT/build/linux-6.6.30"
if [ -f "$KERNEL_SRC/arch/x86/boot/bzImage" ]; then
    cp "$KERNEL_SRC/arch/x86/boot/bzImage" "$PROJECT/build/vmlinuz-arynox"
    echo "Custom kernel: $(du -h "$PROJECT/build/vmlinuz-arynox" | cut -f1)"
elif [ -f /boot/vmlinuz-* ]; then
    cp /boot/vmlinuz-* "$PROJECT/build/vmlinuz-arynox" 2>/dev/null || true
    echo "Host kernel: $(ls -lh /boot/vmlinuz-* | head -1 | awk '{print $5}')"
fi

# Rootfs + squashfs
echo ""
echo "=== Root filesystem ==="
ROOTFS="$PROJECT/build/rootfs"
rm -rf "$ROOTFS"
mkdir -p "$ROOTFS"/{bin,dev,etc/arynox,home,lib,proc,run,sbin,sys,tmp,usr/lib/arynox,usr/lib/systemd/system,var/lib/arynox}

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
HOME_URL="https://arynox.com"
SUPPORT_URL="https://docs.arynox.com"
EOF

cat > "$ROOTFS/etc/arynox/version" << 'EOF'
ARYNOX_OS_VERSION="0.1.0"
ARYNOX_OS_CODENAME="Alpha"
BUILD_DATE="2026-07-15"
KERNEL_VERSION="6.6.30"
EOF

# AI runtime config
cat > "$ROOTFS/etc/arynox/ai-runtime.yaml" << 'EOF'
providers:
  groq:
    api_key: ""
    base_url: "https://api.groq.com/openai/v1"
    default_model: "llama3-70b-8192"
    temperature: 0.7
    max_tokens: 4096
EOF

# Device nodes
mknod -m 666 "$ROOTFS/dev/null" c 1 3 2>/dev/null || true
mknod -m 644 "$ROOTFS/dev/random" c 1 8 2>/dev/null || true
mknod -m 644 "$ROOTFS/dev/urandom" c 1 9 2>/dev/null || true
mknod -m 666 "$ROOTFS/dev/console" c 5 1 2>/dev/null || true
mknod -m 666 "$ROOTFS/dev/tty" c 5 0 2>/dev/null || true

# Fstab
cat > "$ROOTFS/etc/fstab" << 'EOF'
# Arynox OS filesystem table
/dev/root / btrfs subvol=@,compress=zstd,noatime 0 1
tmpfs /tmp tmpfs defaults,noatime,mode=1777 0 0
tmpfs /run tmpfs defaults,noatime,mode=0755 0 0
EOF

# hostname
echo "arynox" > "$ROOTFS/etc/hostname"

# Squashfs
echo "Creating squashfs..."
mksquashfs "$ROOTFS" "$PROJECT/build/filesystem.squashfs" \
    -comp zstd -b 1M -noappend -quiet 2>&1
echo "Squashfs: $(du -h "$PROJECT/build/filesystem.squashfs" | cut -f1)"

# ISO
echo ""
echo "=== Building bootable ISO ==="
ISO_DIR="$PROJECT/build/iso"
rm -rf "$ISO_DIR"
mkdir -p "$ISO_DIR/"{boot/grub,live,EFI/BOOT}

cp "$PROJECT/build/vmlinuz-arynox" "$ISO_DIR/boot/" 2>/dev/null || true
cp "$PROJECT/build/initramfs.img" "$ISO_DIR/boot/"
cp "$PROJECT/build/filesystem.squashfs" "$ISO_DIR/live/" 2>/dev/null || true

# GRUB config
cat > "$ISO_DIR/boot/grub/grub.cfg" << 'GRUB'
set default=0
set timeout=5
insmod all_video
insmod gfxterm
insmod btrfs
insmod ext2
insmod part_gpt
set gfxmode=auto
set gfxpayload=keep
terminal_output gfxterm

menuentry "Arynox OS" --class arynox {
    linux /boot/vmlinuz-arynox root=LABEL=ARYNOX_ROOT rootflags=subvol=@ rw quiet splash loglevel=3
    initrd /boot/initramfs.img
}

menuentry "Arynox OS (Recovery)" --class arynox {
    linux /boot/vmlinuz-arynox root=LABEL=ARYNOX_ROOT rw quiet systemd.unit=rescue.target
    initrd /boot/initramfs.img
}

menuentry "Arynox OS (Safe Graphics)" --class arynox {
    linux /boot/vmlinuz-arynox root=LABEL=ARYNOX_ROOT rw nomodeset
    initrd /boot/initramfs.img
}

menuentry "Firmware Setup" --class firmware {
    fwsetup
}
GRUB

# Generate ISO
RELEASE_DIR="$PROJECT/release"
mkdir -p "$RELEASE_DIR"

echo "Running grub-mkrescue..."
if grub-mkrescue -o "$RELEASE_DIR/arynox-os-0.1.0-amd64.iso" "$ISO_DIR" 2>&1; then
    echo ""
    echo "=============================================="
    echo "  SUCCESS: ISO created!"
    echo "=============================================="
    ls -lh "$RELEASE_DIR/arynox-os-0.1.0-amd64.iso"
else
    echo ""
    echo "grub-mkrescue failed, trying xorriso..."
    xorriso -as mkisofs \
        -V "ARYNOX_OS" \
        -b isolinux/isolinux.bin -c isolinux/boot.cat \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
        -isohybrid-gpt-basdat \
        -o "$RELEASE_DIR/arynox-os-0.1.0-amd64.iso" \
        "$ISO_DIR" 2>&1 || echo "xorriso also failed"
fi

# Summary
echo ""
echo "=== Build Summary ==="
echo "Project: $PROJECT"
echo "ISO: $RELEASE_DIR/arynox-os-0.1.0-amd64.iso"
if [ -f "$RELEASE_DIR/arynox-os-0.1.0-amd64.iso" ]; then
    echo "Status: SUCCESS"
else
    echo "Status: ISO not created (artifacts available)"
    ls -lh "$PROJECT/build/vmlinuz-arynox" "$PROJECT/build/initramfs.img" "$PROJECT/build/filesystem.squashfs" 2>/dev/null
fi
echo ""

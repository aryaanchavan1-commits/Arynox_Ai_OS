#!/bin/bash
set -euo pipefail
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"
echo "=== Arynox OS Final ISO Build ==="
echo ""

# Minimal initramfs (no Flutter - those go in squashfs root)
echo "Building minimal initramfs..."
INITRAMFS="$PROJECT/build/initramfs"
rm -rf "$INITRAMFS"
mkdir -p "$INITRAMFS"/bin
mkdir -p "$INITRAMFS"/{dev,etc,proc,sys,tmp,usr/lib/arynox,lib64,lib/x86_64-linux-gnu}

cp /bin/busybox "$INITRAMFS/bin/"
for c in sh mount umount grep ls cat echo mkdir dmesg mknod switch_root poweroff reboot; do
    ln -sf busybox "$INITRAMFS/bin/$c" 2>/dev/null || true
done

for lib in libgcc_s.so.1 libm.so.6 libc.so.6 libpthread.so.0 librt.so.1; do
    cp "/lib/x86_64-linux-gnu/$lib" "$INITRAMFS/lib/x86_64-linux-gnu/" 2>/dev/null || true
done
cp /lib64/ld-linux-x86-64.so.2 "$INITRAMFS/lib64/" 2>/dev/null || true

cat > "$INITRAMFS/init" << 'XEOF'
#!/bin/sh
/bin/mount -t proc proc /proc
/bin/mount -t sysfs sysfs /sys
/bin/mount -t devtmpfs devtmpfs /dev
/bin/mdev -s
export LD_LIBRARY_PATH=/lib64:/lib/x86_64-linux-gnu
echo ""
echo "  Arynox OS v0.1.0  |  Created by Aryan Chavan  |  (C) 2026"
echo "  AI-Native Operating System"
echo ""
exec /bin/sh
XEOF
chmod +x "$INITRAMFS/init"

cd "$INITRAMFS"
find . | cpio -H newc -o 2>/dev/null | gzip -9 > "$PROJECT/build/initramfs.img"
echo "Initramfs: $(du -h $PROJECT/build/initramfs.img | cut -f1)"

# Build comprehensive root squashfs
echo ""
echo "Building root filesystem (squashfs)..."
ROOTFS="$PROJECT/build/rootfs"
rm -rf "$ROOTFS"
mkdir -p "$ROOTFS"/{bin,dev,etc,home,lib,proc,run,sbin,sys,tmp,usr/lib,usr/share,var}

# Shared libs
for lib in libgcc_s.so.1 libm.so.6 libc.so.6 libpthread.so.0 librt.so.1 libdl.so.2 libresolv.so.2 libnss_dns.so.2 libnss_files.so.2; do
    cp "/lib/x86_64-linux-gnu/$lib" "$ROOTFS/lib/" 2>/dev/null || true
done
cp /lib64/ld-linux-x86-64.so.2 "$ROOTFS/lib64/" 2>/dev/null || true

# Rust daemons
mkdir -p "$ROOTFS/usr/lib/arynox"
for bin in arynox-*; do
    src="$PROJECT/target/release/$bin"
    [ -f "$src" ] && cp "$src" "$ROOTFS/usr/lib/arynox/"
done

# Flutter apps
echo "Copying Flutter apps..."
for d in "$PROJECT/build/flutter-apps/"*/; do
    app=$(basename "$d")
    mkdir -p "$ROOTFS/usr/share/arynox/$app"
    cp -r "$d"/* "$ROOTFS/usr/share/arynox/$app/"
done

# Python AI runtime
mkdir -p "$ROOTFS/usr/lib/arynox/ai-runtime"
cp -r "$PROJECT/ai-python/arynox_ai" "$ROOTFS/usr/lib/arynox/ai-runtime/" 2>/dev/null || true

# systemd + D-Bus
mkdir -p "$ROOTFS/etc/systemd/system" "$ROOTFS/etc/dbus-1/system.d"
cp "$PROJECT/src/boot/systemd/"*.service "$ROOTFS/etc/systemd/system/" 2>/dev/null || true
cp "$PROJECT/src/boot/systemd/"*.target "$ROOTFS/etc/systemd/system/" 2>/dev/null || true
cp "$PROJECT/src/boot/dbus/"*.conf "$ROOTFS/etc/dbus-1/system.d/" 2>/dev/null || true

# OS config
mkdir -p "$ROOTFS/etc/arynox"
cat > "$ROOTFS/etc/os-release" << 'EOF'
NAME="Arynox OS"
ID=arynox
PRETTY_NAME="Arynox OS 0.1.0 (2026)"
VERSION_ID="0.1.0"
HOME_URL="https://arynox.com"
EOF
echo "arynox" > "$ROOTFS/etc/hostname"

# Device nodes
for dev in null zero random urandom console tty; do
    mknod -m 666 "$ROOTFS/dev/$dev" c 1 3 2>/dev/null || true
done

# Build squashfs
mksquashfs "$ROOTFS" "$PROJECT/build/filesystem.squashfs" -comp zstd -b 1M -noappend -quiet 2>&1
echo "Squashfs: $(du -h $PROJECT/build/filesystem.squashfs | cut -f1)"

# Build ISO
echo ""
echo "Building ISO..."
ISO_DIR="$PROJECT/build/iso"
rm -rf "$ISO_DIR"
mkdir -p "$ISO_DIR/"{boot/grub,live,EFI/BOOT}

if [ -f "$PROJECT/build/vmlinuz-arynox" ]; then
    cp "$PROJECT/build/vmlinuz-arynox" "$ISO_DIR/boot/"
else
    cp /tmp/kern-extract/boot/vmlinuz-* "$ISO_DIR/boot/vmlinuz-arynox" 2>/dev/null || true
fi
cp "$PROJECT/build/initramfs.img" "$ISO_DIR/boot/"
cp "$PROJECT/build/filesystem.squashfs" "$ISO_DIR/live/" 2>/dev/null || true

cat > "$ISO_DIR/boot/grub/grub.cfg" << 'GEOF'
set default=0
set timeout=5
serial --unit=0 --speed=115200
terminal_input serial console
terminal_output serial console
menuentry "Arynox OS 2026" --class arynox {
    linux /boot/vmlinuz-arynox console=tty0 console=ttyS0,115200n8 root=/dev/ram0 rw quiet
    initrd /boot/initramfs.img
}
menuentry "Firmware Setup" --class firmware { fwsetup; }
GEOF

mkdir -p "$PROJECT/release"
grub-mkrescue -o "$PROJECT/release/arynox-os-0.1.0-amd64.iso" "$ISO_DIR" 2>&1 | tail -3

echo ""
echo "=== SUCCESS ==="
ls -lh "$PROJECT/release/arynox-os-0.1.0-amd64.iso"
echo "Built by: Aryan Chavan"

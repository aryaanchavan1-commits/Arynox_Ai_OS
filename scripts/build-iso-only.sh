#!/bin/bash
set -euo pipefail
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"
cd "$PROJECT"

echo "=== Creating initramfs ==="
INITRAMFS_DIR="$PROJECT/build/initramfs"
rm -rf "$INITRAMFS_DIR"
mkdir -p "$INITRAMFS_DIR"/bin
mkdir -p "$INITRAMFS_DIR"/{dev,etc,proc,sys,tmp,usr/lib/arynox,lib64,lib/x86_64-linux-gnu}

# Busybox
cp /bin/busybox "$INITRAMFS_DIR/bin/"
for cmd in sh mount umount switch_root grep ls cat echo mkdir dmesg mknod poweroff reboot; do
    ln -sf busybox "$INITRAMFS_DIR/bin/$cmd" 2>/dev/null || true
done

# Shared libraries (required by Rust binaries)
cp /lib/x86_64-linux-gnu/libgcc_s.so.1 "$INITRAMFS_DIR/lib/x86_64-linux-gnu/" 2>/dev/null || true
cp /lib/x86_64-linux-gnu/libm.so.6 "$INITRAMFS_DIR/lib/x86_64-linux-gnu/" 2>/dev/null || true
cp /lib/x86_64-linux-gnu/libc.so.6 "$INITRAMFS_DIR/lib/x86_64-linux-gnu/" 2>/dev/null || true
cp /lib64/ld-linux-x86-64.so.2 "$INITRAMFS_DIR/lib64/" 2>/dev/null || true

# All Arynox daemons
for bin in arynox-session arynox-boot-check arynox-compositor arynox-files \
           arynox-devices arynox-package-manager arynox-security \
           arynox-cloud arynox-devtools arynox-updates \
           arynox-installer arynox-recovery arynox-network-manager arynox-tpm; do
    src="$PROJECT/target/release/$bin"
    [ -f "$src" ] && cp "$src" "$INITRAMFS_DIR/usr/lib/arynox/" && echo "  Added: $bin"
done

# Init script
cat > "$INITRAMFS_DIR/init" << 'INITEOF'
#!/bin/busybox sh
/bin/mount -t proc proc /proc
/bin/mount -t sysfs sysfs /sys
/bin/mount -t devtmpfs devtmpfs /dev
/bin/mknod /dev/null c 1 3 2>/dev/null
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
    name=$(basename "$svc")
    if [ -x "$svc" ]; then
        echo "  Starting: $name"
        export LD_LIBRARY_PATH=/lib64:/lib/x86_64-linux-gnu
        "$svc" &
    else
        echo "  Skipping: $name (not found)"
    fi
done
echo ""
echo "System ready."
echo ""
exec /bin/sh
INITEOF
chmod +x "$INITRAMFS_DIR/init"

cd "$INITRAMFS_DIR"
find . | cpio -H newc -o 2>/dev/null | gzip -9 > "$PROJECT/build/initramfs.img"
echo "Initramfs: $(du -h "$PROJECT/build/initramfs.img" | cut -f1)"

echo ""
echo "=== Building ISO ==="
ISO_DIR="$PROJECT/build/iso"
rm -rf "$ISO_DIR"
mkdir -p "$ISO_DIR/"{boot/grub,live,EFI/BOOT}

cp /tmp/kern-extract/boot/vmlinuz-6.8.0-31-generic "$ISO_DIR/boot/vmlinuz-arynox"
cp "$PROJECT/build/initramfs.img" "$ISO_DIR/boot/"

cat > "$ISO_DIR/boot/grub/grub.cfg" << 'GRUBEOF'
set default=0
set timeout=10
serial --unit=0 --speed=115200
terminal_input serial console
terminal_output serial console

menuentry "Arynox OS 2026" --class arynox {
    linux /boot/vmlinuz-arynox console=tty0 console=ttyS0,115200n8 root=/dev/ram0 rw quiet
    initrd /boot/initramfs.img
}

menuentry "Arynox OS (Recovery)" --class arynox {
    linux /boot/vmlinuz-arynox console=tty0 console=ttyS0,115200n8 rw quiet
    initrd /boot/initramfs.img
}

menuentry "Firmware Setup" --class firmware {
    fwsetup
}
GRUBEOF

mkdir -p "$PROJECT/release"
if command -v grub-mkrescue &>/dev/null; then
    grub-mkrescue -o "$PROJECT/release/arynox-os-0.1.0-amd64.iso" "$ISO_DIR" 2>&1 | tail -3
fi

echo ""
echo "=========================================="
if [ -f "$PROJECT/release/arynox-os-0.1.0-amd64.iso" ]; then
    echo "  BUILD SUCCESSFUL!"
    ls -lh "$PROJECT/release/arynox-os-0.1.0-amd64.iso"
    echo "  Built by: Aryan Chavan"
    echo "  Arynox Technologies (C) 2026"
fi
echo "=========================================="

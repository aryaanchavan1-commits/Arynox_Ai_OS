#!/bin/bash
set -euo pipefail
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"
USBIMG="$PROJECT/build/arynox-usb.img"

[ -f "$PROJECT/build/filesystem.squashfs" ] || { echo "Run build-full-os.sh first"; exit 1; }

echo "Building Arynox OS bootable USB image..."
rm -f "$USBIMG"
dd if=/dev/zero of="$USBIMG" bs=1M count=6144 status=progress
parted -s "$USBIMG" mklabel msdos mkpart primary ext4 1MiB 100% set 1 boot on

LDEV=$(losetup -f --show -P "$USBIMG")
sleep 1
echo "Loop device: $LDEV"

mkfs.ext4 -F "${LDEV}p1"
mount "${LDEV}p1" /mnt/rootdisk

echo "Unsquashing rootfs..."
unsquashfs -f -d /mnt/rootdisk "$PROJECT/build/filesystem.squashfs" 2>&1 | tail -3

# Ensure kernel is in /boot
echo "Setting up kernel in /boot..."
KERNEL_SRC=""
for k in /boot/vmlinuz-* "$PROJECT/build/vmlinuz-arynox" "$PROJECT/build/iso/boot/vmlinuz-arynox"; do
    if [ -f "$k" ]; then
        KERNEL_SRC="$k"
        break
    fi
done
if [ -z "$KERNEL_SRC" ]; then
    apt-get download linux-image-generic 2>/dev/null
    dpkg -x linux-image-generic*.deb /tmp/kernel-extract 2>/dev/null
    KERNEL_SRC=$(find /tmp/kernel-extract -name 'vmlinuz-*' | head -1)
fi
if [ -f "$KERNEL_SRC" ]; then
    cp -v "$KERNEL_SRC" /mnt/rootdisk/boot/
fi

# Create /etc/default/grub if missing
if [ ! -f /mnt/rootdisk/etc/default/grub ]; then
    mkdir -p /mnt/rootdisk/etc/default
    cat > /mnt/rootdisk/etc/default/grub << 'GRUBEOF'
GRUB_DEFAULT=0
GRUB_TIMEOUT=3
GRUB_CMDLINE_LINUX_DEFAULT=""
GRUB_CMDLINE_LINUX="console=ttyS0,115200n8 nokaslr apparmor=0 systemd.default_timeout_start_sec=30"
GRUB_TERMINAL=serial
GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"
GRUB_DISABLE_OS_PROBER=true
GRUB_DISABLE_RECOVERY=true
GRUBEOF
fi

echo "Installing GRUB..."
mount --bind /dev /mnt/rootdisk/dev
mount --bind /proc /mnt/rootdisk/proc
mount --bind /sys /mnt/rootdisk/sys

chroot /mnt/rootdisk grub-install "$LDEV" 2>&1
chroot /mnt/rootdisk update-grub 2>&1

umount /mnt/rootdisk/dev
umount /mnt/rootdisk/proc
umount /mnt/rootdisk/sys
umount /mnt/rootdisk
losetup -d "$LDEV"

echo ""
echo "USB image built: $(ls -lh "$USBIMG")"
echo ""
echo "Test with:"
echo "  qemu-system-x86_64 -m 4G -nographic -drive file=$USBIMG,format=raw,if=virtio"
echo "  qemu-system-x86_64 -m 4G -vga virtio -vnc :0 -drive file=$USBIMG,format=raw,if=virtio"

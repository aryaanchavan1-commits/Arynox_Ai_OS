#!/bin/bash
set -uo pipefail
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"
USBIMG="$PROJECT/build/arynox-usb.img"

echo "Building Arynox OS bootable USB image..."
rm -f "$USBIMG"
dd if=/dev/zero of="$USBIMG" bs=1M count=6144 status=progress

echo "Creating partition table..."
parted -s "$USBIMG" mklabel msdos mkpart primary ext4 1MiB 100% set 1 boot on

echo "Setting up loop device..."
LDEV=$(losetup -f --show -P "$USBIMG")
sleep 1
echo "Loop device: $LDEV"

echo "Formatting partition..."
mkfs.ext4 -F "${LDEV}p1"

echo "Mounting and extracting rootfs..."
mount "${LDEV}p1" /mnt/rootdisk
unsquashfs -f -d /mnt/rootdisk "$PROJECT/build/filesystem.squashfs"

echo "Installing GRUB..."
mount --bind /dev /mnt/rootdisk/dev
mount --bind /proc /mnt/rootdisk/proc
mount --bind /sys /mnt/rootdisk/sys
chroot /mnt/rootdisk apt-get update -qq
chroot /mnt/rootdisk apt-get install -y -qq grub-pc-bin
chroot /mnt/rootdisk grub-install "$LDEV"
chroot /mnt/rootdisk update-grub

# Fix GRUB config for serial console
chroot /mnt/rootdisk sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="console=ttyS0,115200n8 nokaslr"/' /etc/default/grub
chroot /mnt/rootdisk sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT=""/' /etc/default/grub
chroot /mnt/rootdisk update-grub

# Cleanup
umount /mnt/rootdisk/dev
umount /mnt/rootdisk/proc
umount /mnt/rootdisk/sys
umount /mnt/rootdisk
losetup -d "$LDEV"

echo ""
echo "USB image built: $(ls -lh "$USBIMG")"
echo ""
echo "Test with:"
echo "  qemu-system-x86_64 -m 4G -vga virtio -vnc :0 -drive file=$USBIMG,format=raw,if=virtio"

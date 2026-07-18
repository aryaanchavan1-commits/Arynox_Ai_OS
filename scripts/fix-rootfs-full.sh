#!/bin/bash
set -euo pipefail
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"

echo "Mounting root.img..."
LDEV=$(losetup -f --show -P "$PROJECT/build/root.img")
sleep 1
mount "${LDEV}p1" /mnt/rootdisk 2>/dev/null || mount "$LDEV" /mnt/rootdisk

echo "Checking kernel packages..."
mount --bind /dev /mnt/rootdisk/dev
mount --bind /proc /mnt/rootdisk/proc
mount --bind /sys /mnt/rootdisk/sys

echo "Installing kernel..."
chroot /mnt/rootdisk apt-get install -y linux-image-generic 2>&1 | tail -5

echo "Kernel files after install:"
ls -la /mnt/rootdisk/boot/

echo "Generating initramfs..."
chroot /mnt/rootdisk update-initramfs -u -k all 2>&1 | tail -3

echo "Updating GRUB..."
chroot /mnt/rootdisk update-grub 2>&1 | tail -5

echo "=== /boot after fix ==="
ls -lh /mnt/rootdisk/boot/

umount /mnt/rootdisk/dev
umount /mnt/rootdisk/proc
umount /mnt/rootdisk/sys
umount /mnt/rootdisk
losetup -d "$LDEV"
echo "root.img fixed!"

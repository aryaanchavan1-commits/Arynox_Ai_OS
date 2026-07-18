#!/bin/bash
set -euo pipefail
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"

echo "Mounting root.img..."
LDEV=$(losetup -f --show -P "$PROJECT/build/root.img")
sleep 1
mount "${LDEV}p1" /mnt/rootdisk 2>/dev/null || mount "$LDEV" /mnt/rootdisk

mount --bind /dev /mnt/rootdisk/dev
mount --bind /proc /mnt/rootdisk/proc
mount --bind /sys /mnt/rootdisk/sys
cp /etc/resolv.conf /mnt/rootdisk/etc/resolv.conf 2>/dev/null || true

echo "Cleaning apt..."
rm -rf /mnt/rootdisk/var/lib/apt/lists/*
rm -rf /mnt/rootdisk/var/cache/apt/archives/*.deb

echo "Updating apt..."
chroot /mnt/rootdisk apt-get clean 2>&1
chroot /mnt/rootdisk apt-get update -qq 2>&1 | tail -5

echo "Installing grub-pc and initramfs-tools..."
chroot /mnt/rootdisk apt-get install -y -qq grub-pc initramfs-tools 2>&1 | tail -5

# Generate initramfs
KERNEL_VER=$(chroot /mnt/rootdisk ls /boot/vmlinuz-* 2>/dev/null | head -1 | sed 's/.*vmlinuz-//')
echo "Kernel version: $KERNEL_VER"
if [ -n "$KERNEL_VER" ]; then
  chroot /mnt/rootdisk update-initramfs -c -k "$KERNEL_VER" 2>&1 | tail -3
fi

echo "Installing GRUB..."
chroot /mnt/rootdisk grub-install "$LDEV" 2>&1
chroot /mnt/rootdisk update-grub 2>&1

echo "=== Final /boot ==="
ls -lh /mnt/rootdisk/boot/
echo "=== GRUB menu entries ==="
grep -A5 'menuentry\|linux\|initrd' /mnt/rootdisk/boot/grub/grub.cfg 2>/dev/null | head -25

umount /mnt/rootdisk/dev
umount /mnt/rootdisk/proc
umount /mnt/rootdisk/sys
rm -f /mnt/rootdisk/etc/resolv.conf
umount /mnt/rootdisk
losetup -d "$LDEV"
echo "root.img fully fixed!"

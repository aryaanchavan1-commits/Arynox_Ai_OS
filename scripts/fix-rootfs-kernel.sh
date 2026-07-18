#!/bin/bash
set -euo pipefail
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"

echo "Mounting root.img..."
LDEV=$(losetup -f --show -P "$PROJECT/build/root.img")
sleep 1
mount "${LDEV}p1" /mnt/rootdisk 2>/dev/null || mount "$LDEV" /mnt/rootdisk

echo "Free space:"
df -h /mnt/rootdisk

# Copy vmlinuz from ISO boot (the working kernel)
echo "Copying kernel from ISO boot..."
mkdir -p /mnt/rootdisk/boot
cp -v "$PROJECT/build/iso/boot/vmlinuz-arynox" /mnt/rootdisk/boot/
cp -v "$PROJECT/build/iso/boot/initramfs.img" /mnt/rootdisk/boot/

# Also copy from build directory
ls -la "$PROJECT/build/vmlinuz-arynox" 2>/dev/null
ls -la "$PROJECT/build/initramfs.img" 2>/dev/null

# Rename properly
cd /mnt/rootdisk/boot
ln -sf vmlinuz-arynox vmlinuz 2>/dev/null || true
ls -lh /mnt/rootdisk/boot/

# Create /etc/default/grub
mkdir -p /mnt/rootdisk/etc/default
cat > /mnt/rootdisk/etc/default/grub << 'GRUBEOF'
GRUB_DEFAULT=0
GRUB_TIMEOUT=3
GRUB_CMDLINE_LINUX_DEFAULT=""
GRUB_CMDLINE_LINUX="console=ttyS0,115200n8 nokaslr"
GRUB_TERMINAL=console
GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"
GRUB_DISABLE_OS_PROBER=true
GRUB_DISABLE_RECOVERY=true
GRUBEOF

# Mount chroot and update GRUB
mount --bind /dev /mnt/rootdisk/dev
mount --bind /proc /mnt/rootdisk/proc
mount --bind /sys /mnt/rootdisk/sys

echo "Updating initramfs..."
chroot /mnt/rootdisk dracut --force /boot/initramfs.img 6.6.87-arynox 2>&1 | tail -3 || true

echo "Running update-grub..."
chroot /mnt/rootdisk update-grub 2>&1

echo "=== Updated /boot ==="
ls -lh /mnt/rootdisk/boot/

echo "=== grub.cfg kernel entries ==="
grep -A3 'menuentry\|linux\|initrd' /mnt/rootdisk/boot/grub/grub.cfg | head -20

umount /mnt/rootdisk/dev
umount /mnt/rootdisk/proc
umount /mnt/rootdisk/sys
umount /mnt/rootdisk
losetup -d "$LDEV"
echo "root.img kernel fix complete!"

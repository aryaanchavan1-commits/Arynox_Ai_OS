#!/bin/bash
set -euo pipefail
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"
USBIMG="$PROJECT/build/arynox-usb.img"

echo "Mounting USB image..."
LDEV=$(losetup -f --show -P "$USBIMG")
sleep 1
mount "${LDEV}p1" /mnt/rootdisk

# Reduce systemd timeout
echo "DefaultTimeoutStartSec=30s" >> /mnt/rootdisk/etc/systemd/system.conf

# Mask polkit (slow)
ln -sf /dev/null /mnt/rootdisk/etc/systemd/system/polkit.service 2>/dev/null || true

# Update grub.cfg with fast boot parameters
cat > /mnt/rootdisk/boot/grub/grub.cfg << 'GRUBEOF'
serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1
terminal_input serial
terminal_output serial
set default="0"
set timeout=3

menuentry "Arynox OS v0.1.0" {
  insmod ext2
  set root=(hd0,msdos1)
  linux /boot/vmlinuz-arynox root=/dev/vda1 rw console=ttyS0,115200n8 nokaslr apparmor=0 systemd.default_timeout_start_sec=30
}

menuentry "Arynox OS (Single User)" {
  insmod ext2
  set root=(hd0,msdos1)
  linux /boot/vmlinuz-arynox root=/dev/vda1 rw console=ttyS0,115200n8 nokaslr apparmor=0 single
}
GRUBEOF

# Fix root.img too
echo "Fixing root.img..."
mkdir -p /mnt/rootdisk2
LDEV2=$(losetup -f --show -P "$PROJECT/build/root.img")
sleep 1
mount "${LDEV2}p1" /mnt/rootdisk2 2>/dev/null || mount "$LDEV2" /mnt/rootdisk2
echo "DefaultTimeoutStartSec=30s" >> /mnt/rootdisk2/etc/systemd/system.conf
ln -sf /dev/null /mnt/rootdisk2/etc/systemd/system/apparmor.service 2>/dev/null || true
ln -sf /dev/null /mnt/rootdisk2/etc/systemd/system/polkit.service 2>/dev/null || true
umount /mnt/rootdisk2
losetup -d "$LDEV2"
rmdir /mnt/rootdisk2

echo "=== grub.cfg (USB) ==="
cat /mnt/rootdisk/boot/grub/grub.cfg

umount /mnt/rootdisk
losetup -d "$LDEV"
echo "Done!"

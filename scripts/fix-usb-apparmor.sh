#!/bin/bash
set -euo pipefail
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"
USBIMG="$PROJECT/build/arynox-usb.img"

echo "Mounting USB image..."
LDEV=$(losetup -f --show -P "$USBIMG")
sleep 1
mount "${LDEV}p1" /mnt/rootdisk

# Disable apparmor service
echo "Disabling apparmor.service..."
rm -f /mnt/rootdisk/etc/systemd/system/multi-user.target.wants/apparmor.service 2>/dev/null || true
rm -f /mnt/rootdisk/etc/systemd/system/sysinit.target.wants/apparmor.service 2>/dev/null || true
ln -sf /dev/null /mnt/rootdisk/etc/systemd/system/apparmor.service

# Also disable snapd if it exists (another common blocker)
rm -f /mnt/rootdisk/etc/systemd/system/multi-user.target.wants/snapd.service 2>/dev/null || true
ln -sf /dev/null /mnt/rootdisk/etc/systemd/system/snapd.service 2>/dev/null || true

# Update grub.cfg with apparmor=0
cat > /mnt/rootdisk/boot/grub/grub.cfg << 'GRUBEOF'
serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1
terminal_input serial
terminal_output serial
set default="0"
set timeout=3

menuentry "Arynox OS v0.1.0" {
  insmod ext2
  set root=(hd0,msdos1)
  linux /boot/vmlinuz-arynox root=/dev/vda1 rw console=ttyS0,115200n8 nokaslr apparmor=0
}

menuentry "Arynox OS (via PARTUUID)" {
  insmod ext2
  set root=(hd0,msdos1)
  linux /boot/vmlinuz-arynox root=PARTUUID=42cd4a3e-01 rw console=ttyS0,115200n8 nokaslr apparmor=0
}

menuentry "Arynox OS (Single User)" {
  insmod ext2
  set root=(hd0,msdos1)
  linux /boot/vmlinuz-arynox root=/dev/vda1 rw console=ttyS0,115200n8 nokaslr apparmor=0 single
}
GRUBEOF

echo "=== grub.cfg ==="
cat /mnt/rootdisk/boot/grub/grub.cfg
echo "=== Apparmor status ==="
ls -la /mnt/rootdisk/etc/systemd/system/apparmor.service 2>/dev/null

umount /mnt/rootdisk
losetup -d "$LDEV"
echo "Apparmor disabled!"

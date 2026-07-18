#!/bin/bash
set -euo pipefail
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"
USBIMG="$PROJECT/build/arynox-usb.img"

echo "Mounting USB image..."
LDEV=$(losetup -f --show -P "$USBIMG")
sleep 1
mount "${LDEV}p1" /mnt/rootdisk

# Use the custom kernel (has ext4) but update grub.cfg to not use initrd
cat > /mnt/rootdisk/boot/grub/grub.cfg << 'GRUBEOF'
serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1
terminal_input serial
terminal_output serial
set default="0"
set timeout=3

menuentry "Arynox OS v0.1.0 (Linux 6.6.87-arynox)" {
  insmod ext2
  set root=(hd0,msdos1)
  linux /boot/vmlinuz-arynox root=/dev/sda1 rw console=ttyS0,115200n8 nokaslr
}

menuentry "Arynox OS (Single User Mode)" {
  insmod ext2
  set root=(hd0,msdos1)
  linux /boot/vmlinuz-arynox root=/dev/sda1 rw console=ttyS0,115200n8 nokaslr single
}
GRUBEOF

echo "=== grub.cfg ==="
cat /mnt/rootdisk/boot/grub/grub.cfg

# Check what kernel we have
echo "=== /boot files ==="
ls -lh /mnt/rootdisk/boot/

umount /mnt/rootdisk
losetup -d "$LDEV"
echo "USB image updated!"

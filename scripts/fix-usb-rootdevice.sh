#!/bin/bash
set -euo pipefail
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"
USBIMG="$PROJECT/build/arynox-usb.img"

echo "Mounting USB image..."
LDEV=$(losetup -f --show -P "$USBIMG")
sleep 1
mount "${LDEV}p1" /mnt/rootdisk

# Get PARTUUID for the partition
BLKID=$(blkid "${LDEV}p1" | grep -o 'PARTUUID="[^"]*"' | head -1)
UUID=$(blkid "${LDEV}p1" | grep -o 'UUID="[^"]*"' | head -1)
echo "Partition: PARTUUID=$BLKID UUID=$UUID"

cat > /mnt/rootdisk/boot/grub/grub.cfg << 'GRUBEOF'
serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1
terminal_input serial
terminal_output serial
set default="0"
set timeout=3

menuentry "Arynox OS v0.1.0 (Ubuntu 7.0.0-14-generic)" {
  insmod ext2
  set root=(hd0,msdos1)
  linux /boot/vmlinuz-arynox root=/dev/vda1 rw console=ttyS0,115200n8 nokaslr
}

menuentry "Arynox OS (via PARTUUID)" {
  insmod ext2
  set root=(hd0,msdos1)
  linux /boot/vmlinuz-arynox root=PARTUUID=42cd4a3e-01 rw console=ttyS0,115200n8 nokaslr
}

menuentry "Arynox OS (Single User)" {
  insmod ext2
  set root=(hd0,msdos1)
  linux /boot/vmlinuz-arynox root=/dev/vda1 rw console=ttyS0,115200n8 nokaslr single
}
GRUBEOF

echo "=== grub.cfg ==="
cat /mnt/rootdisk/boot/grub/grub.cfg

umount /mnt/rootdisk
losetup -d "$LDEV"
echo "Root device fixed to /dev/vda1!"

#!/bin/bash
set -euo pipefail
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"
USBIMG="$PROJECT/build/arynox-usb.img"

echo "Mounting USB image..."
LDEV=$(losetup -f --show -P "$USBIMG")
sleep 1
mount "${LDEV}p1" /mnt/rootdisk

echo "Removing old custom kernel..."
rm -f /mnt/rootdisk/boot/vmlinuz-*

echo "Copying Ubuntu kernel (has all drivers built-in)..."
cp -v /boot/vmlinuz-7.0.0-14-generic /mnt/rootdisk/boot/
KERNEL_FILE="vmlinuz-7.0.0-14-generic"
echo "Using kernel: $KERNEL_FILE"

# Write clean grub.cfg with Ubuntu kernel, no initramfs needed
cat > /mnt/rootdisk/boot/grub/grub.cfg << 'GRUBEOF'
serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1
terminal_input serial
terminal_output serial
set default="0"
set timeout=3

menuentry "Arynox OS v0.1.0 (Ubuntu 7.0.0-14-generic)" {
  insmod ext2
  set root=(hd0,msdos1)
  linux /boot/vmlinuz-7.0.0-14-generic root=/dev/sda1 rw console=ttyS0,115200n8 nokaslr
}

menuentry "Arynox OS (Single User Mode)" {
  insmod ext2
  set root=(hd0,msdos1)
  linux /boot/vmlinuz-7.0.0-14-generic root=/dev/sda1 rw console=ttyS0,115200n8 nokaslr single
}
GRUBEOF

echo "=== Fixed /boot ==="
ls -lh /mnt/rootdisk/boot/

umount /mnt/rootdisk
losetup -d "$LDEV"
echo "USB image updated with Ubuntu kernel!"
echo "Size: $(ls -lh "$USBIMG" | awk '{print $5}')"

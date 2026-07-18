#!/bin/bash
set -euo pipefail
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"
USBIMG="$PROJECT/build/arynox-usb.img"

echo "Mounting existing USB image..."

LDEV=$(losetup -f --show -P "$USBIMG")
sleep 1
mount "${LDEV}p1" /mnt/rootdisk

echo "Copying kernel files..."
mkdir -p /mnt/rootdisk/boot/grub
cp -v "$PROJECT/build/iso/boot/vmlinuz-arynox" /mnt/rootdisk/boot/
cp -v "$PROJECT/build/iso/boot/initramfs.img" /mnt/rootdisk/boot/

echo "Writing GRUB config..."
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
  initrd /boot/initramfs.img
}

menuentry "Arynox OS (Safe Mode)" {
  insmod ext2
  set root=(hd0,msdos1)
  linux /boot/vmlinuz-arynox root=/dev/sda1 rw console=ttyS0,115200n8 nokaslr single
  initrd /boot/initramfs.img
}
GRUBEOF

# Create /etc/default/grub for future update-grub
mkdir -p /mnt/rootdisk/etc/default
cat > /mnt/rootdisk/etc/default/grub << 'GRUBDEFAULT'
GRUB_DEFAULT=0
GRUB_TIMEOUT=3
GRUB_CMDLINE_LINUX_DEFAULT=""
GRUB_CMDLINE_LINUX="console=ttyS0,115200n8 nokaslr"
GRUB_TERMINAL=serial
GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"
GRUB_DISABLE_OS_PROBER=true
GRUB_DISABLE_RECOVERY=true
GRUBDEFAULT

echo "=== Fixed /boot ==="
ls -lh /mnt/rootdisk/boot/
echo "=== Fixed grub.cfg ==="
cat /mnt/rootdisk/boot/grub/grub.cfg

umount /mnt/rootdisk
losetup -d "$LDEV"

echo ""
echo "USB image fixed! Size: $(ls -lh "$USBIMG" | awk '{print $5}')"

#!/bin/bash
set -euo pipefail
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"

LDEV=$(losetup -f --show -P "$PROJECT/build/arynox-usb.img")
sleep 1
mount "${LDEV}p1" /mnt/rootdisk
echo "BOOT_CONTENT:"
ls -la /mnt/rootdisk/boot/
echo "MODULES_DIR:"
find /mnt/rootdisk/lib/modules -maxdepth 1 -type d 2>/dev/null
echo "HOST_KERNEL: $(uname -r)"
rm -f /mnt/rootdisk/boot/vmlinuz-*
cp -v /boot/vmlinuz-7.0.0-14-generic /mnt/rootdisk/boot/vmlinuz-7.0.0-14-generic 2>&1 || echo "HOST_COPY_FAILED"
ls -la /mnt/rootdisk/boot/
umount /mnt/rootdisk
losetup -d "$LDEV"
echo DONE

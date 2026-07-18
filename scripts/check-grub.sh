#!/bin/bash
set -euo pipefail
LDEV=$(losetup -f --show -P /mnt/d/Arynoxtech/ArynoxOS/build/arynox-usb.img)
sleep 1
mount "${LDEV}p1" /mnt/rootdisk
echo "=== FULL GRUB CFG ==="
cat /mnt/rootdisk/boot/grub/grub.cfg
echo "=== /boot ==="
ls -la /mnt/rootdisk/boot/
echo "=== vmlinuz ==="
find /mnt/rootdisk/boot -name 'vmlinuz*' -o -name 'initr*' 2>/dev/null
umount /mnt/rootdisk
losetup -d "$LDEV"

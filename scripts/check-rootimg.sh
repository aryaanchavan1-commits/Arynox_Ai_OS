#!/bin/bash
set -euo pipefail
LDEV=$(losetup -f --show -P /mnt/d/Arynoxtech/ArynoxOS/build/root.img)
sleep 1
mount "${LDEV}p1" /mnt/rootdisk 2>/dev/null || mount "$LDEV" /mnt/rootdisk
echo "=== root.img /boot ==="
ls -la /mnt/rootdisk/boot/ 2>/dev/null
echo "=== root.img vmlinuz ==="
find /mnt/rootdisk/boot -name 'vmlinuz*' -o -name 'initr*' 2>/dev/null
echo "=== root.img etc/default/grub ==="
cat /mnt/rootdisk/etc/default/grub 2>/dev/null || echo "(none)"
umount /mnt/rootdisk
losetup -d "$LDEV"

#!/bin/bash
set -euo pipefail
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"
USBIMG="$PROJECT/build/arynox-usb.img"

echo "Mounting USB image..."

LDEV=$(losetup -f --show -P "$USBIMG")
echo "Loop device: $LDEV"
sleep 1

mount "${LDEV}p1" /mnt/rootdisk
echo "Mounted at /mnt/rootdisk"

# Check current state
echo "=== Current /etc/default/grub ==="
cat /mnt/rootdisk/etc/default/grub 2>/dev/null || echo "(file does not exist)"

echo "=== /boot contents ==="
ls -lh /mnt/rootdisk/boot/ 2>/dev/null | head -10

echo "=== /boot/grub/grub.cfg first 20 lines ==="
head -20 /mnt/rootdisk/boot/grub/grub.cfg 2>/dev/null || echo "(no grub.cfg)"

# Create proper GRUB default config
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
echo "Created /etc/default/grub"

# Mount chroot filesystems and update GRUB
mount --bind /dev /mnt/rootdisk/dev
mount --bind /proc /mnt/rootdisk/proc
mount --bind /sys /mnt/rootdisk/sys

echo "Running update-grub..."
chroot /mnt/rootdisk update-grub 2>&1

echo "Reinstalling GRUB to MBR..."
chroot /mnt/rootdisk grub-install "$LDEV" 2>&1

# Verify grub.cfg
echo "=== Updated grub.cfg ==="
head -25 /mnt/rootdisk/boot/grub/grub.cfg

# Cleanup
umount /mnt/rootdisk/dev
umount /mnt/rootdisk/proc
umount /mnt/rootdisk/sys
umount /mnt/rootdisk
losetup -d "$LDEV"

echo ""
echo "USB image GRUB fix complete!"

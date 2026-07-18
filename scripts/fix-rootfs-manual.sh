#!/bin/bash
set -euo pipefail
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"

echo "Mounting root.img..."
LDEV=$(losetup -f --show -P "$PROJECT/build/root.img")
sleep 1
mount "${LDEV}p1" /mnt/rootdisk 2>/dev/null || mount "$LDEV" /mnt/rootdisk

# Copy kernel and initramfs from build directory
echo "Copying kernel files..."
mkdir -p /mnt/rootdisk/boot
cp -v "$PROJECT/build/iso/boot/vmlinuz-arynox" /mnt/rootdisk/boot/
cp -v "$PROJECT/build/iso/boot/initramfs.img" /mnt/rootdisk/boot/

# Create GRUB directory and write manual grub.cfg
mkdir -p /mnt/rootdisk/boot/grub
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
echo "GRUB config written"

# Create /etc/default/grub for reference
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

# Verify
echo "=== /boot contents ==="
ls -lh /mnt/rootdisk/boot/
echo "=== grub.cfg ==="
cat /mnt/rootdisk/boot/grub/grub.cfg

# Now rebuild the USB image
echo ""
echo "Rebuilding USB image from fixed rootfs..."

mount --bind /dev /mnt/rootdisk/dev
mount --bind /proc /mnt/rootdisk/proc
mount --bind /sys /mnt/rootdisk/sys

# Reinstall GRUB to MBR of root.img (just in case)
chroot /mnt/rootdisk grub-install /dev/loop2 2>&1 || true

echo "Creating new squashfs..."
mksquashfs /mnt/rootdisk "$PROJECT/build/filesystem.squashfs" -comp xz -b 1M 2>&1 | tail -3

umount /mnt/rootdisk/dev
umount /mnt/rootdisk/proc
umount /mnt/rootdisk/sys
umount /mnt/rootdisk
losetup -d "$LDEV"

echo ""
echo "=== Creating new USB image ==="
USBIMG="$PROJECT/build/arynox-usb.img"
rm -f "$USBIMG"
dd if=/dev/zero of="$USBIMG" bs=1M count=6144 status=progress
parted -s "$USBIMG" mklabel msdos mkpart primary ext4 1MiB 100% set 1 boot on

LDEV2=$(losetup -f --show -P "$USBIMG")
sleep 1
mkfs.ext4 -F "${LDEV2}p1"
mount "${LDEV2}p1" /mnt/rootdisk

echo "Unsquashing fixed rootfs..."
unsquashfs -f -d /mnt/rootdisk "$PROJECT/build/filesystem.squashfs" 2>&1 | tail -3

echo "Installing GRUB on USB image..."
mount --bind /dev /mnt/rootdisk/dev
mount --bind /proc /mnt/rootdisk/proc
mount --bind /sys /mnt/rootdisk/sys
chroot /mnt/rootdisk grub-install "$LDEV2" 2>&1

umount /mnt/rootdisk/dev
umount /mnt/rootdisk/proc
umount /mnt/rootdisk/sys
umount /mnt/rootdisk
losetup -d "$LDEV2"

echo ""
echo "USB image rebuilt: $(ls -lh "$USBIMG")"

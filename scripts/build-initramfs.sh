#!/bin/bash
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"
DIR="/tmp/arynox-initramfs"
rm -rf "$DIR" "$PROJECT/build/initramfs"
mkdir -p "$DIR/bin" "$DIR/dev" "$DIR/etc" "$DIR/mnt/root" "$DIR/proc" "$DIR/run" "$DIR/sbin" "$DIR/sys" "$DIR/tmp" "$DIR/cdrom" "$DIR/lib" "$DIR/lib64"
cp /bin/busybox "$DIR/bin/"
cd "$DIR/bin"
for c in sh mount umount grep ls cat echo mkdir mknod switch_root poweroff reboot sleep modprobe dmesg clear; do
    ln -sf busybox "$c"
done
# Copy full mount binary with libraries for CD-ROM/ISO9660 support
cp /bin/mount "$DIR/bin/mount-full"
for lib in libmount.so.1 libselinux.so.1 libblkid.so.1 libpcre2-8.so.0 libc.so.6; do
    cp -Lv /usr/lib/x86_64-linux-gnu/$lib "$DIR/lib/"
done
cp -Lv /lib64/ld-linux-x86-64.so.2 "$DIR/lib64/" 2>&1
cd "$DIR"
cat > init << 'INITEOF'
#!/bin/sh
export LD_LIBRARY_PATH=/lib:/lib64
/bin/mount -t proc proc /proc
/bin/mount -t sysfs sysfs /sys
/bin/mount -t devtmpfs devtmpfs /dev
/bin/mount -t tmpfs tmpfs /run
/sbin/modprobe squashfs 2>/dev/null || true
/sbin/modprobe overlay 2>/dev/null || true
/sbin/modprobe isofs 2>/dev/null || true
/sbin/modprobe cdrom 2>/dev/null || true
/bin/mknod /dev/sr0 b 11 0 2>/dev/null || true
/bin/mknod /dev/loop0 b 7 0 2>/dev/null || true
echo ""
echo "  Arynox OS v0.1.0  |  Created by Aryan Chavan  |  (C) 2026"
echo "  AI-Native Operating System - Loading..."
echo ""
/bin/sleep 1
MOUNT=/bin/mount-full
CD_MOUNTED=0
for dev in /dev/sr0 /dev/sr1; do
    if [ -b "$dev" ]; then
        echo "Trying $MOUNT $dev..."
        $MOUNT -t iso9660 -o ro "$dev" /cdrom 2>&1 && CD_MOUNTED=1 && break
    fi
done
if [ "$CD_MOUNTED" != "1" ]; then
    for dev in /dev/sd* /dev/vd* /dev/xvd*; do
        [ -b "$dev" ] || continue
        echo "Trying $MOUNT $dev..."
        $MOUNT -t iso9660 -o ro "$dev" /cdrom 2>&1 && CD_MOUNTED=1 && break
    done
fi
if [ "$CD_MOUNTED" != "1" ]; then
    echo "ERROR: Could not find boot CD-ROM"
    echo "Available devices:"
    /bin/ls -la /dev/sd* /dev/sr* /dev/vd* /dev/hd* 2>/dev/null || true
    echo "Dropping to emergency shell..."
    exec /bin/sh
fi
echo "Found boot media, mounting root filesystem..."
$MOUNT -t squashfs -o ro /cdrom/live/filesystem.squashfs /mnt/root 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR: Could not mount filesystem.squashfs"
    /bin/ls -la /cdrom/live/ 2>/dev/null || true
    exec /bin/sh
fi
$MOUNT -t tmpfs -o mode=0755 tmpfs /mnt/root/run 2>&1
/bin/mkdir -p /mnt/root/tmp /mnt/root/var/tmp
$MOUNT -t tmpfs -o mode=1777 tmpfs /mnt/root/tmp 2>&1
$MOUNT -t tmpfs -o mode=1777 tmpfs /mnt/root/var/tmp 2>&1
$MOUNT -t devtmpfs devtmpfs /mnt/root/dev 2>&1
echo "Switching to systemd root..."
exec /sbin/switch_root /mnt/root /sbin/init
INITEOF
chmod +x init
find . | cpio -H newc -o 2>/dev/null | gzip -9 > "$PROJECT/build/initramfs.img"
echo "Initramfs: $(ls -lh $PROJECT/build/initramfs.img | awk '{print $5}')"

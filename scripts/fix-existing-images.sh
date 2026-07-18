#!/bin/bash
set -euo pipefail
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"

fix_image() {
    local img="$1"
    local IMG="$PROJECT/build/$img"
    [ -f "$IMG" ] || { echo "  Skipping $img - not found"; return; }
    
    echo "Fixing $img..."
    local LDEV
    LDEV=$(losetup -f --show -P "$IMG")
    sleep 1
    mount "${LDEV}p1" /mnt/rootdisk 2>/dev/null || mount "$LDEV" /mnt/rootdisk
    
    # Fix Weston
    if [ -f /mnt/rootdisk/etc/systemd/system/weston.service ]; then
        sed -i 's/Restart=on-failure/Restart=no/' /mnt/rootdisk/etc/systemd/system/weston.service
    fi
    
    # systemd timeout
    if ! grep -q "DefaultTimeoutStartSec" /mnt/rootdisk/etc/systemd/system.conf 2>/dev/null; then
        echo "DefaultTimeoutStartSec=30s" >> /mnt/rootdisk/etc/systemd/system.conf
    fi
    
    # Disable apparmor
    ln -sf /dev/null /mnt/rootdisk/etc/systemd/system/apparmor.service 2>/dev/null || true
    
    # Copy kernel if missing
    if [ -z "$(ls /mnt/rootdisk/boot/vmlinuz-* 2>/dev/null)" ]; then
        for k in /boot/vmlinuz-* "$PROJECT/build/vmlinuz-arynox" "$PROJECT/build/iso/boot/vmlinuz-arynox"; do
            if [ -f "$k" ]; then
                cp "$k" /mnt/rootdisk/boot/
                break
            fi
        done
    fi
    
    # Get kernel filename
    local kf
    kf=$(ls /mnt/rootdisk/boot/vmlinuz-* 2>/dev/null | head -1 | xargs basename 2>/dev/null || echo "vmlinuz-7.0.0-14-generic")
    
    # Write grub.cfg (avoid heredoc issues with echo)
    {
        echo 'serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1'
        echo 'terminal_input serial'
        echo 'terminal_output serial'
        echo 'set default="0"'
        echo 'set timeout=3'
        echo ''
        echo 'menuentry "Arynox OS v0.1.0" {'
        echo '  insmod ext2'
        echo '  set root=(hd0,msdos1)'
        echo "  linux /boot/$kf root=/dev/vda1 rw console=ttyS0,115200n8 nokaslr apparmor=0 systemd.default_timeout_start_sec=30"
        echo '}'
        echo ''
        echo 'menuentry "Arynox OS (Single User)" {'
        echo '  insmod ext2'
        echo '  set root=(hd0,msdos1)'
        echo "  linux /boot/$kf root=/dev/vda1 rw console=ttyS0,115200n8 nokaslr apparmor=0 single"
        echo '}'
    } > /mnt/rootdisk/boot/grub/grub.cfg
    
    echo "  Fixed: $kf"
    
    umount /mnt/rootdisk
    losetup -d "$LDEV"
    echo "  Done: $img"
}

fix_image "root.img"
fix_image "arynox-usb.img"
echo "All images fixed!"

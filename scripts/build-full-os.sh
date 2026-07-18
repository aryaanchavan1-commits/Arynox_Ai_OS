#!/bin/bash
set -euo pipefail
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"
RELEASE="resolute"
export DEBIAN_FRONTEND=noninteractive
export LANG=C

echo "=========================================="
echo "  Arynox OS Full Build - Complete Desktop"
echo "  Created by Aryan Chavan"
echo "=========================================="

echo "[1/9] Ensuring build tools..."
apt-get update -qq 2>/dev/null
apt-get install -y -qq debootstrap squashfs-tools xorriso grub-pc mtools linux-image-generic 2>&1 | tail -1

echo "[2/9] Creating root filesystem with debootstrap..."
ROOTFS="/tmp/arynox-rootfs"
umount -R "$ROOTFS" 2>/dev/null || true
rm -rf "$ROOTFS" "$PROJECT/build/rootfs" 2>/dev/null || true
debootstrap --arch=amd64 --include=systemd,systemd-sysv,udev,dbus "$RELEASE" "$ROOTFS" http://archive.ubuntu.com/ubuntu/ 2>&1 | tail -3
echo "  Base rootfs: $(du -sh $ROOTFS | cut -f1)"

echo "[3/9] Configuring root filesystem..."
mount --bind /dev "$ROOTFS/dev" 2>/dev/null || true
mount --bind /proc "$ROOTFS/proc" 2>/dev/null || true
mount --bind /sys "$ROOTFS/sys" 2>/dev/null || true

chroot "$ROOTFS" sed -i 's/^Types: deb$/Types: deb\nComponents: main universe restricted multiverse/' /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null || \
chroot "$ROOTFS" bash -c 'echo "deb http://archive.ubuntu.com/ubuntu resolute main universe" >> /etc/apt/sources.list'
chroot "$ROOTFS" apt-get update -qq

chroot "$ROOTFS" apt-get install -y -qq \
    linux-image-generic initramfs-tools \
    openssh-server sudo bash-completion \
    curl wget ca-certificates vim-tiny nano git rsyslog \
    weston foot fontconfig xwayland libgl1-mesa-dri mesa-utils \
    network-manager modemmanager wpasupplicant \
    pipewire pipewire-pulse wireplumber \
    python3 python3-pip python3-requests \
    pciutils usbutils parted dosfstools ufw grub-pc \
    2>&1 | tail -3

echo "arynox" > "$ROOTFS/etc/hostname"
cat > "$ROOTFS/etc/hosts" << 'EOF'
127.0.0.1 localhost
127.0.1.1 arynox
::1 localhost ip6-localhost ip6-loopback
EOF

cat > "$ROOTFS/etc/os-release" << 'EOF'
NAME="Arynox OS"
ID=arynox
PRETTY_NAME="Arynox OS 0.1.0 (2026)"
VERSION_ID="0.1.0"
HOME_URL="https://github.com/aryaanchavan1-commits/Arynox_Ai_OS"
SUPPORT_URL="https://github.com/aryaanchavan1-commits/Arynox_Ai_OS"
EOF

chroot "$ROOTFS" /usr/sbin/useradd -m -s /bin/bash arynox 2>/dev/null || true
echo "arynox:arynox" | chroot "$ROOTFS" /usr/sbin/chpasswd
echo "arynox ALL=(ALL) NOPASSWD:ALL" > "$ROOTFS/etc/sudoers.d/arynox"

mkdir -p "$ROOTFS/etc/systemd/system/getty@tty1.service.d"
cat > "$ROOTFS/etc/systemd/system/getty@tty1.service.d/autologin.conf" << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin arynox --noclear %I $TERM
EOF

# Weston service with no restart on GPU-less failure
cat > "$ROOTFS/etc/systemd/system/weston.service" << 'EOF'
[Unit]
Description=Weston Wayland Compositor
Requires=systemd-logind.service
After=systemd-logind.service

[Service]
Type=simple
User=arynox
Environment=XDG_RUNTIME_DIR=/run/user/1000
ExecStartPre=/bin/mkdir -p /run/user/1000
ExecStartPre=/bin/chown arynox:arynox /run/user/1000
ExecStart=/usr/bin/weston --tty=1
Restart=no

[Install]
WantedBy=graphical.target
EOF
mkdir -p "$ROOTFS/etc/systemd/system/graphical.target.wants"
ln -sf /etc/systemd/system/weston.service "$ROOTFS/etc/systemd/system/graphical.target.wants/" 2>/dev/null || true

# GRUB default config for serial console
mkdir -p "$ROOTFS/etc/default"
cat > "$ROOTFS/etc/default/grub" << 'GRUBEOF'
GRUB_DEFAULT=0
GRUB_TIMEOUT=3
GRUB_CMDLINE_LINUX_DEFAULT=""
GRUB_CMDLINE_LINUX="console=ttyS0,115200n8 nokaslr apparmor=0 systemd.default_timeout_start_sec=30"
GRUB_TERMINAL=serial
GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"
GRUB_DISABLE_OS_PROBER=true
GRUB_DISABLE_RECOVERY=true
GRUBEOF

cat > "$ROOTFS/etc/netplan/01-netcfg.yaml" << 'EOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    all:
      match:
        name: en*
      dhcp4: true
  wifis:
    all:
      match:
        name: wl*
      dhcp4: true
      access-points: {}
EOF

chroot "$ROOTFS" ufw default deny incoming 2>/dev/null || true
chroot "$ROOTFS" ufw default allow outgoing 2>/dev/null || true
chroot "$ROOTFS" ufw allow ssh 2>/dev/null || true

chroot "$ROOTFS" apt-get install -y -qq firefox 2>&1 | tail -1 || true

echo "[4/9] Installing Arynox daemons..."
mkdir -p "$ROOTFS/usr/lib/arynox"
for bin in arynox-*; do
    src="$PROJECT/target/release/$bin"
    if [ -f "$src" ]; then
        cp "$src" "$ROOTFS/usr/lib/arynox/"
        chmod +x "$ROOTFS/usr/lib/arynox/$bin"
    fi
done

mkdir -p "$ROOTFS/etc/systemd/system"
cp "$PROJECT/src/boot/systemd/"*.service "$ROOTFS/etc/systemd/system/" 2>/dev/null || true
cp "$PROJECT/src/boot/systemd/"*.target "$ROOTFS/etc/systemd/system/" 2>/dev/null || true
for svc in "$PROJECT/src/boot/systemd/"*.service; do
    name=$(basename "$svc")
    chroot "$ROOTFS" systemctl enable "$name" 2>/dev/null || true
done

mkdir -p "$ROOTFS/etc/dbus-1/system.d"
cp "$PROJECT/src/boot/dbus/"*.conf "$ROOTFS/etc/dbus-1/system.d/" 2>/dev/null || true

echo "[5/9] Installing Flutter apps..."
for d in "$PROJECT/build/flutter-apps/"*/; do
    [ -d "$d" ] || continue
    app=$(basename "$d")
    mkdir -p "$ROOTFS/usr/share/arynox/$app"
    cp -r "$d"/* "$ROOTFS/usr/share/arynox/$app/"
done

cat > "$ROOTFS/usr/local/bin/launch-arynox-app" << 'EOF'
#!/bin/bash
APP_NAME="$1"
APP_DIR="/usr/share/arynox/$APP_NAME"
if [ -f "$APP_DIR/$APP_NAME" ]; then
    exec "$APP_DIR/$APP_NAME"
elif [ -f "$APP_DIR/bin/$APP_NAME" ]; then
    exec "$APP_DIR/bin/$APP_NAME"
else
    for f in "$APP_DIR"/*; do
        [ -x "$f" ] && [ ! -d "$f" ] && exec "$f" && break
    done
    echo "No executable found for $APP_NAME"
fi
EOF
chmod +x "$ROOTFS/usr/local/bin/launch-arynox-app"

echo "[6/9] Installing Python AI runtime..."
AI_DIR="$ROOTFS/usr/lib/arynox/ai-runtime"
mkdir -p "$AI_DIR"
cp -r "$PROJECT/ai-python/arynox_ai" "$AI_DIR/" 2>/dev/null || true
cp "$PROJECT/ai-python/pyproject.toml" "$AI_DIR/" 2>/dev/null || true
chroot "$ROOTFS" pip3 install --quiet wheel setuptools 2>/dev/null || true
chroot "$ROOTFS" pip3 install --quiet -e /usr/lib/arynox/ai-runtime 2>/dev/null || true

echo "[7/9] Creating AI first-boot download service..."
mkdir -p "$ROOTFS/usr/local/lib/arynox-ai"
cat > "$ROOTFS/usr/local/lib/arynox-ai/download-models.sh" << 'AISCRIPT'
#!/bin/bash
LOGFILE="/var/log/arynox-ai-download.log"
STATUSFILE="/var/lib/arynox-ai/download-complete"
MODEL_DIR="/usr/share/arynox/ai-models"
mkdir -p "$MODEL_DIR" /var/lib/arynox-ai
exec > "$LOGFILE" 2>&1
echo "=== Arynox AI Model Download ==="
echo "Started: $(date)"
echo "[1/4] Installing Ollama..."
if ! command -v ollama &>/dev/null; then
    curl -fsSL https://ollama.com/install.sh | bash 2>&1
fi
echo "[2/4] Downloading Qwen2.5 (3B)..."
ollama pull qwen2.5:3b 2>&1 || ollama pull qwen2.5 2>&1
echo "[3/4] Downloading Moondream2..."
ollama pull moondream2 2>&1 || echo "Moondream2 not on Ollama, deferring"
echo "[4/4] Downloading SmolVLM 500M..."
ollama pull smolvlm 2>&1 || echo "SmolVLM not on Ollama, deferring"
date > "$STATUSFILE"
echo "=== Download Complete: $(date) ==="
AISCRIPT
chmod +x "$ROOTFS/usr/local/lib/arynox-ai/download-models.sh"

mkdir -p "$ROOTFS/etc/systemd/system"
cat > "$ROOTFS/etc/systemd/system/arynox-ai-download.service" << 'EOF'
[Unit]
Description=Arynox AI Model Download (First Boot)
ConditionPathExists=!/var/lib/arynox-ai/download-complete
After=network-online.target
Wants=network-online.target
[Service]
Type=oneshot
ExecStart=/usr/local/lib/arynox-ai/download-models.sh
RemainAfterExit=yes
StandardOutput=journal+console
[Install]
WantedBy=multi-user.target
EOF
chroot "$ROOTFS" systemctl enable arynox-ai-download 2>/dev/null || true

cat > "$ROOTFS/etc/systemd/system/ollama.service" << 'EOF'
[Unit]
Description=Ollama AI Runtime
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/ollama serve
Restart=on-failure
User=arynox
Environment=OLLAMA_HOST=0.0.0.0
Environment=OLLAMA_KEEP_ALIVE=24h
[Install]
WantedBy=multi-user.target
EOF

echo "[8/9] Creating desktop environment..."
mkdir -p "$ROOTFS/home/arynox/.config"
cat > "$ROOTFS/home/arynox/.config/weston.ini" << 'WESTONINI'
[core]
shell=desktop-shell.so
xwayland=true
[shell]
panel-position=top
locking=false
animation=fade
background-color=0x1a1a2e
[launcher]
icon=/usr/share/icons/gnome/256x256/apps/utilities-terminal.png
path=/usr/bin/foot
[launcher]
icon=/usr/share/icons/gnome/256x256/apps/firefox.png
path=/usr/bin/firefox
[launcher]
icon=/usr/share/arynox/ai-hub/icon.png
path=/usr/local/bin/launch-arynox-app ai-hub
[launcher]
icon=/usr/share/arynox/ai-assistant/icon.png
path=/usr/local/bin/launch-arynox-app ai-assistant
[launcher]
icon=/usr/share/arynox/ai-copilot/icon.png
path=/usr/local/bin/launch-arynox-app ai-copilot
[output]
name=auto
mode=1920x1080@60
scale=1
WESTONINI
chown -R 1000:1000 "$ROOTFS/home/arynox/.config"

chroot "$ROOTFS" systemctl enable NetworkManager 2>/dev/null || true
chroot "$ROOTFS" systemctl enable systemd-networkd 2>/dev/null || true
chroot "$ROOTFS" systemctl enable systemd-resolved 2>/dev/null || true
chroot "$ROOTFS" systemctl enable ssh 2>/dev/null || true
chroot "$ROOTFS" systemctl enable pipewire 2>/dev/null || true
chroot "$ROOTFS" systemctl set-default graphical.target 2>/dev/null || true

# Set systemd timeout
echo "DefaultTimeoutStartSec=30s" >> "$ROOTFS/etc/systemd/system.conf"

umount -l "$ROOTFS/dev" 2>/dev/null || true
umount -l "$ROOTFS/proc" 2>/dev/null || true
umount -l "$ROOTFS/sys" 2>/dev/null || true

echo "[9/9] Building final images..."
mksquashfs "$ROOTFS" "$PROJECT/build/filesystem.squashfs" -comp zstd -b 1M -noappend -quiet 2>&1
echo "Squashfs: $(du -h $PROJECT/build/filesystem.squashfs | cut -f1)"

# Cleanup
rm -rf "$ROOTFS"

echo ""
echo "=========================================="
echo "  Arynox OS Build Complete!"
echo "  Files:"
ls -lh "$PROJECT/build/filesystem.squashfs"
echo "=========================================="

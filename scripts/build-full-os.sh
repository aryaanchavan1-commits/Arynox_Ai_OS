#!/bin/bash
set -uo pipefail
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"
RELEASE="resolute"
export DEBIAN_FRONTEND=noninteractive
export LANG=C

echo "=========================================="
echo "  Arynox OS Full Build - Complete Desktop"
echo "  Created by Aryan Chavan"
echo "=========================================="
echo ""

# Ensure tools
echo "[1/9] Ensuring build tools..."
apt-get update -qq 2>/dev/null
apt-get install -y -qq debootstrap squashfs-tools xorriso grub-pc-bin mtools 2>&1 | tail -1

# ---- STEP 1: Rootfs with debootstrap ----
echo "[2/9] Creating root filesystem with debootstrap..."
ROOTFS="/tmp/arynox-rootfs"

# Clean up any previous rootfs mounts
umount -R "$ROOTFS" 2>/dev/null || true
rm -rf "$ROOTFS" "$PROJECT/build/rootfs" 2>/dev/null || true

debootstrap --arch=amd64 "$RELEASE" "$ROOTFS" http://archive.ubuntu.com/ubuntu/ 2>&1 | tail -3
echo "  Rootfs size: $(du -sh $ROOTFS | cut -f1)"

echo "  Rootfs size: $(du -sh $ROOTFS | cut -f1)"

# ---- STEP 2: Configure rootfs ----
echo "[3/9] Configuring root filesystem..."

# Mount virtual filesystems for chroot
mount --bind /dev "$ROOTFS/dev" 2>/dev/null || true
mount --bind /proc "$ROOTFS/proc" 2>/dev/null || true
mount --bind /sys "$ROOTFS/sys" 2>/dev/null || true

# Enable universe repository for weston, foot, etc.
chroot "$ROOTFS" sed -i 's/^Types: deb$/Types: deb\nComponents: main universe restricted multiverse/' /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null || \
chroot "$ROOTFS" sed -i 's/main$/main universe/' /etc/apt/sources.list 2>/dev/null || \
chroot "$ROOTFS" bash -c 'echo "deb http://archive.ubuntu.com/ubuntu resolute main universe" >> /etc/apt/sources.list' 2>/dev/null || true
chroot "$ROOTFS" apt-get update -qq 2>/dev/null
chroot "$ROOTFS" apt-get install -y -qq \
    systemd systemd-sysv udev dbus dbus-x11 \
    openssh-server sudo bash-completion \
    curl wget ca-certificates \
    vim-tiny nano htop git rsyslog 2>&1 | tail -3

# Install desktop/display packages
chroot "$ROOTFS" apt-get install -y -qq \
    weston foot fontconfig \
    xwayland libgl1-mesa-dri mesa-utils 2>&1 | tail -3

# Install network packages
chroot "$ROOTFS" apt-get install -y -qq \
    network-manager modemmanager wpasupplicant rfkill 2>&1 | tail -3

# Install audio packages
chroot "$ROOTFS" apt-get install -y -qq \
    pipewire pipewire-pulse wireplumber 2>&1 | tail -3

# Install Python/AI packages
chroot "$ROOTFS" apt-get install -y -qq \
    python3 python3-pip python3-venv python3-requests python3-numpy 2>&1 | tail -3 || \
chroot "$ROOTFS" apt-get install -y -qq \
    python3 python3-requests 2>&1 | tail -1

# Install hardware utilities
chroot "$ROOTFS" apt-get install -y -qq \
    libinput10 libpam-systemd \
    pciutils usbutils parted dosfstools \
    ufw linux-firmware 2>&1 | tail -3

# Set hostname
echo "arynox" > "$ROOTFS/etc/hostname"
cat > "$ROOTFS/etc/hosts" << 'EOF'
127.0.0.1 localhost
127.0.1.1 arynox
::1 localhost ip6-localhost ip6-loopback
EOF

# Create OS release
cat > "$ROOTFS/etc/os-release" << 'EOF'
NAME="Arynox OS"
ID=arynox
PRETTY_NAME="Arynox OS 0.1.0 (2026)"
VERSION_ID="0.1.0"
HOME_URL="https://arynox.com"
SUPPORT_URL="https://github.com/aryaanchavan1-commits/Arynoxos"
EOF

# Create arynox user with auto-login
chroot "$ROOTFS" /usr/sbin/useradd -m -s /bin/bash arynox 2>/dev/null || true
echo "arynox:arynox" | chroot "$ROOTFS" /usr/sbin/chpasswd
echo "arynox ALL=(ALL) NOPASSWD:ALL" > "$ROOTFS/etc/sudoers.d/arynox"

# Enable auto-login for tty1 via getty override
mkdir -p "$ROOTFS/etc/systemd/system/getty@tty1.service.d"
cat > "$ROOTFS/etc/systemd/system/getty@tty1.service.d/autologin.conf" << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin arynox --noclear %I $TERM
EOF

# Configure Weston for auto-start
mkdir -p "$ROOTFS/etc/systemd/user"
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
Restart=on-failure

[Install]
WantedBy=graphical.target
EOF

mkdir -p "$ROOTFS/etc/systemd/system/graphical.target.wants"
ln -sf /etc/systemd/system/weston.service "$ROOTFS/etc/systemd/system/graphical.target.wants/" 2>/dev/null || true

# Configure network
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

# Firewall defaults
chroot "$ROOTFS" ufw default deny incoming 2>/dev/null || true
chroot "$ROOTFS" ufw default allow outgoing 2>/dev/null || true
chroot "$ROOTFS" ufw allow ssh 2>/dev/null || true
chroot "$ROOTFS" systemctl enable ufw 2>/dev/null || true

# Install browser (try multiple options)
chroot "$ROOTFS" apt-get install -y -qq firefox 2>&1 | tail -1 || \
    chroot "$ROOTFS" apt-get install -y -qq firefox-esr 2>&1 | tail -1 || \
    chroot "$ROOTFS" apt-get install -y -qq epiphany-browser 2>&1 | tail -1 || \
    chroot "$ROOTFS" apt-get install -y -qq w3m 2>&1 | tail -1 || true

# ---- STEP 3: Integrate Arynox daemons ----
echo "[4/9] Installing Arynox daemons..."

mkdir -p "$ROOTFS/usr/lib/arynox"
for bin in arynox-*; do
    src="$PROJECT/target/release/$bin"
    if [ -f "$src" ]; then
        cp "$src" "$ROOTFS/usr/lib/arynox/"
        chmod +x "$ROOTFS/usr/lib/arynox/$bin"
    fi
done

# Copy systemd service files
mkdir -p "$ROOTFS/etc/systemd/system"
cp "$PROJECT/src/boot/systemd/"*.service "$ROOTFS/etc/systemd/system/" 2>/dev/null || true
cp "$PROJECT/src/boot/systemd/"*.target "$ROOTFS/etc/systemd/system/" 2>/dev/null || true

# Enable daemon services
for svc in "$PROJECT/src/boot/systemd/"*.service; do
    name=$(basename "$svc")
    chroot "$ROOTFS" systemctl enable "$name" 2>/dev/null || true
done

# Copy D-Bus config
mkdir -p "$ROOTFS/etc/dbus-1/system.d"
cp "$PROJECT/src/boot/dbus/"*.conf "$ROOTFS/etc/dbus-1/system.d/" 2>/dev/null || true

# ---- STEP 4: Integrate Flutter apps ----
echo "[5/9] Installing Flutter apps..."
for d in "$PROJECT/build/flutter-apps/"*/; do
    [ -d "$d" ] || continue
    app=$(basename "$d")
    mkdir -p "$ROOTFS/usr/share/arynox/$app"
    cp -r "$d"/* "$ROOTFS/usr/share/arynox/$app/"
done

# Create launcher script
cat > "$ROOTFS/usr/local/bin/launch-arynox-app" << 'EOF'
#!/bin/bash
# Launch an Arynox Flutter app
APP_NAME="$1"
APP_DIR="/usr/share/arynox/$APP_NAME"
if [ -f "$APP_DIR/$APP_NAME" ]; then
    exec "$APP_DIR/$APP_NAME"
elif [ -f "$APP_DIR/bin/$APP_NAME" ]; then
    exec "$APP_DIR/bin/$APP_NAME"
else
    # Try to find any executable
    for f in "$APP_DIR"/*; do
        [ -x "$f" ] && [ ! -d "$f" ] && exec "$f" && break
    done
    echo "No executable found for $APP_NAME"
fi
EOF
chmod +x "$ROOTFS/usr/local/bin/launch-arynox-app"

# ---- STEP 5: Python AI runtime ----
echo "[6/9] Installing Python AI runtime..."
AI_DIR="$ROOTFS/usr/lib/arynox/ai-runtime"
mkdir -p "$AI_DIR"
cp -r "$PROJECT/ai-python/arynox_ai" "$AI_DIR/" 2>/dev/null || true
cp "$PROJECT/ai-python/pyproject.toml" "$AI_DIR/" 2>/dev/null || true

# Install Python deps
chroot "$ROOTFS" pip3 install --quiet wheel setuptools 2>/dev/null || true
chroot "$ROOTFS" pip3 install --quiet -e /usr/lib/arynox/ai-runtime 2>/dev/null || true

# ---- STEP 6: AI First-Boot Download Service ----
echo "[7/9] Creating AI first-boot download service..."

mkdir -p "$ROOTFS/usr/local/lib/arynox-ai"
cat > "$ROOTFS/usr/local/lib/arynox-ai/download-models.sh" << 'AISCRIPT'
#!/bin/bash
# Arynox AI - First Boot Model Download
# Downloads: Ollama + Llama 3.2 (3B), Moondream2, SmolVLM 500M
# Total: ~8-10GB (well under 20GB limit)

LOGFILE="/var/log/arynox-ai-download.log"
STATUSFILE="/var/lib/arynox-ai/download-complete"
MODEL_DIR="/usr/share/arynox/ai-models"

mkdir -p "$MODEL_DIR" /var/lib/arynox-ai
exec > "$LOGFILE" 2>&1

echo "=== Arynox AI Model Download ==="
echo "Started: $(date)"

# 1. Install Ollama
echo "[1/4] Installing Ollama..."
if ! command -v ollama &>/dev/null; then
    curl -fsSL https://ollama.com/install.sh | bash 2>&1
fi

# 2. Pull models via Ollama
echo "[2/4] Downloading Llama 3.2 (3B) for reasoning/coding..."
ollama pull llama3.2:3b 2>&1 || ollama pull llama3.2 2>&1

echo "[3/4] Downloading Moondream2 for vision/face detection..."
ollama pull moondream2 2>&1 || echo "Moondream2 not available, downloading from HuggingFace..."
if ! ollama list | grep -q moondream; then
    # Fallback: download from HuggingFace
    pip3 install --quiet huggingface-hub 2>/dev/null
    python3 -c "
import os, subprocess
os.environ['HF_HUB_ENABLE_HF_TRANSFER'] = '1'
from huggingface_hub import snapshot_download
snapshot_download(repo_id='vikhyatk/moondream2', local_dir='$MODEL_DIR/moondream2', 
                  allow_patterns=['*.pt', '*.json', '*.bin', '*.txt'])
print('Moondream2 downloaded to $MODEL_DIR/moondream2')
" 2>&1 || echo "Moondream2 download deferred"
fi

echo "[4/4] Downloading SmolVLM 500M for detection..."
if ! ollama list | grep -q smolvlm; then
    pip3 install --quiet transformers torch 2>/dev/null
    python3 -c "
import os
os.environ['HF_HUB_ENABLE_HF_TRANSFER'] = '1'
from huggingface_hub import snapshot_download
snapshot_download(repo_id='HuggingFaceTB/SmolVLM-500M', local_dir='$MODEL_DIR/smolvlm-500m',
                  allow_patterns=['*.safetensors', '*.json', '*.txt', '*.model'])
print('SmolVLM-500M downloaded to $MODEL_DIR/smolvlm-500m')
" 2>&1 || echo "SmolVLM download deferred"
fi

# 4. Create AI config
cat > /etc/arynox/ai-config.json << 'JSON'
{
    "provider": "ollama",
    "models": {
        "reasoning": "llama3.2:3b",
        "vision": "moondream2",
        "detection": "smolvlm-500m"
    },
    "endpoint": "http://localhost:11434",
    "offline": true,
    "auto_browser": true
}
JSON

# Mark complete
date > "$STATUSFILE"
echo "=== Download Complete: $(date) ==="
echo "Models downloaded to $MODEL_DIR and Ollama"
AISCRIPT
chmod +x "$ROOTFS/usr/local/lib/arynox-ai/download-models.sh"

# Create systemd service for first-boot download
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
StandardError=journal+console

[Install]
WantedBy=multi-user.target
EOF

chroot "$ROOTFS" systemctl enable arynox-ai-download 2>/dev/null || true

# Create AI agent service
cat > "$ROOTFS/etc/systemd/system/arynox-ai-agent.service" << 'EOF'
[Unit]
Description=Arynox AI Autonomous Agent
After=arynox-ai-download.service ollama.service
Requires=arynox-ai-download.service ollama.service
ConditionPathExists=/var/lib/arynox-ai/download-complete

[Service]
Type=simple
User=arynox
ExecStart=/usr/local/bin/arynox-ai-agent
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Create AI agent script
cat > "$ROOTFS/usr/local/bin/arynox-ai-agent" << 'AGENTSCRIPT'
#!/bin/bash
# Arynox AI Autonomous Agent
# Monitors system, provides AI assistance via Ollama
# Uses: llama3.2 (reasoning), moondream2 (vision), smolvlm (detection)

API="http://localhost:11434/api"
MODEL_REASON="llama3.2:3b"
MODEL_VISION="moondream2"
MODEL_DETECT="smolvlm-500m"

echo "Arynox AI Agent started. Waiting for Ollama..."
for i in {1..30}; do
    curl -s "$API/tags" >/dev/null 2>&1 && break
    sleep 2
done

# Start AI assistant service on port 8080
# Provides REST API for all apps to use AI
python3 -c "
import http.server, json, subprocess, os, sys

PORT = 8080
MODELS = {'reasoning': '$MODEL_REASON', 'vision': '$MODEL_VISION', 'detection': '$MODEL_DETECT'}

class AIHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get('content-length', 0))
        body = json.loads(self.rfile.read(length).decode() if length else '{}')
        
        if self.path == '/chat':
            model = body.get('model', MODELS['reasoning'])
            prompt = body.get('prompt', '')
            result = subprocess.run(['ollama', 'run', model, prompt], 
                                   capture_output=True, text=True, timeout=300)
            self.send_json({'response': result.stdout})
            
        elif self.path == '/analyze':
            # Vision analysis with Moondream2
            image = body.get('image', '')
            result = subprocess.run(['ollama', 'run', MODELS['vision'], 
                                   f'Describe this image in detail: {image}'],
                                   capture_output=True, text=True, timeout=120)
            self.send_json({'analysis': result.stdout})
            
        elif self.path == '/detect':
            # Object/face detection with SmolVLM
            image = body.get('image', '')
            result = subprocess.run(['ollama', 'run', MODELS['detect'],
                                   f'Detect all objects, faces, and text in this image: {image}'],
                                   capture_output=True, text=True, timeout=120)
            self.send_json({'detections': result.stdout})
            
        elif self.path == '/browse':
            # Web browsing capability
            import urllib.request
            url = body.get('url', '')
            try:
                resp = urllib.request.urlopen(url, timeout=30)
                content = resp.read().decode('utf-8', errors='replace')
                # Summarize with LLM
                summary = subprocess.run(['ollama', 'run', MODELS['reasoning'],
                                        f'Summarize this web page content: {content[:10000]}'],
                                        capture_output=True, text=True, timeout=120)
                self.send_json({'url': url, 'summary': summary.stdout, 'content': content[:5000]})
            except Exception as e:
                self.send_json({'error': str(e)})
        
        else:
            self.send_json({'error': 'unknown endpoint'})
    
    def send_json(self, data):
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())
    
    def log_message(self, format, *args):
        pass

print(f'Arynox AI Agent running on port {PORT}')
http.server.HTTPServer(('0.0.0.0', PORT), AIHandler).serve_forever()
" &
echo "AI Agent running on port 8080"
wait
AGENTSCRIPT
chmod +x "$ROOTFS/usr/local/bin/arynox-ai-agent"

# Create Ollama service
cat > "$ROOTFS/etc/systemd/system/ollama.service" << 'EOF'
[Unit]
Description=Ollama AI Runtime
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/ollama serve
Restart=always
User=arynox
Environment=OLLAMA_HOST=0.0.0.0
Environment=OLLAMA_KEEP_ALIVE=24h

[Install]
WantedBy=multi-user.target
EOF

# ---- STEP 7: Create Weston desktop launcher with app shortcuts ----
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

# Enable essential services
chroot "$ROOTFS" systemctl enable NetworkManager 2>/dev/null || true
chroot "$ROOTFS" systemctl enable systemd-networkd 2>/dev/null || true
chroot "$ROOTFS" systemctl enable systemd-resolved 2>/dev/null || true
chroot "$ROOTFS" systemctl enable ssh 2>/dev/null || true
chroot "$ROOTFS" systemctl enable pipewire 2>/dev/null || true
chroot "$ROOTFS" systemctl enable ollama 2>/dev/null || true
chroot "$ROOTFS" systemctl set-default graphical.target 2>/dev/null || true

# Unmount chroot filesystems
umount -l "$ROOTFS/dev" 2>/dev/null || true
umount -l "$ROOTFS/proc" 2>/dev/null || true
umount -l "$ROOTFS/sys" 2>/dev/null || true

# ---- STEP 8: Build initramfs ----
echo "[8/9] Building initramfs..."
INITRAMFS_DIR="$PROJECT/build/initramfs"
rm -rf "$INITRAMFS_DIR"
mkdir -p "$INITRAMFS_DIR"/{bin,dev,etc,lib64,lib/x86_64-linux-gnu,mnt/root,proc,run,sbin,sys,tmp,cdrom}

# BusyBox for initramfs utilities
cp /bin/busybox "$INITRAMFS_DIR/bin/"
for c in sh mount umount grep ls cat echo mkdir dmesg mknod switch_root poweroff reboot sleep modprobe; do
    ln -sf busybox "$INITRAMFS_DIR/bin/$c" 2>/dev/null || true
done

# Copy libraries for busybox
for lib in libgcc_s.so.1 libm.so.6 libc.so.6 libpthread.so.0 librt.so.1 libcrypt.so.1; do
    cp "/lib/x86_64-linux-gnu/$lib" "$INITRAMFS_DIR/lib/x86_64-linux-gnu/" 2>/dev/null || true
done
cp /lib64/ld-linux-x86-64.so.2 "$INITRAMFS_DIR/lib64/" 2>/dev/null || true

# Kernel modules for squashfs, overlay, ISO9660
MODULES_DIR="$INITRAMFS_DIR/lib/modules"
mkdir -p "$MODULES_DIR"
KERNEL_VER=$(ls /lib/modules/ 2>/dev/null | head -1)
if [ -n "$KERNEL_VER" ]; then
    mkdir -p "$MODULES_DIR/$KERNEL_VER"
    for mod in squashfs overlay isofs cdrom; do
        find /lib/modules/$KERNEL_VER -name "${mod}.ko*" -exec cp {} "$MODULES_DIR/$KERNEL_VER/" \; 2>/dev/null || true
    done
    depmod -b "$INITRAMFS_DIR" "$KERNEL_VER" 2>/dev/null || true
fi

# Create init script
cat > "$INITRAMFS_DIR/init" << 'INITEOF'
#!/bin/sh

# Redirect output to serial console (QEMU nographic mode)
exec >/dev/ttyS0 2>&1

# Mount essential filesystems
/bin/mount -t proc proc /proc
/bin/mount -t sysfs sysfs /sys
/bin/mount -t devtmpfs devtmpfs /dev
/bin/mount -t tmpfs tmpfs /run

# Load kernel modules
/sbin/modprobe squashfs 2>/dev/null || true
/sbin/modprobe overlay 2>/dev/null || true
/sbin/modprobe isofs 2>/dev/null || true
/sbin/modprobe cdrom 2>/dev/null || true

# Create device nodes
/bin/mknod /dev/sr0 b 11 0 2>/dev/null || true
/bin/mknod /dev/loop0 b 7 0 2>/dev/null || true

echo ""
echo "  Arynox OS v0.1.0  |  Created by Aryan Chavan  |  (C) 2026"
echo "  AI-Native Operating System - Loading..."
echo ""

# Wait for devices and serial console
/bin/sleep 3

# Try to find and mount CD-ROM
CD_MOUNTED=0
for dev in /dev/sr0 /dev/sr1 /dev/hda /dev/hdb /dev/sda /dev/sdb /dev/sdc; do
    if [ -b "$dev" ]; then
        /bin/mount -t iso9660 -o ro "$dev" /cdrom 2>/dev/null && CD_MOUNTED=1 && break
    fi
done

if [ "$CD_MOUNTED" != "1" ]; then
    # Try block devices
    for dev in /dev/*; do
        case "$dev" in
            /dev/sd*|/dev/hd*|/dev/vd*|/dev/xvd*)
                [ -b "$dev" ] || continue
                /bin/mount -t iso9660 -o ro "$dev" /cdrom 2>/dev/null && CD_MOUNTED=1 && break
                ;;
        esac
    done
fi

if [ "$CD_MOUNTED" != "1" ]; then
    echo "ERROR: Could not find boot CD-ROM"
    echo "Available devices:"
    /bin/ls -la /dev/sd* /dev/sr* /dev/hd* 2>/dev/null || true
    echo "Dropping to emergency shell..."
    exec /bin/sh
fi

echo "Found boot media, mounting root filesystem..."

# Mount squashfs
/bin/mount -t squashfs -o ro /cdrom/live/filesystem.squashfs /mnt/root 2>/dev/null
if [ $? -ne 0 ]; then
    echo "ERROR: Could not mount filesystem.squashfs"
    echo "Contents of /cdrom/live/:"
    /bin/ls -la /cdrom/live/ 2>/dev/null || true
    exec /bin/sh
fi

# Mount writable tmpfs overlays
/bin/mount -t tmpfs -o mode=0755 tmpfs /mnt/root/run
/bin/mkdir -p /mnt/root/tmp /mnt/root/var/tmp
/bin/mount -t tmpfs -o mode=1777 tmpfs /mnt/root/tmp
/bin/mount -t tmpfs -o mode=1777 tmpfs /mnt/root/var/tmp

# Mount devtmpfs for device management
/bin/mount -t devtmpfs devtmpfs /mnt/root/dev

echo "Switching to systemd root..."
exec /sbin/switch_root /mnt/root /sbin/init
INITEOF
chmod +x "$INITRAMFS_DIR/init"

# Build cpio initramfs
cd "$INITRAMFS_DIR"
find . | cpio -H newc -o 2>/dev/null | gzip -9 > "$PROJECT/build/initramfs.img"
echo "Initramfs: $(du -h $PROJECT/build/initramfs.img | cut -f1)"

# ---- STEP 9: Build squashfs ----
echo "[8/9] Building squashfs root filesystem..."
mksquashfs "$ROOTFS" "$PROJECT/build/filesystem.squashfs" -comp zstd -b 1M -noappend -quiet 2>&1
echo "Squashfs: $(du -h $PROJECT/build/filesystem.squashfs | cut -f1)"

# Clean up rootfs
rm -rf "$ROOTFS"

# ---- STEP 10: Build ISO ----
echo "[9/9] Building bootable ISO..."
ISO_DIR="$PROJECT/build/iso"
rm -rf "$ISO_DIR"
mkdir -p "$ISO_DIR/"{boot/grub,live,EFI/BOOT}

# Kernel
KERNEL_SRC=""
for k in "$PROJECT/build/vmlinuz-arynox" /boot/vmlinuz-*; do
    if [ -f "$k" ]; then
        KERNEL_SRC="$k"
        break
    fi
done

if [ -z "$KERNEL_SRC" ] || [ ! -f "$KERNEL_SRC" ]; then
    # Download generic kernel
    cd /tmp
    apt-get download linux-image-7.0.0-14-generic 2>/dev/null
    dpkg -x linux-image-7.0.0-14-generic*.deb kernel-extract 2>/dev/null
    KERNEL_SRC="/tmp/kernel-extract/boot/vmlinuz-7.0.0-14-generic"
fi

if [ -f "$KERNEL_SRC" ]; then
    cp "$KERNEL_SRC" "$ISO_DIR/boot/vmlinuz-arynox"
fi
cp "$PROJECT/build/initramfs.img" "$ISO_DIR/boot/"
cp "$PROJECT/build/filesystem.squashfs" "$ISO_DIR/live/"

# GRUB config
cat > "$ISO_DIR/boot/grub/grub.cfg" << 'GEOF'
set default=0
set timeout=3
serial --unit=0 --speed=115200
terminal_input serial console
terminal_output serial console
menuentry "Arynox OS 2026" --class arynox {
    linux /boot/vmlinuz-arynox console=ttyS0,115200n8 earlyprintk=serial,ttyS0,115200 nokaslr loglevel=7 root=LABEL=ARYNOX rw
    initrd /boot/initramfs.img
}
menuentry "Arynox OS (Safe Mode)" --class arynox {
    linux /boot/vmlinuz-arynox console=ttyS0,115200n8 earlyprintk=serial,ttyS0,115200 nokaslr loglevel=7 root=LABEL=ARYNOX rw single
    initrd /boot/initramfs.img
}
menuentry "Firmware Setup" --class firmware {
    fwsetup
}
GEOF

# EFI boot support
mkdir -p "$ISO_DIR/EFI/BOOT"
cat > "$ISO_DIR/EFI/BOOT/grub.cfg" << 'GEOF'
set default=0
set timeout=3
menuentry "Arynox OS 2026" --class arynox {
    linux /boot/vmlinuz-arynox console=ttyS0,115200n8 earlyprintk=serial,ttyS0,115200 nokaslr loglevel=7 root=LABEL=ARYNOX rw
    initrd /boot/initramfs.img
}
GEOF

# Build ISO
mkdir -p "$PROJECT/release"
rm -f "$PROJECT/release/arynox-os-0.1.0-amd64.iso"
grub-mkrescue -o "$PROJECT/release/arynox-os-0.1.0-amd64.iso" "$ISO_DIR" 2>&1 | tail -3

echo ""
echo "=========================================="
echo "  Arynox OS Build Complete!"
ls -lh "$PROJECT/release/arynox-os-0.1.0-amd64.iso"
echo "  Total files in ISO:"
ls -la "$ISO_DIR/live/"
ls -la "$ISO_DIR/boot/"
echo "=========================================="
echo ""
echo "Test with:"
echo "  qemu-system-x86_64 -cdrom release/arynox-os-0.1.0-amd64.iso -m 4G -vga virtio -display gtk"

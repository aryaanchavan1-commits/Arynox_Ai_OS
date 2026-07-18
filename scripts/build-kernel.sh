#!/bin/bash
set -euo pipefail
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"
KERNEL_VER="6.6.87"
KERNEL_DIR="/tmp/linux-$KERNEL_VER"
CONFIG="$PROJECT/src/boot/kernel-config-6.6"

echo "=========================================="
echo "  Building Arynox Custom Kernel 6.6 LTS"
echo "=========================================="

# Install kernel build dependencies
apt-get update -qq
apt-get install -y -qq build-essential libncurses-dev bison flex \
    libssl-dev libelf-dev bc cpio xz-utils \
    dwarves zstd 2>&1 | tail -3

# Download kernel source
cd /tmp
if [ ! -d "$KERNEL_DIR" ]; then
    echo "Downloading Linux $KERNEL_VER..."
    wget -q "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$KERNEL_VER.tar.xz"
    echo "Extracting..."
    tar xf "linux-$KERNEL_VER.tar.xz"
    rm "linux-$KERNEL_VER.tar.xz"
fi

cd "$KERNEL_DIR"

# Apply Arynox config
cp "$CONFIG" .config
make olddefconfig

# Build kernel
echo "Building kernel (this takes a while)..."
make -j$(nproc) bzImage 2>&1 | tail -5

# Build modules
make -j$(nproc) modules 2>&1 | tail -5

# Install modules to a staging directory
MODULES_STAGING="/tmp/arynox-kernel-modules"
rm -rf "$MODULES_STAGING"
mkdir -p "$MODULES_STAGING"
make modules_install INSTALL_MOD_PATH="$MODULES_STAGING" 2>&1 | tail -3

# Copy kernel image
cp arch/x86_64/boot/bzImage "$PROJECT/build/vmlinuz-arynox-$KERNEL_VER"
cp .config "$PROJECT/build/kernel-config-$KERNEL_VER"

# Package modules
cd "$MODULES_STAGING"
tar czf "$PROJECT/build/kernel-modules-$KERNEL_VER.tar.gz" lib/

echo ""
echo "Kernel build complete!"
ls -lh "$PROJECT/build/vmlinuz-arynox-$KERNEL_VER"
ls -lh "$PROJECT/build/kernel-modules-$KERNEL_VER.tar.gz"
echo ""
echo "Update build-full-os.sh to use:"
echo "  cp $PROJECT/build/vmlinuz-arynox-$KERNEL_VER /boot/"
echo "  tar xzf $PROJECT/build/kernel-modules-$KERNEL_VER.tar.gz -C /"

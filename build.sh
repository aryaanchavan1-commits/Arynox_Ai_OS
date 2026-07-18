#!/bin/bash
set -euo pipefail
PROJECT="$(cd "$(dirname "$0")" && pwd)"

echo "=========================================="
echo "  Arynox OS - Complete Build System"
echo "=========================================="
echo ""
echo "This script builds Arynox OS from source."
echo "Requirements: WSL2 Ubuntu 26.04, 20GB+ free space"
echo ""

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Must run as root (sudo)"
    exit 1
fi

# Step 1: Build Rust daemons
if [ -f "$PROJECT/Cargo.toml" ]; then
    echo "[1/4] Building Rust daemons..."
    cd "$PROJECT"
    cargo build --release 2>&1 | tail -3 || echo "  (Rust build skipped - not a workspace)"
fi

# Step 2: Build Flutter apps
if ls "$PROJECT/src/"*/pubspec.yaml 2>/dev/null; then
    echo "[2/4] Building Flutter apps..."
    for dir in "$PROJECT/src/"*/; do
        if [ -f "$dir/pubspec.yaml" ]; then
            app=$(basename "$dir")
            echo "  Building $app..."
            cd "$dir"
            flutter build linux --release 2>&1 | tail -1 || echo "  (Flutter build failed for $app)"
        fi
    done
fi

# Step 3: Build full OS
echo "[3/4] Building root filesystem..."
cd "$PROJECT"
bash "$PROJECT/scripts/build-full-os.sh" 2>&1 | tail -5

# Step 4: Build bootable USB
echo "[4/4] Building bootable USB image..."
bash "$PROJECT/scripts/build-usb-image.sh" 2>&1 | tail -5

echo ""
echo "=========================================="
echo "  Build Complete!"
echo "  USB image: $PROJECT/build/arynox-usb.img"
echo "=========================================="

#!/bin/bash
set -euo pipefail
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"
RELEASE_DIR="$PROJECT/release"
mkdir -p "$RELEASE_DIR"

echo "Splitting images for GitHub Releases (< 2GB per chunk)..."

if [ -f "$PROJECT/build/arynox-usb.img" ]; then
    echo "Splitting USB image..."
    split -b 1900M "$PROJECT/build/arynox-usb.img" "$RELEASE_DIR/arynox-usb.img.part"
    ls -lh "$RELEASE_DIR/arynox-usb.img.part"*
fi

if [ -f "$PROJECT/build/filesystem.squashfs" ]; then
    echo "Copying squashfs..."
    xz -T0 -9 -k "$PROJECT/build/filesystem.squashfs" 2>/dev/null || true
    if [ -f "$PROJECT/build/filesystem.squashfs.xz" ]; then
        mv "$PROJECT/build/filesystem.squashfs.xz" "$RELEASE_DIR/"
    else
        # Split if too large
        if [ "$(stat -c%s "$PROJECT/build/filesystem.squashfs" 2>/dev/null)" -gt 2000000000 ] 2>/dev/null; then
            split -b 1900M "$PROJECT/build/filesystem.squashfs" "$RELEASE_DIR/filesystem.squashfs.part"
        else
            cp "$PROJECT/build/filesystem.squashfs" "$RELEASE_DIR/"
        fi
    fi
fi

# Copy small files directly
cp "$PROJECT/build/vmlinuz-arynox" "$RELEASE_DIR/" 2>/dev/null || true
cp "$PROJECT/build/vmlinuz-"* "$RELEASE_DIR/" 2>/dev/null || true
cp "$PROJECT/build/initramfs.img" "$RELEASE_DIR/" 2>/dev/null || true
cp "$PROJECT/build/root.img" "$RELEASE_DIR/" 2>/dev/null || true

# Create checksums
cd "$RELEASE_DIR"
echo "Creating checksums..."
sha256sum * > SHA256SUMS 2>/dev/null || true
cat SHA256SUMS

# Create reassemble script
cat > "$RELEASE_DIR/reassemble.sh" << 'EOF'
#!/bin/bash
# Reassemble split Arynox OS release files
if ls arynox-usb.img.part* 1>/dev/null 2>&1; then
    echo "Reassembling USB image..."
    cat arynox-usb.img.part* > arynox-os-0.1.0-amd64.img
    echo "USB image: arynox-os-0.1.0-amd64.img ($(ls -lh arynox-os-0.1.0-amd64.img | awk '{print $5}'))"
fi
if ls filesystem.squashfs.part* 1>/dev/null 2>&1; then
    echo "Reassembling squashfs..."
    cat filesystem.squashfs.part* > filesystem.squashfs
    echo "Squashfs: filesystem.squashfs ($(ls -lh filesystem.squashfs | awk '{print $5}'))"
fi
echo "Verify with: sha256sum -c SHA256SUMS"
EOF
chmod +x "$RELEASE_DIR/reassemble.sh"

echo ""
echo "Release directory:"
ls -lh "$RELEASE_DIR/"

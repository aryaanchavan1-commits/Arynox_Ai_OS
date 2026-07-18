#!/bin/bash
export PATH="/opt/flutter/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"
mkdir -p "$PROJECT/build/flutter-apps"

build_one() {
    local name="$1"
    local dir="$2"
    echo ""
    echo "=== Building $name ==="
    cd "$dir" 2>/dev/null || { echo "  Directory not found"; return 1; }
    if [ ! -f pubspec.yaml ]; then echo "  No pubspec.yaml"; return 1; fi

    if [ ! -d linux ]; then
        flutter create --platforms=linux . 2>&1 | grep -v "^$" | tail -2
    fi

    flutter pub get 2>&1 | tail -1
    if flutter build linux --release 2>&1 | tail -3; then
        echo "  SUCCESS: $name"
        local out="$PROJECT/build/flutter-apps/$(echo $name | tr '/' '-')"
        mkdir -p "$out"
        cp -r build/linux/x64/release/bundle/* "$out/" 2>/dev/null || true
    else
        echo "  FAILED: $name"
        return 1
    fi
}

# Build all apps
build_one "desktop" "$PROJECT/src/desktop"
build_one "settings" "$PROJECT/src/settings"
build_one "files" "$PROJECT/src/files"
build_one "devices" "$PROJECT/src/devices"
build_one "software" "$PROJECT/src/software"
build_one "network" "$PROJECT/src/network"
build_one "devtools" "$PROJECT/src/devtools"
build_one "installer" "$PROJECT/src/installer"
build_one "ai-hub" "$PROJECT/src/ai/hub"
build_one "ai-assistant" "$PROJECT/src/ai/assistant"
build_one "ai-copilot" "$PROJECT/src/ai/copilot"

echo ""
echo "=== Final Summary ==="
for f in "$PROJECT/build/flutter-apps/"*/; do
    [ -d "$f" ] && echo "  $(basename $f): $(du -sh "$f" | cut -f1)"
done
echo ""
echo "Total: $(ls -d "$PROJECT/build/flutter-apps/"*/ 2>/dev/null | wc -l) apps"

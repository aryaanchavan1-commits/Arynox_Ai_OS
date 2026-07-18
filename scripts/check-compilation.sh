#!/bin/bash
set -euo pipefail
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"
cd "$PROJECT"

echo "=== Rust Crates ==="
for m in src/wm src/files src/devices src/packages src/network src/security src/cloud src/updates src/installer src/recovery src/devtools core/arynox-tpm core/arynox-boot-check core/arynox-session; do
    if [ -f "$m/Cargo.toml" ]; then
        echo "OK: $m"
    else
        echo "MISSING: $m"
    fi
done

echo ""
echo "=== Flutter Apps ==="
for d in src/devtools src/settings src/files src/desktop src/installer src/network src/software src/devices src/ai/hub src/ai/assistant src/ai/copilot; do
    if [ -f "$d/pubspec.yaml" ] && [ -f "$d/lib/main.dart" ]; then
        echo "OK: $d"
    elif [ -f "$d/pubspec.yaml" ]; then
        echo "NO_MAIN: $d"
    else
        echo "MISSING: $d"
    fi
done

echo ""
echo "=== Boot Services ==="
ls src/boot/systemd/*.service 2>/dev/null
echo ""
echo "=== Checking Rust dependency graph ==="
# Parse each crate for dependencies
for m in src/wm src/files src/devices src/packages src/network src/security src/cloud src/updates src/installer src/recovery src/devtools; do
    name=$(grep -m1 'name' "$m/Cargo.toml" 2>/dev/null | head -1)
    deps=$(grep -E '^(tokio|serde|zbus|anyhow|tracing|thiserror|uuid)' "$m/Cargo.toml" 2>/dev/null | tr '\n' ' ')
    echo "  $m: $name deps: $deps"
done

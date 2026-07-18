#!/bin/bash
set -euo pipefail
cd /mnt/d/Arynoxtech/ArynoxOS

echo "=== Checking all Rust crates ==="
for m in src/wm src/files src/devices src/packages src/network src/security src/cloud src/updates src/installer src/recovery src/devtools core/arynox-tpm core/arynox-boot-check core/arynox-session; do
    if [ -f "$m/Cargo.toml" ]; then
        NAME=$(grep -m1 "name" "$m/Cargo.toml" 2>/dev/null)
        DEPS=$(grep -cE "^(tokio|serde|zbus|anyhow|tracing|thiserror|uuid)" "$m/Cargo.toml" 2>/dev/null || echo 0)
        echo "OK $m: $NAME ($DEPS workspace deps)"
    else
        echo "MISSING: $m"
    fi
done

echo ""
echo "=== Attempting cargo check ==="
if command -v cargo &>/dev/null; then
    cargo check 2>&1 | tail -20
else
    echo "cargo not installed"
fi

#!/bin/bash
set -euo pipefail
cd /mnt/d/Arynoxtech/ArynoxOS
export HOME=/root
export PATH="$HOME/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

echo "Building arynox-session..."
cd core/arynox-session
cargo build --release 2>&1 || echo "FAILED"
cd /mnt/d/Arynoxtech/ArynoxOS

echo "Building arynox-boot-check..."
cd core/arynox-boot-check
cargo build --release 2>&1 || echo "FAILED"
cd /mnt/d/Arynoxtech/ArynoxOS

echo "Building arynox-tpm..."
cd core/arynox-tpm
cargo build --release 2>&1 || echo "FAILED"
cd /mnt/d/Arynoxtech/ArynoxOS

echo "=== Build results ==="
find target/release -maxdepth 1 -type f -executable 2>/dev/null | head -20

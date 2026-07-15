#!/bin/bash
cd /mnt/d/Arynoxtech/ArynoxOS
export HOME=/root
export PATH="/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

echo "Building arynox-session..."
cd core/arynox-session
cargo build --release 2>&1 | tail -5
cd /mnt/d/Arynoxtech/ArynoxOS

echo "Building arynox-boot-check..."
cd core/arynox-boot-check
cargo build --release 2>&1 | tail -5
cd /mnt/d/Arynoxtech/ArynoxOS

echo "Building arynox-tpm..."
cd core/arynox-tpm
cargo build --release 2>&1 | tail -5
cd /mnt/d/Arynoxtech/ArynoxOS

echo "=== Binaries ==="
find /mnt/d/Arynoxtech/ArynoxOS/target/release -maxdepth 1 -type f -executable 2>/dev/null
echo "=== Done ==="

#!/bin/bash
cd /mnt/d/Arynoxtech/ArynoxOS/build/workspace
export HOME=/root
export PATH="/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
echo "Rebuilding..."
cargo build --release 2>&1
echo "Exit code: $?"
ls -la target/release/arynox-session target/release/arynox-boot-check 2>/dev/null || echo "Some binaries missing"

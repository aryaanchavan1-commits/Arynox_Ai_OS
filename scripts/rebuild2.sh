#!/bin/bash
set -e
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"
cd "$PROJECT/build/workspace"
export HOME=/root
export PATH="/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Re-copy sources after fixes
rm -rf arynox-session arynox-boot-check
cp -r "$PROJECT/core/arynox-session" .
cp -r "$PROJECT/core/arynox-boot-check" .

echo "Building..."
cargo build --release 2>&1
echo "=== Result ==="
ls -la target/release/arynox-session target/release/arynox-boot-check 2>/dev/null || echo "Build failed"

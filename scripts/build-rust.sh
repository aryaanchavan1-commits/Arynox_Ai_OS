#!/bin/bash
set -e
cd /mnt/d/Arynoxtech/ArynoxOS
export HOME=/root
export PATH="/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Configure git for cargo to bypass auth issues in WSL
git config --global url."https://github.com/".insteadOf git://github.com/ 2>/dev/null || true
git config --global advice.detachedHead false 2>/dev/null || true

echo "=== Configuring cargo ==="
mkdir -p /root/.cargo
cat > /root/.cargo/config.toml << 'EOF'
[net]
git-fetch-with-cli = true
EOF

echo "=== Building core crates (no git deps) ==="

for crate in core/arynox-session core/arynox-boot-check; do
    echo ""
    echo "--- Building $crate ---"
    cd /mnt/d/Arynoxtech/ArynoxOS
    # Use --manifest-path to reference the specific crate
    cargo build --release --manifest-path "$crate/Cargo.toml" 2>&1 | tail -10
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo "  OK: $crate"
    else
        echo "  FAILED: $crate"
    fi
done

echo ""
echo "=== Build results ==="
find /mnt/d/Arynoxtech/ArynoxOS/target/release -maxdepth 1 -type f -executable 2>/dev/null | head -20
echo ""
echo "=== Complete ==="

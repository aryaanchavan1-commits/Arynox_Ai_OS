#!/bin/bash
set -e
cd /mnt/d/Arynoxtech/ArynoxOS
echo "=== Cargo check ==="
export PATH="$HOME/.cargo/bin:$PATH"
which cargo 2>/dev/null || echo "cargo not found"
echo ""
echo "=== Check Cargo.toml files ==="
for f in core/arynox-tpm/Cargo.toml src/wm/Cargo.toml; do
    if [ -f "$f" ]; then echo "  EXISTS: $f"; else echo "  MISSING: $f"; fi
done
echo ""
echo "=== Workspace root ==="
head -5 Cargo.toml
echo ""
echo "=== Check crates ==="
for crate in core/arynox-tpm core/arynox-boot-check core/arynox-session; do
    if [ -f "$crate/Cargo.toml" ]; then echo "  $crate: OK"; else echo "  $crate: MISSING"; fi
done

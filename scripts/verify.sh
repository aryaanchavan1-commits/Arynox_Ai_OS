#!/bin/bash
set -euo pipefail
PROJECT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT"

PASS=0
FAIL=0

check() {
    local desc="$1"
    local cmd="$2"
    if eval "$cmd" 2>/dev/null; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc"
        FAIL=$((FAIL + 1))
    fi
}

echo "=========================================="
echo "  Arynox OS Build Verification"
echo "=========================================="
echo ""

echo "--- Rust Crates ---"
for m in src/wm src/files src/devices src/packages src/network src/security src/cloud src/updates src/installer src/recovery src/devtools core/arynox-tpm core/arynox-boot-check core/arynox-session; do
    check "Crate $m exists" "[ -f '$m/Cargo.toml' ]"
    check "Crate $m has name field" "grep -q 'name' '$m/Cargo.toml'"
done

echo ""
echo "--- Flutter Apps ---"
for d in src/devtools src/settings src/files src/desktop src/installer src/network src/software src/devices src/ai/hub src/ai/assistant src/ai/copilot; do
    check "Flutter app $d exists" "[ -f '$d/pubspec.yaml' ]"
    check "Flutter app $d has main.dart" "[ -f '$d/lib/main.dart' ]"
done

echo ""
echo "--- Python AI Runtime ---"
check "ai-python module exists" "[ -d 'ai-python/arynox_ai' ]"
check "pyproject.toml exists" "[ -f 'ai-python/pyproject.toml' ]"
check "setup.py or pyproject.toml" "[ -f 'ai-python/pyproject.toml' ]"

echo ""
echo "--- Boot Configuration ---"
check "systemd services" "ls src/boot/systemd/*.service >/dev/null 2>&1"
check "kernel config" "[ -f 'src/boot/kernel-config-6.6' ]"
check "initramfs hooks" "ls src/boot/initramfs/hooks/ >/dev/null 2>&1"
check "initramfs scripts" "ls src/boot/initramfs/scripts/ >/dev/null 2>&1"
check "bootloader config" "ls src/boot/loader/loader.conf >/dev/null 2>&1"

echo ""
echo "--- Build Scripts ---"
for s in scripts/build-full-os.sh scripts/build-usb-image.sh scripts/build-kernel.sh scripts/build-initramfs.sh; do
    check "Build script $s" "[ -f '$s' ]"
    check "Build script $s is executable" "[ -x '$s' ]"
done

check "Dockerfile exists" "[ -f 'Dockerfile' ]"
check "build.sh exists" "[ -f 'build.sh' ]"
check "build.sh is executable" "[ -x 'build.sh' ]"

echo ""
echo "--- CI/CD ---"
check "CI workflow" "[ -f '.github/workflows/ci.yml' ]"
check "Release workflow" "[ -f '.github/workflows/release.yml' ]"

echo ""
echo "--- Documentation ---"
check "README exists" "[ -f 'README.md' ]"
check "ARCHITECTURE exists" "[ -f 'ARCHITECTURE.md' ]"
check "LICENSE exists" "[ -f 'LICENSE' ]"

echo ""
echo "=========================================="
echo "  Results: $PASS passed, $FAIL failed"
echo "=========================================="
exit $FAIL

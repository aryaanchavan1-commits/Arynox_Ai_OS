#!/bin/bash
set -euo pipefail
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"
USBIMG="$PROJECT/build/arynox-usb.img"

echo "Testing USB image boot in QEMU..."
echo "Waiting 120 seconds for boot..."

timeout 180 qemu-system-x86_64 \
  -m 4G \
  -nographic \
  -no-reboot \
  -drive file="$USBIMG",format=raw,if=virtio \
  -serial file:"$PROJECT/build/usb-boot-log.txt" \
  -monitor none \
  2>/dev/null &

QEMU_PID=$!
echo "QEMU PID: $QEMU_PID"

# Wait for boot and check for progress
for i in $(seq 1 120); do
  sleep 1
  if grep -q "ary\|login\|root\|kernel\|panic\|systemd" "$PROJECT/build/usb-boot-log.txt" 2>/dev/null; then
    echo "=== Boot log at ${i}s ==="
    tail -10 "$PROJECT/build/usb-boot-log.txt"
    break
  fi
done

# Wait for completion or timeout
sleep 30

echo "=== Final boot log ==="
tail -30 "$PROJECT/build/usb-boot-log.txt"

kill $QEMU_PID 2>/dev/null || true
echo "Test complete."

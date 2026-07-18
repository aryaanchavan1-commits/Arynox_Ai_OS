#!/bin/bash
set -euo pipefail

# Check for stale processes and wait
for i in 1 2 3; do
  if pgrep -f "apt-get|chroot" > /dev/null 2>&1; then
    echo "Waiting for other processes... ($i)"
    sleep 20
  else
    break
  fi
done

exec /mnt/d/Arynoxtech/ArynoxOS/scripts/fix-rootfs-manual.sh

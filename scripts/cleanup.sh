#!/bin/bash
set -euo pipefail
echo "Cleaning up mounts..."
umount /mnt/rootdisk/dev 2>/dev/null || true
umount /mnt/rootdisk/proc 2>/dev/null || true
umount /mnt/rootdisk/sys 2>/dev/null || true
umount /mnt/rootdisk 2>/dev/null || true
for l in /dev/loop*; do
  losetup -d "$l" 2>/dev/null || true
done
echo "CLEANUP_DONE"

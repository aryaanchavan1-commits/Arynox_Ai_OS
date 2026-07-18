#!/bin/bash
for d in /mnt/d/Arynoxtech/ArynoxOS/build/flutter-apps/*/; do
    name=$(basename "$d")
    files=$(ls "$d" 2>/dev/null | head -3 | tr '\n' ' ')
    echo "$name: $files"
done

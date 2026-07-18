#!/bin/bash
for d in /mnt/d/Arynoxtech/ArynoxOS/src/*/ /mnt/d/Arynoxtech/ArynoxOS/src/ai/*/; do
    name=$(basename "$d")
    if [ -d "${d}linux" ]; then
        echo "$name: linux=YES"
    else
        echo "$name: linux=no"
    fi
done

#!/bin/bash
cd /mnt/d/Arynoxtech/ArynoxOS
export HOME=/root
export PATH="$HOME/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
echo "rustc: $(rustc --version 2>/dev/null || echo 'not found')"
echo "cargo: $(cargo --version 2>/dev/null || echo 'not found')"
echo "HOME: $HOME"
echo "PATH: $PATH"
ls -la $HOME/.cargo/bin/ 2>/dev/null || echo "No cargo bin dir"

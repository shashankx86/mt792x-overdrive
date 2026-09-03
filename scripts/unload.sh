#!/usr/bin/env bash
set -e

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo ./scripts/unload.sh)"
    exit 1
fi

echo "=== Unloading MT792x Modules ==="
modprobe -r mt7921e mt7921_common mt792x_lib mt76_connac_lib mt76 2>/dev/null || true
echo "=== Unloaded ==="

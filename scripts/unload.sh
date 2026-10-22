#!/usr/bin/env bash
set -e

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo ./scripts/unload.sh)"
    exit 1
fi

echo "=== Unloading MT792x Modules ==="
for m in mt7921e mt7921_common mt792x_lib mt76_connac_lib mt76; do
    if grep -q "^${m} " /proc/modules; then
        rmmod "${m}"
    fi
done
echo "=== Unloaded ==="

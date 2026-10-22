#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo ./scripts/load.sh)"
    exit 1
fi

echo "=== Loading MT792x Overdrive Modules ==="

# 1. Unload the stock or previously loaded stack first
for m in mt7921e mt7921_common mt792x_lib mt76_connac_lib mt76; do
    if grep -q "^${m} " /proc/modules; then
        echo "Unloading ${m}..."
        rmmod "${m}"
    fi
done

# 2. Ensure mac80211 and cfg80211 are present
modprobe mac80211 cfg80211

# 3. Insert overdrive modules in dependency order
insmod "${DIR}/mt76.ko"
insmod "${DIR}/mt76-connac-lib.ko"
insmod "${DIR}/mt792x-lib.ko"
insmod "${DIR}/mt7921/mt7921-common.ko"
insmod "${DIR}/mt7921/mt7921e.ko"

echo "=== MT792x Overdrive Driver Loaded Successfully ==="
lsmod | grep -E "mt7921|mt76"

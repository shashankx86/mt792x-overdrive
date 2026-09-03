#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo ./scripts/load.sh)"
    exit 1
fi

echo "=== Loading MT792x Overdrive Modules ==="

# 1. Ensure mac80211 and cfg80211 are present
modprobe mac80211 cfg80211

# 2. Insert overdrive modules in dependency order
insmod "${DIR}/mt76.ko"
insmod "${DIR}/mt76-connac-lib.ko"
insmod "${DIR}/mt792x-lib.ko"
insmod "${DIR}/mt7921/mt7921-common.ko"
insmod "${DIR}/mt7921/mt7921e.ko"

echo "=== MT792x Overdrive Driver Loaded Successfully ==="
lsmod | grep -E "mt7921|mt76"

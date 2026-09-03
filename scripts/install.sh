#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KERNEL_VER="$(uname -r)"
DEST="/lib/modules/${KERNEL_VER}/updates/mt792x-overdrive"

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo ./scripts/install.sh)"
    exit 1
fi

case "$1" in
    uninstall|remove)
        echo "=== Removing Overdrive modules from ${DEST} ==="
        rm -rf "${DEST}"
        depmod -a
        echo "Reverted to stock kernel modules. Reboot or modprobe mt7921e."
        exit 0
        ;;
esac

echo "=== Installing MT792x Overdrive Modules into ${DEST} ==="
mkdir -p "${DEST}"

# Check if stock modules are zstd compressed
USE_ZSTD=false
if ls /lib/modules/"${KERNEL_VER}"/kernel/drivers/net/wireless/mediatek/mt76/*.zst >/dev/null 2>&1; then
    USE_ZSTD=true
fi

install_mod() {
    local src="$1"
    local name="$(basename "$src")"
    if [ "$USE_ZSTD" = true ] && command -v zstd >/dev/null 2>&1; then
        zstd -f -q "${src}" -o "${DEST}/${name}.zst"
        echo "Installed ${DEST}/${name}.zst"
    else
        cp "${src}" "${DEST}/${name}"
        echo "Installed ${DEST}/${name}"
    fi
}

install_mod "${DIR}/mt76.ko"
install_mod "${DIR}/mt76-connac-lib.ko"
install_mod "${DIR}/mt792x-lib.ko"
install_mod "${DIR}/mt7921/mt7921-common.ko"
install_mod "${DIR}/mt7921/mt7921e.ko"

echo "=== Running depmod -a ==="
depmod -a

echo "=== Installation complete! ==="
echo "The overdrive driver will now be automatically loaded by the system on every boot."
echo "To revert back to stock at any time: sudo ./scripts/install.sh uninstall"

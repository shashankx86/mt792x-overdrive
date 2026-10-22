#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KERNEL_VER="$(uname -r)"
BUILD_DIR="/lib/modules/${KERNEL_VER}/build"

echo "=== Building MT792x Overdrive Driver (Linux ${KERNEL_VER}) ==="

if [ ! -d "${BUILD_DIR}" ]; then
    echo "Error: Kernel build headers not found at ${BUILD_DIR}"
    exit 1
fi

# Ensure overdrive patch is applied
"${DIR}/scripts/patch.sh" apply

# Detect Clang / LLVM vs GCC from the kernel config
if grep -Eq '^CONFIG_CC_IS_CLANG=y' "${BUILD_DIR}/.config" 2>/dev/null; then
    COMPILER="CC=clang LLVM=1"
    echo "Using Clang compiler toolchain (LLVM=1)"
elif grep -Eq '^CONFIG_CC_IS_GCC=y' "${BUILD_DIR}/.config" 2>/dev/null; then
    COMPILER=""
    echo "Using GCC compiler toolchain"
elif grep -q 'clang version' /proc/version 2>/dev/null; then
    COMPILER="CC=clang LLVM=1"
    echo "Kernel config missing; running kernel was built with clang, using LLVM=1"
else
    COMPILER=""
    echo "Kernel config missing; defaulting to GCC"
fi

make -j"$(nproc)" -C "${BUILD_DIR}" M="${DIR}" ${COMPILER} modules

echo "=== Build Complete ==="
echo "Built overdrive modules:"
ls -lh "${DIR}"/mt76.ko "${DIR}"/mt76-connac-lib.ko "${DIR}"/mt792x-lib.ko "${DIR}"/mt7921/mt7921-common.ko "${DIR}"/mt7921/mt7921e.ko

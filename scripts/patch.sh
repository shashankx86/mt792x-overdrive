#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATCH_DIR="${DIR}/patch"

get_patches() {
    mapfile -t PATCH_LIST < <(find "${PATCH_DIR}" -maxdepth 1 -type f -name "*.patch" | sort)
}

get_applied_patch() {
    get_patches
    APPLIED_PATCH=""
    for p in "${PATCH_LIST[@]}"; do
        [ -s "$p" ] || continue
        if patch -p1 -R --dry-run -d "${DIR}" < "$p" >/dev/null 2>&1; then
            APPLIED_PATCH="$p"
            return 0
        fi
    done
    return 1
}

print_table() {
    get_patches
    get_applied_patch || true
    echo "Available patches:"
    printf "  %-4s  %-32s  %-10s\n" "ID" "Patch File" "Status"
    printf "  %-4s  %-32s  %-10s\n" "--" "----------" "------"
    local id=1
    for p in "${PATCH_LIST[@]}"; do
        local bname
        bname="$(basename "$p")"
        local status="Not applied"
        if [ "$p" = "$APPLIED_PATCH" ]; then
            status="APPLIED"
        fi
        printf "  %-4s  %-32s  %-10s\n" "$id" "$bname" "$status"
        ((id++))
    done
}

status() {
    get_applied_patch || true
    if [ -n "$APPLIED_PATCH" ]; then
        echo "Patch status: True ($(basename "$APPLIED_PATCH") applied)"
    else
        echo "Patch status: False"
    fi
    echo ""
    print_table
}

resolve_patch() {
    local target="$1"
    get_patches
    local count="${#PATCH_LIST[@]}"

    if [ "$count" -eq 0 ]; then
        echo "Error: No patch files found in ${PATCH_DIR}"
        exit 1
    fi

    # Auto-select if only one patch is present and no argument given
    if [ -z "$target" ]; then
        if [ "$count" -eq 1 ]; then
            SELECTED_PATCH="${PATCH_LIST[0]}"
            echo "Auto-selecting single available patch: $(basename "$SELECTED_PATCH")"
            return 0
        else
            echo "Error: Multiple patches available. Please specify a patch ID number."
            echo ""
            print_table
            echo ""
            echo "Usage: $0 apply <ID>"
            exit 1
        fi
    fi

    # If numeric ID given
    if [[ "$target" =~ ^[0-9]+$ ]]; then
        local idx=$((target - 1))
        if [ "$idx" -ge 0 ] && [ "$idx" -lt "$count" ]; then
            SELECTED_PATCH="${PATCH_LIST[$idx]}"
            return 0
        else
            echo "Error: Invalid patch ID '$target'. Valid IDs: 1 to $count"
            exit 1
        fi
    fi

    # Match by filename
    for p in "${PATCH_LIST[@]}"; do
        if [ "$(basename "$p")" = "$target" ] || [ "$p" = "$target" ]; then
            SELECTED_PATCH="$p"
            return 0
        fi
    done

    echo "Error: Could not find patch matching '$target'."
    exit 1
}

apply() {
    resolve_patch "$1"
    get_applied_patch || true

    if [ "$SELECTED_PATCH" = "$APPLIED_PATCH" ]; then
        echo "Patch '$(basename "$SELECTED_PATCH")' is already applied."
        return 0
    elif [ -n "$APPLIED_PATCH" ]; then
        echo "Error: Another patch '$(basename "$APPLIED_PATCH")' is currently applied."
        echo "Please revert it first using: $0 revert"
        exit 1
    fi

    echo "Applying patch: $(basename "$SELECTED_PATCH")..."
    patch -p1 -d "${DIR}" < "${SELECTED_PATCH}"
    echo "Patch applied successfully."
}

revert() {
    get_applied_patch || true
    local target="$1"

    if [ -n "$APPLIED_PATCH" ]; then
        SELECTED_PATCH="$APPLIED_PATCH"
    else
        resolve_patch "$target"
    fi

    if patch -p1 -R --dry-run -d "${DIR}" < "${SELECTED_PATCH}" >/dev/null 2>&1; then
        echo "Reverting patch: $(basename "$SELECTED_PATCH")..."
        patch -p1 -R -d "${DIR}" < "${SELECTED_PATCH}"
        echo "Reverted to clean upstream stock."
    else
        echo "Patch '$(basename "$SELECTED_PATCH")' is not currently applied."
    fi
}

case "$1" in
    status)
        status
        ;;
    apply)
        apply "$2"
        ;;
    revert|unpatch)
        revert "$2"
        ;;
    *)
        echo "Usage: $0 {status|apply [id]|revert [id]}"
        exit 1
        ;;
esac

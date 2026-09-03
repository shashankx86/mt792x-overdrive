# mt792x-overdrive

High-performance, unthrottled Linux kernel driver for MediaTek & AMD Wi-Fi 6 / 6E wireless adapters.

Bypasses laptop OEM BIOS power restrictions (ACPI SAR), uncaps firmware modulation transmit tables, and eliminates PCIe power-saving wake latency and jitter-sensitive workloads.

Maintained directly against stable Linux kernel releases via version-aligned patches under `patch/`.

---

## What It Does

| Restriction | Stock Driver | Overdrive | Impact |
| :--- | :--- | :--- | :--- |
| **ACPI Dynamic SAR** | BIOS limits TX power by 6–12 dBm on battery/body proximity | **Completely bypassed** | Restores full radio amplifier wattage (recovers +3 to +6 dBm) |
| **MCU Rate Power (SKU)** | Power throttled per modulation rate (MCS 0–11) to match SAR | **Uncapped** | Transmits at full regulatory channel EIRP across all MCS rates |
| **PCIe ASPM** | Enabled by default; PCIe link enters L0s/L1 between bursts | **Disabled by default** | Eliminates bus wake-up latency and micro-stutters during game ticks |

---

## Hardware Compatibility

Unified driver for the entire MediaTek & AMD Wi-Fi 6 / 6E generation:

| Chipset | PCI ID | Protocol | Notes |
| :--- | :---: | :---: | :--- |
| **MediaTek MT7921 / MT7961** | `0x7961` | Wi-Fi 6 (80 MHz) | Acer, ASUS, Lenovo, HP gaming laptops |
| **MediaTek MT7922** | `0x7922` | Wi-Fi 6E (160 MHz, 6 GHz) | High-end motherboards & laptops |
| **AMD RZ608** | `0x0608`, `0x7920` | Wi-Fi 6 | Re-badged MT7921 for AMD platforms |
| **AMD RZ616** | `0x0616`, `0x0b48:0x7922` | Wi-Fi 6E | Re-badged MT7922 for AMD Advantage platforms |
| **MediaTek MT7902** | `0x7902` | Wi-Fi 6 | Budget laptop combo chip |

---

## Patch Management

The repository keeps the base driver at clean upstream stock. Overdrive modifications are maintained as version-aligned patches under `patch/`:

* **`patch/7.1.8-overdrive.patch`**: ACPI SAR bypass, MCU rate uncap, ASPM disable, version tag.

Use `scripts/patch.sh` to manage the tree:
```bash
./scripts/patch.sh status   # Check current state (applied vs clean stock)
./scripts/patch.sh apply    # Apply overdrive patch
./scripts/patch.sh revert   # Revert back to clean upstream stock
```

---

## Installation

### Method 1: Arch Linux 

Build and install via `makepkg` (uses DKMS):
```bash
cd packaging
makepkg -si
```
*Automatically applies the patch and rebuilds across all future `pacman -Syu` kernel updates.*

To uninstall:
```bash
sudo pacman -R mt792x-overdrive-dkms
```

---

### Method 2: Manual DKMS (Ubuntu / Debian / Fedora / Arch)

```bash
sudo dkms add .
sudo dkms build mt792x-overdrive/7.1.8_overdrive
sudo dkms install mt792x-overdrive/7.1.8_overdrive
```

To remove:
```bash
sudo dkms remove mt792x-overdrive/7.1.8_overdrive --all
```

---

### Method 3: Standalone Build & Load (No Installation)

```bash
# Automatically applies patch and builds
./scripts/build.sh

# Load into kernel
sudo ./scripts/load.sh

# Unload
sudo ./scripts/unload.sh
```

---

## Verification

Check if Overdrive is active:
```bash
# Verify version tag and ASPM
modinfo mt7921e | grep version
journalctl -k -b | grep -i mt7921e

# Check live link quality & packet retry counters
iw dev wlan0 station dump | grep -E "signal|bitrate|tx retries|tx failed"
```

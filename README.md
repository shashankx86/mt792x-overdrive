# mt792x-overdrive

Custom driver for mt76-based PCIe cards with performance in mind.

The base tree stays clean upstream stock. All changes ship in `patch/`.

---

## What it changes

| Area | Stock | Overdrive |
| :--- | :--- | :--- |
| ACPI SAR tables | BIOS caps TX power by proximity | Bypassed, full regulatory channel power |
| MCU per-rate (SKU) limits | Derated per MCS 0-11 | Uses max regulatory power across rates |
| PCIe ASPM | L0s/L1 between bursts | Off by default |
| Country CLC tables | Firmware prunes channels/power | Skipped by default |
| Firmware power-save / deep-sleep | On, 83 ms idle timeout | Off by default |
| WM event ring | 8 entries, drops under scan/radar churn | 64 entries |
| Delay-interrupt coalescing | Already 0 | Kept at 0, guard comment added |
| RX reorder hold | 100 ms BE/BK, 40 ms others | 50 ms / 20 ms |
| RX NAPI weight, data queue | 64 | 128, MCU queues stay 64 |
| PCIe read request size | BIOS default | 512 when ASPM is off |
| TX AQL gate on new kernels | Calls removed `aql_pending`, fails to build | Ported to `airtime_check`, inverted polarity |

---

## Hardware that works

PCIe only. The build ships `mt7921e` plus its libs and drops USB, SDIO, testmode, and all other chip families, so none of those bind after install.

| Chipset | PCI ID | Protocol |
| :--- | :---: | :--- |
| MediaTek MT7921 / MT7961 | `14c3:7961` | Wi-Fi 6, 80 MHz |
| MediaTek MT7961 1a stepping | `14c3:7920` | Wi-Fi 6, 80 MHz, same family, its own firmware |
| MediaTek MT7922 | `14c3:7922`, `0b48:7922` | Wi-Fi 6E, 160 MHz |
| AMD RZ608 | `14c3:0608` | Wi-Fi 6, re-badged MT7921 |
| AMD RZ616 | `14c3:0616` | Wi-Fi 6E, re-badged MT7922 |
| MediaTek MT7902 | `14c3:7902` | Wi-Fi 6 budget combo |

SDIO and USB variants of these IDs are not supported by this build.

---

## Module parameters

Everything is reversible at runtime, no recompile. All default to the fast setting.

| Parameter | Module | Default | To restore stock |
| :--- | :--- | :---: | :--- |
| `disable_aspm` | `mt7921e` | 1 | `disable_aspm=0` |
| `disable_clc` | `mt7921-common` | 1 | `disable_clc=0` |
| `disable_ps` | `mt7921-common` | 1 | `disable_ps=0` |
| `disable_ds` | `mt7921-common` | 1 | `disable_ds=0` |
| `reorder_fast` | `mt76` | 1 | `reorder_fast=0` |

Example, turn firmware power-save back on for a flight:

```bash
sudo modprobe -r mt7921e mt7921-common
sudo modprobe mt7921-common disable_ps=0 disable_ds=0
sudo modprobe mt7921e
```

Check live values under `/sys/module/mt7921_common/parameters/` and `/sys/module/mt76/parameters/`.

---

## Requirements

* Kernel 7.1 or newer with headers. The DKMS config sets `BUILD_EXCLUSIVE_KERNEL_MIN=7.1` because the driver uses `NL80211_IFTYPE_NAN_DATA` and `CFG80211_NAN_MAX_PEER_MAPS`, which do not exist before 7.1, so older kernels refuse to build instead of failing halfway.
* On clang-built kernels (some Arch/CachyOS flavors) build with `CC=clang LLVM=1`. `scripts/build.sh` detects this automatically. Plain `make` with gcc fails on those trees because the kernel passes clang-only flags.

---

## Patch management

One patch, `patch/20261008.467ae2e3-overdrive.patch`, holds every change. `patch/BASE` records the upstream commit it was built from. Versions are date plus upstream SHA, not kernel releases, because the source is openwrt/mt76 master and not a kernel tarball. Current version `20261008.467ae2e3` means base from 2026-10-08 at `467ae2e3`. Newer base, newer version, upgrades sort correctly.

```bash
./scripts/patch.sh status   # applied vs clean stock
./scripts/patch.sh apply    # apply overdrive patch
./scripts/patch.sh revert   # back to clean upstream stock
```

---

## Installation

### Method 1: Arch Linux

```bash
cd packaging
makepkg -si
```

Applies the patch at package time and rebuilds on future `pacman -Syu` kernel updates.

```bash
sudo pacman -R mt792x-overdrive-dkms
```

### Method 2: manual DKMS

Apply the patch first. Bare `dkms add .` on a clean tree builds unpatched stock because DKMS has no pre-build hook here, the PKGBUILD path is what applies it. Note that `dkms add .` copies the whole working tree, including `.git` and any build or packaging artifacts; use the PKGBUILD method, or export with `git archive` and run `./scripts/patch.sh apply` inside the export, if you want a lean `/usr/src` copy.

```bash
./scripts/patch.sh apply
sudo dkms add .
sudo dkms build mt792x-overdrive/20261008.467ae2e3
sudo dkms install mt792x-overdrive/20261008.467ae2e3
```

```bash
sudo dkms remove mt792x-overdrive/20261008.467ae2e3 --all
```

### Method 3: standalone build and load

```bash
./scripts/build.sh     # applies patch and builds
sudo ./scripts/load.sh
sudo ./scripts/unload.sh
```

Or install the built modules with `sudo ./scripts/install.sh` (`uninstall` reverts to stock).

---

## Verification

```bash
modinfo mt7921e | grep version
journalctl -k -b | grep -i mt7921e
iw dev wlan0 station dump | grep -E "signal|bitrate|tx retries|tx failed"
iw dev wlan0 get power_save
```

Healthy signs: version reads `20261008.467ae2e3`, power save reads off, txpower sits near 30 dBm instead of collapsing to single digits after a few rounds.

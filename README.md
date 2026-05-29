# openwrt-ci

Production-grade OpenWrt/LEDE firmware CI for [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede) and [ImmortalWrt](https://github.com/immortalwrt/immortalwrt).

## Device matrix

| 设备 | 代号 | 平台 |
|------|------|------|
| 小米 AX3600 | `xiaomi-ax3600` | ipq807x |
| 小米 AX9000 | `xiaomi-ax9000` | ipq807x |
| 小米 WR30U | `xiaomi-wr30u` | mt7981 |
| 小米 AX6000 | `xiaomi-ax6000` | mt7986 |
| 红米 AX6000 | `redmi-ax6000` | mt7986 |
| 斐讯 K2P | `phicomm-k2p` | mt7621 |
| 小米路由 3G | `xiaomi-3g` | mt7621 |
| 小米 CR660x | `xiaomi-cr660x` | mt7621 |
| NanoPi R2S | `r2s` | armv8 |
| x86_64 | `x86_64` | x86_64 |
| 树莓派 4B | `raspberrypi-4b` | bcm2711 |

Codenames live in `configs/devices.list`; platform slugs in `configs/devices.meta.json`.

## SDK multi-package build

**Actions → Build SDK Package → Run workflow**

| Input | Example |
|-------|---------|
| `devices` | `all` or `x86_64,r2s,xiaomi-ax3600` |
| `packages` | `all` or `luci-app-passwall,luci-app-mosdns` |

- Builds up to **4 devices in parallel**
- Each device job compiles **all selected packages**
- Uses SDK artifact from `build-v2` when available; otherwise falls back to source tree

Package list: `configs/packages.list`

## Quick start (GitHub Actions)

1. Push this repo to GitHub.
2. **Actions → Build Firmware v2 → Run workflow**
   - `source`: `lede` or `immortalwrt`
   - `device`: `x86_64` or `all`
3. Download artifacts from the completed run.

Upstream auto-build: **Check Upstream v2** runs every 6 hours.

## Local build

**Quick (recommended):**

```bash
./scripts/local-build.sh lede x86_64
```

**Manual step-by-step** — see below.

```bash
git clone <this-repo> openwrt-ci && cd openwrt-ci

export SOURCE=lede          # or immortalwrt
export DEVICE=x86_64
export BUILD_DIR="$PWD/build"

# 1. Clone upstream
git clone --depth=1 --branch master \
  https://github.com/coolsnowwolf/lede.git "$BUILD_DIR/$SOURCE"

# 2. Merge configs (common + device + plugins)
./scripts/merge-config.sh "$BUILD_DIR/$SOURCE/.config" \
  "configs/$SOURCE/common.config" \
  "configs/$SOURCE/$DEVICE.config" \
  "configs/custom-plugins.config"

# 3. Banner + files overlay
COMMIT=$(git -C "$BUILD_DIR/$SOURCE" rev-parse --short HEAD)
./scripts/generate-banner.sh "$PWD" "$SOURCE" "$DEVICE" "$COMMIT"
./scripts/install-files-overlay.sh "$BUILD_DIR/$SOURCE"

# 4. Custom feeds (append = non-destructive, overwrite = backup + append)
SOURCE_NAME=$SOURCE ./scripts/setup-custom-packages.sh "$BUILD_DIR/$SOURCE" append

# 5. Build
cd "$BUILD_DIR/$SOURCE"
make defconfig
make -j$(($(nproc) > 1 ? $(nproc) - 1 : 1)) download compile

# 6. Pack output
./scripts/pack-firmware.sh "$BUILD_DIR/$SOURCE" "$PWD/artifacts/local" "$SOURCE" "$DEVICE"
```

> macOS users: install `bash` 5+ (`brew install bash`) and run scripts with that shell.

Requires Ubuntu 22.04 (or Debian-like) with ≥ 30 GB disk and 8 GB RAM.

## Push & trigger CI

```bash
gh auth login   # once, if token expired
git push -u origin main
./scripts/push-and-build.sh Jas0n0ss/openwrt-ci lede x86_64
```

## Config layering

OpenWrt `.config` does not support `#include`. This repo merges fragments at build time:

| Layer | Path | Purpose |
|-------|------|---------|
| Common | `configs/{source}/common.config` | ccache, branding |
| Device | `configs/{source}/{device}.config` | TARGET_* selection |
| Plugins | `configs/custom-plugins.config` | PassWall, MosDNS, etc. |

Later layers override earlier keys with the same `CONFIG_*` name.

## Performance tips

- **Parallelism**: `make -j$(nproc)` can OOM on 7 GB CI runners — workflow caps at `nproc-1`, max 8.
- **ccache**: enabled via `common.config`; per-device cache key includes config hash.
- **Disk**: post-build removes `build_dir/*` and `staging_dir`; use `free-disk-space` action on CI.
- **Cache budget (~10 GB)**: dl (~4 GB) + feeds (~2 GB) + ccache (~4 GB per active device).
- **Full matrix**: 7 devices × ~90 min ≈ use `max-parallel: 4` and 150 min job timeout.

## Directory map

See repository root — matches the structure in the project specification.

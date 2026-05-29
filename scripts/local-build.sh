#!/usr/bin/env bash
# local-build.sh — One-shot local firmware build using repo conventions
#
# Usage:
#   ./scripts/local-build.sh [source] [device]
# Example:
#   ./scripts/local-build.sh lede x86_64

set -euo pipefail

SOURCE="${1:-lede}"
DEVICE="${2:-x86_64}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$REPO_ROOT/build}"
SOURCE_TREE="$BUILD_DIR/$SOURCE"
N="$( (sysctl -n hw.ncpu 2>/dev/null) || nproc )"
JOBS="${JOBS:-$(( N > 1 ? N - 1 : 1 ))}"

case "$SOURCE" in
  lede)         UPSTREAM="https://github.com/coolsnowwolf/lede.git" ;;
  immortalwrt)  UPSTREAM="https://github.com/immortalwrt/immortalwrt.git" ;;
  *) echo "Unknown source: $SOURCE" >&2; exit 1 ;;
esac

bash "$REPO_ROOT/scripts/validate-configs.sh"

mkdir -p "$BUILD_DIR"
if [[ ! -d "$SOURCE_TREE/.git" ]]; then
  git clone --depth=1 --branch master "$UPSTREAM" "$SOURCE_TREE"
fi

bash "$REPO_ROOT/scripts/merge-config.sh" "$SOURCE_TREE/.config" \
  "$REPO_ROOT/configs/$SOURCE/common.config" \
  "$REPO_ROOT/configs/$SOURCE/$DEVICE.config" \
  "$REPO_ROOT/configs/custom-plugins.config"

COMMIT="$(git -C "$SOURCE_TREE" rev-parse --short HEAD)"
bash "$REPO_ROOT/scripts/generate-banner.sh" "$REPO_ROOT" "$SOURCE" "$DEVICE" "$COMMIT"
bash "$REPO_ROOT/scripts/bundle-oh-my-bash.sh" "$REPO_ROOT"
bash "$REPO_ROOT/scripts/install-files-overlay.sh" "$SOURCE_TREE" "$REPO_ROOT"

SOURCE_NAME="$SOURCE" bash "$REPO_ROOT/scripts/setup-custom-packages.sh" "$SOURCE_TREE" append

cd "$SOURCE_TREE"
make defconfig
make -j"$JOBS" download compile

OUT="$REPO_ROOT/artifacts/local-$SOURCE-$DEVICE"
bash "$REPO_ROOT/scripts/pack-firmware.sh" "$SOURCE_TREE" "$OUT" "$SOURCE" "$DEVICE"
echo "Done. Firmware in: $OUT"

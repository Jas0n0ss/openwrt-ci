#!/bin/bash
# scripts/pack-firmware.sh
# 从 bin/targets 筛选最终固件并按命名规范重命名
# 用法：bash scripts/pack-firmware.sh <source> <device_slug>
#   source: lede | immortalwrt
#   device_slug: e.g. r2s, x86_64, redmi-ax6000
# ============================================================
set -euo pipefail

SOURCE="${1:?需要指定 source: lede|immortalwrt}"
DEVICE="${2:?需要指定 device slug}"
OUTPUT_DIR="${GITHUB_WORKSPACE:-$(pwd)}/firmware-output"

mkdir -p "${OUTPUT_DIR}"

log() { echo "[pack] $*"; }

# ============================================================
# 设备元数据映射表
# 格式：device_slug → "openwrt_device_name|platform|arch"
# ============================================================
declare -A DEVICE_META=(
  ["xiaomi-ax3600"]="xiaomi-ax3600|ipq807x|generic"
  ["xiaomi-ax9000"]="xiaomi-ax9000|ipq807x|generic"
  ["xiaomi-wr30u"]="xiaomi-mi-router-wr30u|mediatek|filogic"
  ["xiaomi-ax6000"]="xiaomi-mi-router-ax6000|mediatek|filogic"
  ["redmi-ax6000"]="xiaomi-redmi-router-ax6000|mediatek|filogic"
  ["phicomm-k2p"]="phicomm-k2p|ramips|mt7621"
  ["xiaomi-3g"]="xiaomi-mi-router-3g|ramips|mt7621"
  ["xiaomi-cr660x"]="xiaomi-mi-router-cr6606|ramips|mt7621"
  ["r2s"]="nanopi-r2s|rockchip|armv8"
  ["x86_64"]="generic|x86|64"
  ["raspberrypi-4b"]="rpi-4|bcm27xx|bcm2711"
)

META="${DEVICE_META[${DEVICE}]:-}"
if [ -z "${META}" ]; then
  log "ERROR: 未知设备 ${DEVICE}"
  exit 1
fi

OW_DEVICE_NAME="$(echo "${META}" | cut -d'|' -f1)"
PLATFORM="$(echo "${META}" | cut -d'|' -f2)"
ARCH="$(echo "${META}" | cut -d'|' -f3)"

PREFIX="Jas0n0ss-${SOURCE}-${DEVICE}-${OW_DEVICE_NAME}-${PLATFORM}-${ARCH}"

log "Searching for firmware in bin/targets/${PLATFORM}/${ARCH}/..."

# 只保留可刷写固件，排除杂项
INCLUDE_PATTERNS=(
  "*-sysupgrade.bin"
  "*-sysupgrade.img.gz"
  "*-sysupgrade.tar"
  "*-combined-efi.img.gz"
  "*-combined.img.gz"
  "*-factory.bin"
  "*-squashfs-sysupgrade.bin"
  "*-squashfs-combined-efi.img.gz"
  "*-squashfs-combined.img.gz"
  "*-squashfs-factory.bin"
  "*-ext4-sysupgrade.bin"
  "*-ext4-combined-efi.img.gz"
  "*-ext4-combined.img.gz"
)

EXCLUDE_PATTERNS=(
  "*.manifest"
  "*sha256sums*"
  "*.buildinfo"
  "*.json"
  "packages/"
  "*.ipk"
  "*.zst"
  "*-kernel.bin"
  "*-rootfs*"
  "*-initramfs*"
)

TARGET_DIR="bin/targets/${PLATFORM}/${ARCH}"

if [ ! -d "${TARGET_DIR}" ]; then
  log "ERROR: 目录不存在: ${TARGET_DIR}"
  exit 1
fi

FOUND=0
for pattern in "${INCLUDE_PATTERNS[@]}"; do
  while IFS= read -r -d '' f; do
    fname="$(basename "${f}")"

    # 排除杂项
    skip=false
    for excl in "${EXCLUDE_PATTERNS[@]}"; do
      # shellcheck disable=SC2254
      case "${fname}" in
        ${excl}) skip=true; break ;;
      esac
    done
    $skip && continue

    # 提取类型后缀（sysupgrade.bin / combined-efi.img.gz 等）
    type_suffix="${fname##*-squashfs-}"
    type_suffix="${type_suffix##*-ext4-}"
    # 若没有 squashfs/ext4 中间段，直接取最后部分
    if [ "${type_suffix}" = "${fname}" ]; then
      # 去除设备名前缀，只保留类型部分
      type_suffix="${fname#*-sysupgrade}"
      type_suffix="sysupgrade${type_suffix}"
    fi

    NEW_NAME="${PREFIX}-${type_suffix}"
    log "  ${fname} → ${NEW_NAME}"
    cp "${f}" "${OUTPUT_DIR}/${NEW_NAME}"
    FOUND=$((FOUND + 1))
  done < <(find "${TARGET_DIR}" -maxdepth 1 -name "${pattern}" -print0 2>/dev/null)
done

if [ "${FOUND}" -eq 0 ]; then
  log "WARNING: ${DEVICE} 未找到任何固件文件，检查编译是否成功"
  exit 1
fi

log "打包完成，共 ${FOUND} 个固件文件 → ${OUTPUT_DIR}/"
ls -lh "${OUTPUT_DIR}/"

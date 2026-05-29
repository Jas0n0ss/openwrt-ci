#!/usr/bin/env bash
# pack-firmware.sh — Collect firmware images and generate SHA256SUMS
#
# Usage: pack-firmware.sh <source_tree> <output_dir> <source> <device> <platform>

set -euo pipefail

SOURCE_TREE="${1:?source tree required}"
OUTPUT_DIR="${2:?output dir required}"
SOURCE="${3:?source name required}"
DEVICE="${4:?device required}"
PLATFORM="${5:-$DEVICE}"

BRAND="Jas0n0ss"
BIN_DIR="$SOURCE_TREE/bin/targets"

mkdir -p "$OUTPUT_DIR"

shopt -s globstar nullglob
images=()
while IFS= read -r img; do
  images+=("$img")
done < <(find "$BIN_DIR" -type f \( \
  -name '*sysupgrade*.bin' -o \
  -name '*sysupgrade*.img' -o \
  -name '*factory*.bin' -o \
  -name '*factory*.img' -o \
  -name '*squashfs*.bin' -o \
  -name '*combined*.img.gz' \
\) 2>/dev/null | sort)

if [[ ${#images[@]} -eq 0 ]]; then
  echo "ERROR: no firmware images found under $BIN_DIR" >&2
  exit 1
fi

declare -a packed=()
for img in "${images[@]}"; do
  base="$(basename "$img")"
  ext="${base##*.}"
  if [[ "$base" == *sysupgrade* ]]; then
    type="sysupgrade"
  elif [[ "$base" == *factory* ]]; then
    type="factory"
  elif [[ "$base" == *combined* ]]; then
    type="combined"
  else
    type="firmware"
  fi
  dest="${OUTPUT_DIR}/${BRAND}-${SOURCE}-${DEVICE}-${PLATFORM}-${type}.${ext}"
  cp -f "$img" "$dest"
  packed+=("$dest")
  echo "packed: $(basename "$dest")"
done

(
  cd "$OUTPUT_DIR"
  sha256sum "${packed[@]##*/}" > SHA256SUMS
)
echo "Generated SHA256SUMS with ${#packed[@]} file(s)"

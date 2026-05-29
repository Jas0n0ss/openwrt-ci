#!/usr/bin/env bash
# export-sdk.sh — Collect OpenWrt SDK tarball after full build
#
# Usage: export-sdk.sh <source_tree> <output_dir>

set -euo pipefail

SOURCE_TREE="${1:?source tree required}"
OUTPUT_DIR="${2:?output dir required}"

mkdir -p "$OUTPUT_DIR"

sdk=""
while IFS= read -r f; do
  sdk="$f"
done < <(find "$SOURCE_TREE/bin/targets" -type f \( \
  -iname 'openwrt-sdk-*.tar.xz' -o \
  -iname 'OpenWrt-SDK-*.tar.xz' -o \
  -iname '*sdk*.tar.xz' \
\) 2>/dev/null | sort | tail -1)

if [[ -z "$sdk" || ! -f "$sdk" ]]; then
  echo "SDK tarball not found under $SOURCE_TREE/bin/targets — running make prepare-sdk" >&2
  cd "$SOURCE_TREE"
  make -j"$(nproc)" prepare-sdk
  while IFS= read -r f; do
    sdk="$f"
  done < <(find "$SOURCE_TREE/bin/targets" -type f \( \
    -iname 'openwrt-sdk-*.tar.xz' -o \
    -iname 'OpenWrt-SDK-*.tar.xz' -o \
    -iname '*sdk*.tar.xz' \
  \) 2>/dev/null | sort | tail -1)
fi

if [[ -z "$sdk" || ! -f "$sdk" ]]; then
  echo "ERROR: failed to produce SDK tarball" >&2
  exit 1
fi

cp -f "$sdk" "$OUTPUT_DIR/"
echo "sdk_path=$OUTPUT_DIR/$(basename "$sdk")"
echo "Exported SDK: $(basename "$sdk")"

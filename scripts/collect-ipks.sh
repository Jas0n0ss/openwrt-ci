#!/usr/bin/env bash
# collect-ipks.sh — Gather built .ipk files from OpenWrt tree into output dir
#
# Usage: collect-ipks.sh <tree_dir> <output_dir>
# Prints: count=N and dir=PATH (for eval in CI)

set -euo pipefail

TREE="${1:?tree dir required}"
OUT="${2:?output dir required}"

mkdir -p "$OUT"

while IFS= read -r ipk; do
  cp -f "$ipk" "$OUT/$(basename "$ipk")"
done < <(find "$TREE" -type f \( \
  -path '*/bin/packages/*/*.ipk' -o \
  -path '*/build_dir/target-*/packages/*/*.ipk' \
\) 2>/dev/null | sort -u)

count="$(find "$OUT" -maxdepth 1 -name '*.ipk' 2>/dev/null | wc -l | tr -d ' ')"
echo "count=$count"
echo "dir=$OUT"
echo "Collected $count IPK(s) -> $OUT" >&2

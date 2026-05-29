#!/usr/bin/env bash
# build-packages.sh — Compile multiple OpenWrt packages in source or SDK tree
#
# Usage: build-packages.sh <tree_dir> <jobs> <pkg1> [pkg2 ...]

set -euo pipefail

TREE="${1:?tree dir required}"
JOBS="${2:?jobs required}"
shift 2
packages=("$@")

if [[ ${#packages[@]} -eq 0 ]]; then
  echo "ERROR: no packages specified" >&2
  exit 1
fi

cd "$TREE"

for pkg in "${packages[@]}"; do
  pkg="${pkg#package/}"
  pkg="${pkg%/compile}"
  echo "=== Building package/$pkg ==="
  make "package/${pkg}/compile" -j"$JOBS" V=s
done

echo "Built ${#packages[@]} package(s)"

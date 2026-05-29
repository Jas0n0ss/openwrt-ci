#!/usr/bin/env bash
# install-files-overlay.sh — Copy files/ overlay into OpenWrt source tree
#
# Usage: install-files-overlay.sh <source_tree> [repo_root]

set -euo pipefail

SOURCE_TREE="${1:?source tree path required}"
REPO_ROOT="${2:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
OVERLAY_DIR="$REPO_ROOT/files"
TARGET="$SOURCE_TREE/files"

if [[ ! -d "$OVERLAY_DIR" ]]; then
  echo "ERROR: overlay directory not found: $OVERLAY_DIR" >&2
  exit 1
fi

mkdir -p "$TARGET"
rsync -a --delete "$OVERLAY_DIR/" "$TARGET/"
echo "Installed overlay from $OVERLAY_DIR -> $TARGET"

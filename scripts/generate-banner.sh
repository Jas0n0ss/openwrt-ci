#!/usr/bin/env bash
# generate-banner.sh — Render /etc/banner from template (does not mutate template)
#
# Usage: generate-banner.sh <repo_root> <source> <device> <commit>

set -euo pipefail

REPO_ROOT="${1:?repo root required}"
SOURCE="${2:?source required}"
DEVICE="${3:?device required}"
COMMIT="${4:?commit required}"

TEMPLATE="$REPO_ROOT/files/etc/banner.template"
OUTPUT="$REPO_ROOT/files/etc/banner"

if [[ ! -f "$TEMPLATE" ]]; then
  TEMPLATE="$OUTPUT"
fi

sed \
  -e "s|__BUILD_SOURCE__|${SOURCE}|g" \
  -e "s|__BUILD_DEVICE__|${DEVICE}|g" \
  -e "s|__BUILD_COMMIT__|${COMMIT}|g" \
  "$TEMPLATE" > "$OUTPUT"

echo "Rendered banner -> $OUTPUT (source=$SOURCE device=$DEVICE commit=${COMMIT:0:8})"

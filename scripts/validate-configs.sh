#!/usr/bin/env bash
# validate-configs.sh — Ensure every device in devices.list has config for each source

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIST="$REPO_ROOT/configs/devices.list"
SOURCES=(lede immortalwrt)
errors=0

while IFS= read -r device || [[ -n "$device" ]]; do
  device="$(echo "$device" | sed 's/#.*//;s/[[:space:]]//g')"
  [[ -z "$device" ]] && continue

  for source in "${SOURCES[@]}"; do
    cfg="$REPO_ROOT/configs/$source/$device.config"
    if [[ ! -f "$cfg" ]]; then
      echo "MISSING: $cfg" >&2
      errors=$((errors + 1))
    elif ! grep -q '^CONFIG_TARGET_' "$cfg"; then
      echo "WARN: no CONFIG_TARGET_* in $cfg" >&2
    fi
  done
done < "$LIST"

common="$REPO_ROOT/configs/custom-plugins.config"
if [[ ! -f "$common" ]]; then
  echo "MISSING: $common" >&2
  errors=$((errors + 1))
fi

if [[ $errors -gt 0 ]]; then
  echo "Validation failed with $errors error(s)" >&2
  exit 1
fi

echo "All device configs present for: ${SOURCES[*]}"

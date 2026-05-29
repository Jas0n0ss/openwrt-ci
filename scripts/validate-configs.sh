#!/usr/bin/env bash
# validate-configs.sh — Ensure devices.list, meta.json, and per-source configs align

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIST="$REPO_ROOT/configs/devices.list"
META="$REPO_ROOT/configs/devices.meta.json"
SOURCES=(lede immortalwrt)
errors=0

if ! python3 - "$LIST" "$META" <<'PY'
import json, sys
list_path, meta_path = sys.argv[1], sys.argv[2]
with open(meta_path) as f:
    meta = json.load(f)
devices = []
for line in open(list_path):
    line = line.split("#", 1)[0].strip()
    if line:
        devices.append(line)
missing_meta = [d for d in devices if d not in meta]
if missing_meta:
    print("MISSING meta entries:", ", ".join(missing_meta), file=sys.stderr)
    sys.exit(2)
PY
then
  errors=$((errors + 1))
fi

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

for f in custom-plugins.config packages.list; do
  if [[ ! -f "$REPO_ROOT/configs/$f" ]]; then
    echo "MISSING: configs/$f" >&2
    errors=$((errors + 1))
  fi
done

if [[ $errors -gt 0 ]]; then
  echo "Validation failed with $errors error(s)" >&2
  exit 1
fi

echo "All device configs present for: ${SOURCES[*]}"

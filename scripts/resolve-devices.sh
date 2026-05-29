#!/usr/bin/env bash
# resolve-devices.sh — Output JSON array of devices for workflow matrix
#
# Usage: resolve-devices.sh <device_input> [devices.list]

set -euo pipefail

INPUT="${1:-all}"
LIST="${2:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/configs/devices.list}"

read_devices() {
  grep -vE '^\s*(#|$)' "$LIST" | sed 's/[[:space:]]//g'
}

if [[ "$INPUT" == "all" ]]; then
  devices=()
  while IFS= read -r line; do
    devices+=("$line")
  done < <(read_devices)
else
  devices=("$INPUT")
fi

if [[ ${#devices[@]} -eq 0 ]]; then
  echo "ERROR: no devices resolved" >&2
  exit 1
fi

# Emit JSON array for GitHub Actions fromJSON()
printf '%s\n' "${devices[@]}" | python3 -c "import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))"

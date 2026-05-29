#!/usr/bin/env bash
# resolve-packages.sh — Output JSON array of package names for workflow matrix
#
# Usage: resolve-packages.sh <input> [packages.list]
#   input: all | comma-separated package names

set -euo pipefail

INPUT="${1:-all}"
LIST="${2:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/configs/packages.list}"

read_packages() {
  grep -vE '^\s*(#|$)' "$LIST" | sed 's/[[:space:]]//g'
}

if [[ "$INPUT" == "all" ]]; then
  packages=()
  while IFS= read -r line; do
    packages+=("$line")
  done < <(read_packages)
elif [[ "$INPUT" == *","* ]]; then
  IFS=',' read -r -a packages <<< "$INPUT"
  for i in "${!packages[@]}"; do
    packages[$i]="$(echo "${packages[$i]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  done
else
  packages=("$INPUT")
fi

if [[ ${#packages[@]} -eq 0 ]]; then
  echo "ERROR: no packages resolved" >&2
  exit 1
fi

printf '%s\n' "${packages[@]}" | python3 -c "import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))"

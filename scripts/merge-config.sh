#!/usr/bin/env bash
# merge-config.sh — Merge layered OpenWrt .config fragments into a single .config
#
# Usage: merge-config.sh <output> <fragment1> [fragment2 ...]
# Later fragments override earlier ones for duplicate CONFIG_* keys.

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <output> <fragment1> [fragment2 ...]" >&2
  exit 1
fi

output="$1"
shift
tmp="$(mktemp)"
declare -A kv

for fragment in "$@"; do
  if [[ ! -f "$fragment" ]]; then
    echo "ERROR: config fragment not found: $fragment" >&2
    exit 1
  fi
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [[ -z "$line" ]] && continue
    key="${line%%=*}"
    kv["$key"]="$line"
  done < "$fragment"
done

{
  for key in $(printf '%s\n' "${!kv[@]}" | sort); do
    echo "${kv[$key]}"
  done
} > "$tmp"

mv "$tmp" "$output"
echo "Merged ${#kv[@]} config keys -> $output"

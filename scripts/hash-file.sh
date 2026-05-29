#!/usr/bin/env bash
# hash-file.sh — Print first 12 chars of SHA256 for cache keys
#
# Usage: hash-file.sh <file>

set -euo pipefail

FILE="${1:?file required}"
if [[ ! -f "$FILE" ]]; then
  echo "missing"
  exit 0
fi

sha256sum "$FILE" | awk '{print substr($1,1,12)}'

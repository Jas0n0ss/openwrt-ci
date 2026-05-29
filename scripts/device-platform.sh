#!/usr/bin/env bash
# device-platform.sh — Lookup platform slug from configs/devices.meta.json
#
# Usage: device-platform.sh <device_codename>

set -euo pipefail

DEVICE="${1:?device codename required}"
META="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/configs/devices.meta.json"

python3 - "$DEVICE" "$META" <<'PY'
import json, sys
device, path = sys.argv[1], sys.argv[2]
with open(path) as f:
    meta = json.load(f)
if device not in meta:
    print(device, file=sys.stderr)
    sys.exit(1)
print(meta[device]["platform"])
PY

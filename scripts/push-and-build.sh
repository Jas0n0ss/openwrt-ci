#!/usr/bin/env bash
# push-and-build.sh — Push repo and trigger x86_64 smoke build on GitHub Actions
#
# Prerequisites: gh auth login

set -euo pipefail

REPO="${1:-Jas0n0ss/openwrt-ci}"
SOURCE="${2:-lede}"
DEVICE="${3:-x86_64}"

git push -u origin HEAD

gh workflow run build-v2.yml \
  --repo "$REPO" \
  -f "source=$SOURCE" \
  -f "device=$DEVICE" \
  -f "upload_release=false"

echo "Build triggered. Watch: https://github.com/$REPO/actions"

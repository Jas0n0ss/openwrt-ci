#!/usr/bin/env bash
# setup-custom-packages.sh — Integrate third-party feeds and packages
#
# Usage:
#   setup-custom-packages.sh <source_tree> [append|overwrite]
#
# Modes:
#   append    — prepend custom feeds + append if missing (default)
#   overwrite — backup feeds.conf.default, prepend custom feeds

set -euo pipefail

SOURCE_TREE="${1:?source tree path required}"
MODE="${2:-append}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FEEDS_CONF="$SOURCE_TREE/feeds.conf.default"
SOURCE_NAME="${SOURCE_NAME:-$(basename "$SOURCE_TREE")}"
PATCHES_DIR="$REPO_ROOT/patches/${SOURCE_NAME}"
CUSTOM_BLOCK_BEGIN="# --- openwrt-ci custom feeds ---"
CUSTOM_BLOCK_END="# --- end openwrt-ci custom feeds ---"

log() { echo "[setup-custom-packages] $*"; }

# PassWall main branch; MosDNS/TurboACC/Aurora from community feeds
read -r -d '' CUSTOM_FEEDS <<'EOF' || true
src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main
src-git passwall https://github.com/Openwrt-Passwall/openwrt-passwall.git;main
src-git passwall2 https://github.com/Openwrt-Passwall/openwrt-passwall2.git;main
src-git mosdns https://github.com/sbwml/luci-app-mosdns.git;master
src-git turboacc https://github.com/chenmozhijin/turboacc.git;luci
src-git aurora https://github.com/gngpp/luci-theme-aurora.git;main
EOF

feed_exists() {
  local name="$1"
  grep -qE "^src-[^[:space:]]+[[:space:]]+${name}[[:space:]]" "$FEEDS_CONF" 2>/dev/null
}

prepend_custom_feeds() {
  if grep -qF "$CUSTOM_BLOCK_BEGIN" "$FEEDS_CONF" 2>/dev/null; then
    log "custom feed block already present"
    return 0
  fi

  local tmp
  tmp="$(mktemp)"
  {
    echo "$CUSTOM_BLOCK_BEGIN"
    echo "$CUSTOM_FEEDS"
    echo "$CUSTOM_BLOCK_END"
    echo ""
    cat "$FEEDS_CONF"
  } > "$tmp"
  mv "$tmp" "$FEEDS_CONF"
  log "prepended custom feeds block"
}

append_missing_feeds() {
  while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    local name
    name="$(echo "$line" | awk '{print $2}')"
    if feed_exists "$name"; then
      log "feed '$name' already present"
    else
      echo "$line" >> "$FEEDS_CONF"
      log "appended feed: $name"
    fi
  done <<< "$CUSTOM_FEEDS"
}

remove_stale_passwall() {
  # LEDE ships older PassWall in luci feed — remove to avoid version conflicts
  local paths=(
    "$SOURCE_TREE/feeds/luci/applications/luci-app-passwall"
    "$SOURCE_TREE/feeds/luci/applications/luci-app-passwall2"
  )
  for p in "${paths[@]}"; do
    if [[ -d "$p" ]]; then
      rm -rf "$p"
      log "removed stale bundled package: $p"
    fi
  done
}

apply_patches() {
  if [[ ! -d "$PATCHES_DIR" ]]; then
    log "no patches directory: $PATCHES_DIR"
    return 0
  fi
  shopt -s nullglob
  local patches=("$PATCHES_DIR"/*.patch)
  if [[ ${#patches[@]} -eq 0 ]]; then
    log "no patches to apply"
    return 0
  fi
  for patch in "${patches[@]}"; do
    log "applying patch: $(basename "$patch")"
    patch -p1 -d "$SOURCE_TREE" < "$patch"
  done
}

install_feed_packages() {
  cd "$SOURCE_TREE"

  log "feeds update -a"
  ./scripts/feeds update -a

  remove_stale_passwall

  log "feeds install passwall packages (forced, passwall_packages feed)"
  ./scripts/feeds install -a -f -p passwall_packages || true
  ./scripts/feeds install -a -f -p passwall || true
  ./scripts/feeds install -a -f -p passwall2 || true
  ./scripts/feeds install -a -f -p mosdns || true
  ./scripts/feeds install -a -f -p turboacc || true
  ./scripts/feeds install -a -f -p aurora || true

  log "feeds install remaining feeds"
  ./scripts/feeds install -a
}

main() {
  if [[ ! -f "$FEEDS_CONF" ]]; then
    echo "ERROR: feeds.conf.default not found in $SOURCE_TREE" >&2
    exit 1
  fi

  case "$MODE" in
    append)
      prepend_custom_feeds
      append_missing_feeds
      ;;
    overwrite)
      cp "$FEEDS_CONF" "${FEEDS_CONF}.bak.$(date +%s)"
      prepend_custom_feeds
      ;;
    *)
      echo "ERROR: unknown mode '$MODE' (use append or overwrite)" >&2
      exit 1
      ;;
  esac

  apply_patches
  install_feed_packages
  log "done"
}

main "$@"

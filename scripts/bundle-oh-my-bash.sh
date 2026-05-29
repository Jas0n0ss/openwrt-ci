#!/usr/bin/env bash
# bundle-oh-my-bash.sh — Stage Oh My Bash files into overlay (optional pre-build step)
#
# Usage: bundle-oh-my-bash.sh <repo_root>

set -euo pipefail

REPO_ROOT="${1:?repo root required}"
OMB_DIR="$REPO_ROOT/files/usr/lib/oh-my-bash"
BASHRC="$REPO_ROOT/files/root/.bashrc"

mkdir -p "$OMB_DIR"

if [[ ! -f "$BASHRC" ]]; then
  cat > "$BASHRC" <<'EOF'
export OMB_THEME="agnoster"
if [ -f /usr/lib/oh-my-bash/oh-my-bash.sh ]; then
  source /usr/lib/oh-my-bash/oh-my-bash.sh
fi
EOF
fi

# Oh My Bash is installed via OpenWrt package feed; this script ensures
# overlay directory exists for any custom OMB tweaks.
echo "Oh My Bash overlay directory ready: $OMB_DIR"

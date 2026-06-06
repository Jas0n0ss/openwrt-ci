#!/bin/bash
# scripts/install-files-overlay.sh
# 在构建阶段将 oh-my-bash 克隆到 files/ overlay，随固件打包进 root 家目录
# 用法：bash scripts/install-files-overlay.sh
# ============================================================
set -euo pipefail

OMB_TARGET="files/root/.oh-my-bash"
OMB_REPO="https://github.com/ohmybash/oh-my-bash.git"

if [ -d "${OMB_TARGET}" ]; then
  echo "[ombs] oh-my-bash already present at ${OMB_TARGET}, skipping."
  exit 0
fi

echo "[ombs] Cloning oh-my-bash..."
git clone --depth 1 "${OMB_REPO}" "${OMB_TARGET}"

# 写入 root 的 .bashrc（追加，不覆盖）
BASHRC="files/root/.bashrc"
mkdir -p "$(dirname "${BASHRC}")"

cat > "${BASHRC}" << 'EOF'
# .bashrc — Jas0n0ss OpenWrt build
export OSH="$HOME/.oh-my-bash"
OSH_THEME="font"
OMB_USE_SUDO=true

plugins=(git)
completions=(git)
aliases=(general)

source "$OSH/oh-my-bash.sh"
EOF

echo "[ombs] oh-my-bash installed → ${OMB_TARGET}"

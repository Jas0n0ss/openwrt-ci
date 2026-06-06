#!/bin/bash
# scripts/setup-custom-packages.sh
# 配置 feeds 并注入自定义软件包
# 用法：bash scripts/setup-custom-packages.sh <source>
#   source: lede | immortalwrt
# ============================================================
set -euo pipefail

SOURCE="${1:-lede}"
REPO_ROOT="$(pwd)"

log() { echo "[setup] $*"; }

# ============================================================
# 1. 追加自定义 feeds
# ============================================================
log "Configuring custom feeds for ${SOURCE}..."

# PassWall feeds
if ! grep -q "passwall_packages" feeds.conf.default 2>/dev/null; then
  echo "src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git;main" >> feeds.conf.default
  echo "src-git passwall https://github.com/xiaorouji/openwrt-passwall.git;main" >> feeds.conf.default
fi

# MosDNS (sbwml v5)
if ! grep -q "luci-app-mosdns" feeds.conf.default 2>/dev/null; then
  echo "src-git mosdns https://github.com/sbwml/luci-app-mosdns.git;v5" >> feeds.conf.default
fi

# Aurora 主题
if ! grep -q "luci-theme-aurora" feeds.conf.default 2>/dev/null; then
  echo "src-git aurora https://github.com/fkkt-55/luci-theme-aurora.git;main" >> feeds.conf.default
fi

# TurboACC
if ! grep -q "turboacc" feeds.conf.default 2>/dev/null; then
  echo "src-git turboacc https://github.com/chenmozhijin/turboacc.git;package" >> feeds.conf.default
fi

# ============================================================
# 2. 更新 & 安装 feeds
# ============================================================
log "Updating feeds..."
./scripts/feeds update -a

log "Installing feeds..."
./scripts/feeds install -a

# 解决潜在的 dnsmasq 冲突：确保只保留一个 dnsmasq
# feeds 里可能同时存在 dnsmasq 和 dnsmasq-full，先删除基础包
if [ -d "feeds/base/package/network/services/dnsmasq" ]; then
  log "Removing base dnsmasq to avoid conflict with dnsmasq-full..."
  rm -rf feeds/base/package/network/services/dnsmasq || true
fi

# ============================================================
# 3. 再次安装（确保自定义 feeds 覆盖成功）
# ============================================================
./scripts/feeds install -a -f

# ============================================================
# 4. 注入 overlay 文件
# ============================================================
log "Copying overlay files..."
if [ -d "${REPO_ROOT}/files" ]; then
  cp -r "${REPO_ROOT}/files/." ./files/
fi

log "Custom packages setup complete."

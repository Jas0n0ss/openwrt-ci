#!/bin/bash
# scripts/setup-custom-packages.sh
# 配置 feeds 并注入自定义软件包
# 用法：bash scripts/setup-custom-packages.sh <source>
#   source: lede | immortalwrt
#   在源码树根目录（working-directory）下执行
# ============================================================
set -euo pipefail

# 第三方仓库若返回 404/私有，git 会转而向终端索要用户名；CI 非交互环境下
# 这会直接报 "could not read Username" 并以 128 退出。禁用交互让其立即失败。
export GIT_TERMINAL_PROMPT=0
export GIT_ASKPASS=true

SOURCE="${1:-lede}"
# 构建器仓库根目录 = 脚本所在目录的上一级，与当前 cwd（源码树）无关
BUILDER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { echo "[setup] $*"; }

# ============================================================
# 1. feed 型仓库（自身即 feed 目录结构）→ 追加到 feeds.conf.default
#    PassWall 已迁移至 Openwrt-Passwall 组织（xiaorouji 旧库已下架）
# ============================================================
add_feed() { # name url ref
  local name="$1" url="$2" ref="$3"
  if grep -qE "[[:space:]]${name}[[:space:]]" feeds.conf.default 2>/dev/null; then
    log "feed exists: ${name}"
    return 0
  fi
  echo "src-git ${name} ${url};${ref}" >> feeds.conf.default
  log "added feed: ${name}"
}

add_feed passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git main
add_feed passwall          https://github.com/Openwrt-Passwall/openwrt-passwall.git          main
add_feed turboacc          https://github.com/chenmozhijin/turboacc.git                      package

# ============================================================
# 2. 单包仓库（非 feed 结构）→ clone 进 package/
#    第 4 参数 required=1：克隆失败即终止；=0：失败仅告警（主题等可选项）
# ============================================================
clone_pkg() { # url ref dest required
  local url="$1" ref="$2" dest="package/$3" required="${4:-1}"
  if [ -d "${dest}/.git" ]; then
    log "package exists: $3"
    return 0
  fi
  rm -rf "${dest}"
  log "cloning $3 (${ref}) ..."
  if ! git clone --depth=1 --branch "${ref}" "${url}" "${dest}"; then
    rm -rf "${dest}"
    if [ "${required}" = "1" ]; then
      log "ERROR: 必需包克隆失败：${url}"
      exit 1
    fi
    log "WARN: 可选包克隆失败，已跳过：${url}"
  fi
}

mkdir -p package
clone_pkg https://github.com/sbwml/luci-app-mosdns.git    v5     mosdns            1
clone_pkg https://github.com/sbwml/v2ray-geodata.git      master v2ray-geodata     1
clone_pkg https://github.com/eamonxg/luci-theme-aurora.git master luci-theme-aurora 0

# ============================================================
# 3. 更新 feeds，并清理与 package/ 克隆重复或与官方 PassWall 冲突的项
# ============================================================
log "feeds update -a"
./scripts/feeds update -a

for dup in \
  feeds/packages/net/mosdns \
  feeds/luci/applications/luci-app-mosdns \
  feeds/packages/net/v2ray-geodata \
  feeds/luci/applications/luci-app-passwall ; do
  [ -d "${dup}" ] && rm -rf "${dup}" && log "removed conflicting feed path: ${dup}"
done

log "feeds install -a"
./scripts/feeds install -a

# dnsmasq-full 冲突：移除基础 dnsmasq，避免与 dnsmasq-full 二选一冲突
if [ -d feeds/base/package/network/services/dnsmasq ]; then
  log "removing base dnsmasq (use dnsmasq-full)"
  rm -rf feeds/base/package/network/services/dnsmasq || true
fi

# 强制覆盖安装，确保自定义 feeds 生效
./scripts/feeds install -a -f

# ============================================================
# 4. 注入 overlay 文件（uci-defaults / profile.d 等）
#    源自构建器仓库的 files/，而非源码树自身
# ============================================================
if [ -d "${BUILDER_ROOT}/files" ]; then
  log "copying overlay files from builder repo"
  mkdir -p files
  cp -r "${BUILDER_ROOT}/files/." ./files/
fi

log "custom packages setup complete."

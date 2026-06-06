#!/bin/bash
# scripts/generate-banner.sh
# 生成 SSH Banner 并写入 files/etc/banner
# 用法：bash scripts/generate-banner.sh <source>
#   source: lede | immortalwrt
# ============================================================
set -euo pipefail

SOURCE="${1:-lede}"
OUTPUT="files/etc/banner"
mkdir -p "$(dirname "${OUTPUT}")"

if [ "${SOURCE}" = "lede" ]; then
cat > "${OUTPUT}" << 'LEDE_BANNER'
     _________
    /        /\      _    ___ ___  ___
   /  LE    /  \    | |  | __|   \| __|
  /    DE  /    \   | |__| _|| |) | _|
 /________/  LE  \  |____|___|___/|___|
 \        \   DE /
  \    LE  \    /  -----------------------------------------------
   \  DE    \  /    LEDE | @Jas0n0ss | LuCI: http://10.10.10.1/
    \________\/    https://github.com/Jas0n0ss/openwrt-lede-builder
-------------------------------------------------------------------
LEDE_BANNER

else
cat > "${OUTPUT}" << 'IMRT_BANNER'
     _________
    /        /\      _    ___ ___  ___
   /  IM    /  \    | |  | __|   \| __|
  /    RT  /    \   | |__| _|| |) | _|
 /________/  AL  \  |____|___|___/|___|
 \        \  WRT /
  \    IM  \    /  -----------------------------------------------
   \  RT    \  /    ImmortalWrt | @Jas0n0ss | LuCI: http://10.10.10.1/
    \________\/    https://github.com/Jas0n0ss/openwrt-lede-builder
-------------------------------------------------------------------
IMRT_BANNER

fi

echo "[banner] Generated ${OUTPUT} for ${SOURCE}"

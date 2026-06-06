# OpenWrt Builder — Jas0n0ss

自动编译 **LEDE** 和 **ImmortalWrt** 固件，为指定路由器预装常用插件，刷机即用。

---

## 支持设备（11 台）

| 代号 | 平台 | SoC |
|---|---|---|
| `xiaomi-ax3600` | ipq807x | IPQ8074 |
| `xiaomi-ax9000` | ipq807x | IPQ8072 |
| `xiaomi-wr30u` | mediatek/filogic | MT7981 |
| `xiaomi-ax6000` | mediatek/filogic | MT7986A |
| `redmi-ax6000` | mediatek/filogic | MT7986A |
| `phicomm-k2p` | ramips/mt7621 | MT7621 |
| `xiaomi-3g` | ramips/mt7621 | MT7621 |
| `xiaomi-cr660x` | ramips/mt7621 | MT7621 |
| `r2s` | rockchip/armv8 | RK3328 |
| `x86_64` | x86/64 | — |
| `raspberrypi-4b` | bcm27xx/bcm2711 | BCM2711 |

---

## 预装插件

| 插件 | 功能 |
|---|---|
| PassWall (+ Hysteria / sing-box) | 科学上网 |
| MosDNS v5 (sbwml) | DNS 分流 |
| TurboACC (BBR + nft-fullcone) | 网络加速 |
| TTYD | 网页终端 |
| luci-app-arpbind | IP/MAC 绑定 |
| luci-theme-aurora | LuCI 主题 |

---

## 固件默认设置

| 项目 | 值 |
|---|---|
| LAN IP | `10.10.10.1` |
| DHCP 范围 | `10.10.10.100 – 10.10.10.250` |
| 默认密码 | `root / password` |
| 时区 | `Asia/Shanghai` |
| LuCI 语言 | 简体中文 |
| LuCI 主题 | Aurora |

---

## 使用方法

1. Fork 本仓库
2. `Actions` → 选择 `Build LEDE` 或 `Build ImmortalWrt`
3. 点击 **Run workflow**
4. 等待编译完成，固件在 **Releases** 中下载

ImmortalWrt 还会在每周日自动编译。

---

## 固件命名格式

```
Jas0n0ss-<source>-<device>-<openwrt_name>-<platform>-<arch>-<type>.<ext>
```

示例：
- `Jas0n0ss-lede-r2s-nanopi-r2s-rockchip-armv8-sysupgrade.img.gz`
- `Jas0n0ss-immortalwrt-redmi-ax6000-xiaomi-redmi-router-ax6000-mediatek-filogic-sysupgrade.bin`

---

## 仓库结构

```
configs/
  devices.list                  # 设备列表
  lede/
    common.config               # LEDE 公共配置
    <device>.config             # 设备专属配置
  immortalwrt/
    common.config               # ImmortalWrt 公共配置
    <device>.config
  custom-plugins.config         # TurboACC 等（defconfig 后注入）
  snippets/
scripts/
  setup-custom-packages.sh      # feeds 配置 + 自定义包
  pack-firmware.sh              # 固件筛选 + 重命名
  generate-banner.sh            # SSH banner 生成
  install-files-overlay.sh      # oh-my-bash 打包进固件
files/
  etc/
    uci-defaults/99-custom-settings   # 首次启动网络/UI 配置
    profile.d/oh-my-bash.sh
  root/
    .oh-my-bash/                # oh-my-bash（由脚本安装）
    .bashrc
.github/workflows/
  _build.yml                    # 可复用编译工作流（被下面两个调用）
  build-lede.yml                # 调用层：LEDE
  build-immortalwrt.yml         # 调用层：ImmortalWrt（含每周日定时）
```

---

## 关于 TurboACC Kconfig 循环依赖

`luci-app-turboacc` ↔ `kmod-nft-fullcone` ↔ `dnsmasq-full` ↔ `nftables-json` 之间存在 Kconfig 循环依赖。

处理方式：**先执行 `make defconfig`（不含 TurboACC），再追加 `custom-plugins.config`，最后 `make oldconfig`**。

---

*Maintained by [@Jas0n0ss](https://github.com/Jas0n0ss)*

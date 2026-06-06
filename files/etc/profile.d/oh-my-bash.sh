#!/bin/bash
# files/etc/profile.d/oh-my-bash.sh
# root 使用 bash + oh-my-bash（如果已安装）

# 设置默认 shell 为 bash（如果当前不是）
export SHELL=/bin/bash

# oh-my-bash 初始化
OMB_DIR="${HOME}/.oh-my-bash"
if [ -f "${OMB_DIR}/oh-my-bash.sh" ]; then
  export OSH="${OMB_DIR}"
  export OSH_THEME="font"
  export OMB_USE_SUDO=true
  export COMPLETION_WAITING_DOTS="true"

  plugins=(git)
  completions=(git)
  aliases=(general)

  source "${OMB_DIR}/oh-my-bash.sh"
fi

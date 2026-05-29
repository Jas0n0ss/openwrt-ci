# Oh My Bash — minimal preset for Jas0n0ss firmware
export OMB_THEME="agnoster"
export OMB_PROMPT_SHOW_PYTHON_VERSION=false
export OMB_PROMPT_SHOW_PYTHON_VENV=false

if [ -f /usr/lib/oh-my-bash/oh-my-bash.sh ]; then
  source /usr/lib/oh-my-bash/oh-my-bash.sh
fi

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

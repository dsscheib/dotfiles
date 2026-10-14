# shellcheck shell=bash
# ==============================================================================
# SHARED BASH/ZSH CONFIGURATION
# Sourced by ~/.bashrc and ~/.zshrc. Fish keeps its own copy in config.fish.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. ENVIRONMENT VARIABLES & PATHS
# ------------------------------------------------------------------------------
# Listed lowest priority first: each entry is prepended, so the last one wins.
for dir in "/usr/local/bin" "$HOME/.local/share/flatpak/exports/bin" \
  "/var/lib/flatpak/exports/bin" "$HOME/go/bin" "$HOME/.cargo/bin" \
  "$HOME/.local/bin" "$HOME/bin"; do
  if [[ -d "$dir" && ":$PATH:" != *":$dir:"* ]]; then
    export PATH="$dir:$PATH"
  fi
done
unset dir

# Called after Mise activation so user-local and managed tools are visible.
setup_editor() {
  export PAGER="${PAGER:-less}"
  if command -v nvim &>/dev/null; then
    export EDITOR="${EDITOR:-nvim}"
    export VISUAL="${VISUAL:-${EDITOR}}"
    export MANPAGER="${MANPAGER:-nvim +Man!}" MANWIDTH="${MANWIDTH:-999}"
    alias vim=nvim
  else
    export EDITOR="${EDITOR:-vi}"
    export VISUAL="${VISUAL:-${EDITOR}}"
  fi
}

if [[ -d "$HOME/STMicroelectronics/STM32Cube/STM32CubeProgrammer/bin" ]]; then
  export STM32_PRG_PATH="$HOME/STMicroelectronics/STM32Cube/STM32CubeProgrammer/bin"
fi

# ------------------------------------------------------------------------------
# 2. ALIASES & UTILITIES
# ------------------------------------------------------------------------------
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

if command -v eza &>/dev/null; then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza -lh --icons --group-directories-first"
  alias la="eza -lah --icons --group-directories-first"
  alias tree="eza --tree --icons"
else
  alias ls="ls --color=auto"
  alias ll="ls -lh --color=auto"
  alias la="ls -lah --color=auto"
fi

if command -v bat &>/dev/null; then
  alias cat="bat --style=plain"
elif command -v batcat &>/dev/null; then
  alias cat="batcat --style=plain"
fi

alias grep="grep --color=auto"

# Pop!_OS / Debian (apt + flatpak) only
alias update="sudo apt update && sudo apt upgrade -y && flatpak update -y"
alias cleanup="sudo apt autoremove -y && sudo apt autoclean && flatpak uninstall --unused -y"

alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"

alias sudo="sudo "

# Synchronize tmux's default shell with the shell invoking the client. This
# updates an already-running server so new panes use the current shell.
tmux() {
  local current_shell
  current_shell=$(readlink -f "/proc/$$/exe") || return
  command tmux set-option -g default-shell "$current_shell" >/dev/null 2>&1 || true
  command tmux "$@"
}

# TMUX ALIASES
alias tmux-install="~/.local/share/tmux/plugins/tpm/bin/install_plugins"
alias tmux-update="~/.local/share/tmux/plugins/tpm/bin/update_plugins all"
alias tmux-clean="~/.local/share/tmux/plugins/tpm/bin/clean_plugins"

if command -v fzf &>/dev/null; then
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --color=header:italic"
fi

# ------------------------------------------------------------------------------
# 3. WELCOME BANNER (call at the end of the rc file)
# ------------------------------------------------------------------------------
show_banner() {
  [[ -n "${TMUX:-}" || -n "${NVIM:-}" ]] && return
  if command -v fastfetch &>/dev/null; then
    fastfetch
  elif command -v neofetch &>/dev/null; then
    neofetch
  fi
}

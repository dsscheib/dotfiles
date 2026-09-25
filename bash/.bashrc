# ==============================================================================
# ML4W-INSPIRED BASH CONFIGURATION
# Save to: ~/.bashrc
# ==============================================================================

case $- in
*i*) ;;
*) return ;;
esac

# ------------------------------------------------------------------------------
# 1. ENVIRONMENT VARIABLES & PATHS
# ------------------------------------------------------------------------------
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export LANG="en_US.UTF-8"

# Use Neovim as default man page pager
if command -v nvim &>/dev/null; then
  export MANPAGER="nvim +Man!"
  export MANWIDTH=999
fi

for dir in "$HOME/bin" "$HOME/.local/bin" "$HOME/.cargo/bin" \
  "/var/lib/flatpak/exports/bin" "$HOME/.local/share/flatpak/exports/bin" \
  "/usr/local/bin"; do
  if [[ -d "$dir" && ":$PATH:" != *":$dir:"* ]]; then
    export PATH="$dir:$PATH"
  fi
done

# ------------------------------------------------------------------------------
# 2. BASH OPTIONS & HISTORY
# ------------------------------------------------------------------------------
HISTFILE="$HOME/.bash_history"
HISTSIZE=10000
HISTFILESIZE=10000
HISTCONTROL=ignoreboth:erasedups

shopt -s histappend
shopt -s checkwinsize
shopt -s autocd
shopt -s globstar

# ------------------------------------------------------------------------------
# 3. KEYBINDINGS (Vi Mode Enabled)
# ------------------------------------------------------------------------------
set -o vi # Enable Vi keybindings for readline

# Bind Up/Down history search in Vi insert/command modes
bind -m vi-insert '"\e[A": history-search-backward'
bind -m vi-insert '"\e[B": history-search-forward'
bind -m vi-command '"\e[A": history-search-backward'
bind -m vi-command '"\e[B": history-search-forward'
bind -m vi-command '"k": history-search-backward'
bind -m vi-command '"j": history-search-forward'

# ------------------------------------------------------------------------------
# 4. ALIASES & UTILITIES
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

if command -v rg &>/dev/null; then
  alias grep="rg"
else
  alias grep="grep --color=auto"
fi

alias bashconfig="$EDITOR ~/.bashrc"
alias reload="source ~/.bashrc && echo 'Bash configuration reloaded.'"

alias update="sudo apt update && sudo apt upgrade -y && flatpak update -y"
alias cleanup="sudo apt autoremove -y && sudo apt autoclean && flatpak uninstall --unused -y"

alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"

alias vim=nvim

# ------------------------------------------------------------------------------
# 5. EXTERNAL INTEGRATIONS
# ------------------------------------------------------------------------------
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init bash)"
fi

if command -v fzf &>/dev/null; then
  [ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && source /usr/share/doc/fzf/examples/key-bindings.bash
  [ -f /usr/share/doc/fzf/examples/completion.bash ] && source /usr/share/doc/fzf/examples/completion.bash
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --color=header:italic"
fi

if command -v starship &>/dev/null; then
  eval "$(starship init bash)"
else
  PS1='\[\e[36m\]\u@\h\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\$ '
fi

# ------------------------------------------------------------------------------
# ZOXIDE INTEGRATION
# ------------------------------------------------------------------------------
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init bash)"

  # Aliases
  alias cd="z"
  alias cdi="zi"
fi

# ------------------------------------------------------------------------------
# TMUX ALIASES
# ------------------------------------------------------------------------------
alias tmux-install="~/.config/tmux/plugins/tpm/bin/install_plugins"
alias tmux-update="~/.config/tmux/plugins/tpm/bin/update_plugins all"
alias tmux-clean="~/.config/tmux/plugins/tpm/bin/clean_plugins"

# ------------------------------------------------------------------------------
# 6. WELCOME BANNER
# ------------------------------------------------------------------------------
if command -v fastfetch &>/dev/null; then
  fastfetch
elif command -v neofetch &>/dev/null; then
  neofetch
fi


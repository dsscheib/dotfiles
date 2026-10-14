# shellcheck shell=bash
# ==============================================================================
# ML4W-INSPIRED BASH CONFIGURATION
# Save to: ~/.bashrc
# ==============================================================================

case $- in
*i*) ;;
*) return ;;
esac

# ------------------------------------------------------------------------------
# 1. SHARED ENVIRONMENT, PATHS & ALIASES
# ------------------------------------------------------------------------------
# shellcheck source=shell/.config/shell/common.sh
[ -f "$HOME/.config/shell/common.sh" ] && . "$HOME/.config/shell/common.sh"

if command -v mise &>/dev/null; then
  eval "$(mise activate bash)"
fi
setup_editor

# ------------------------------------------------------------------------------
# 2. BASH OPTIONS & HISTORY
# ------------------------------------------------------------------------------
HISTFILE="$HOME/.bash_history"
HISTSIZE=50000
HISTFILESIZE=50000
HISTCONTROL=ignoreboth

shopt -s histappend
shopt -s checkwinsize
shopt -s autocd
shopt -s globstar

# ------------------------------------------------------------------------------
# 3. KEYBINDINGS (Vi Mode Enabled)
# ------------------------------------------------------------------------------
set -o vi

bind -m vi-insert '"\e[A": history-search-backward'
bind -m vi-insert '"\e[B": history-search-forward'
bind -m vi-command '"\e[A": history-search-backward'
bind -m vi-command '"\e[B": history-search-forward'
bind -m vi-command '"k": history-search-backward'
bind -m vi-command '"j": history-search-forward'

# ------------------------------------------------------------------------------
# 4. BASH-SPECIFIC ALIASES
# ------------------------------------------------------------------------------
alias bashconfig='$EDITOR ~/.bashrc'
alias reload="source ~/.bashrc && echo 'Bash configuration reloaded.'"

# ------------------------------------------------------------------------------
# 5. EXTERNAL INTEGRATIONS
# ------------------------------------------------------------------------------

# Load programmable completion, including APT, before fzf integrations.
if [[ -z ${BASH_COMPLETION_VERSINFO:-} && -r /usr/share/bash-completion/bash_completion ]]; then
  # shellcheck source=/dev/null
  source /usr/share/bash-completion/bash_completion
fi
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init bash --cmd cd)"
fi

if command -v fzf &>/dev/null; then
  # shellcheck source=/dev/null
  [ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && source /usr/share/doc/fzf/examples/key-bindings.bash
  # shellcheck source=/dev/null
  [ -f /usr/share/doc/fzf/examples/completion.bash ] && source /usr/share/doc/fzf/examples/completion.bash
fi

if command -v starship &>/dev/null; then
  eval "$(starship init bash)"
else
  PS1='\[\e[1;36m\][bash]\[\e[0m\] \[\e[36m\]\u@\h\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\$ '
fi

if command -v gocomplete &>/dev/null; then
  complete -o nospace -C gocomplete go
fi

# ------------------------------------------------------------------------------
# 6. WELCOME BANNER
# ------------------------------------------------------------------------------
show_banner

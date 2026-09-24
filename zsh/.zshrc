# ==============================================================================
# ML4W-INSPIRED ZSH CONFIGURATION (Tailored for Pop!_OS 24.04)
# Save this file to ~/.zshrc
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. ENVIRONMENT VARIABLES & PATHS
# ------------------------------------------------------------------------------
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Deduplicate and append essential paths (Cargo, Go, Flatpak, local bin)
typeset -U path
path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  /var/lib/flatpak/exports/bin
  "$HOME/.local/share/flatpak/exports/bin"
  /usr/local/bin
  $path
)
export PATH

# Less formatting for colored man pages
export LESS_TERMCAP_mb=$'\e[1;31m'
export LESS_TERMCAP_md=$'\e[1;36m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;32m'

# ------------------------------------------------------------------------------
# 2. ZSH OPTIONS & HISTORY
# ------------------------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

# History options
setopt SHARE_HISTORY          # Share command history across open terminals
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicate entries first when trimming
setopt HIST_IGNORE_DUPS       # Don't record duplicate entries consecutively
setopt HIST_IGNORE_ALL_DUPS   # Delete old duplicate entries if a new one is added
setopt HIST_FIND_NO_DUPS      # Do not display duplicates when searching history
setopt HIST_IGNORE_SPACE      # Don't record commands starting with a space
setopt HIST_SAVE_NO_DUPS      # Don't write duplicate entries to the history file
setopt HIST_REDUCE_BLANKS     # Remove unnecessary blanks from history commands

# Directory & navigation behavior
setopt AUTO_CD                # Type directory name to cd into it
setopt AUTO_PUSHD             # Push directory onto stack on cd
setopt PUSHD_IGNORE_DUPS      # Avoid duplicates in directory stack
setopt PUSHD_SILENT           # Suppress directory stack output

# Miscellaneous
setopt NO_BEEP                # Disable terminal bell
setopt INTERACTIVE_COMMENTS   # Allow inline comments (#) in interactive shell

# ------------------------------------------------------------------------------
# 3. COMPLETION SYSTEM
# ------------------------------------------------------------------------------
autoload -Uz compinit
# Cache completions for fast startup
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.cache/zsh/zcompcache"
compinit -d "$HOME/.cache/zsh/zcompdump"

# Case-insensitive, partial-word, and substring completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Interactive selection menu
zstyle ':completion:*' menu select

# Colorize completions using system LS_COLORS
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Group completion results with clear headers
zstyle ':completion:*:*:*:*:descriptions' format '%F{cyan}-- %d --%f'
zstyle ':completion:*:*:*:*:warnings' format '%F{red}-- No matches found --%f'

# ------------------------------------------------------------------------------
# 4. KEYBINDINGS (Emacs mode with history search)
# ------------------------------------------------------------------------------
bindkey -e

# Home / End navigation fixes across terminals
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line

# Delete key fix
bindkey '^[[3~' delete-char

# Ctrl + Left/Right word jumps
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# History search using Up/Down arrows matching current line buffer
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# ------------------------------------------------------------------------------
# 5. ALIASES & UTILITIES
# ------------------------------------------------------------------------------
# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# Modern alternative tools with standard fallbacks
if command -v eza &> /dev/null; then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza -lh --icons --group-directories-first"
  alias la="eza -lah --icons --group-directories-first"
  alias tree="eza --tree --icons"
elif command -v exa &> /dev/null; then
  alias ls="exa --icons --group-directories-first"
  alias ll="exa -lh --icons --group-directories-first"
  alias la="exa -lah --icons --group-directories-first"
  alias tree="exa --tree --icons"
else
  alias ls="ls --color=auto"
  alias ll="ls -lh --color=auto"
  alias la="ls -lah --color=auto"
fi

# On Pop!_OS / Ubuntu, 'bat' is installed as 'batcat'
if command -v bat &> /dev/null; then
  alias cat="bat --style=plain"
elif command -v batcat &> /dev/null; then
  alias cat="batcat --style=plain"
fi

if command -v rg &> /dev/null; then
  alias grep="rg"
else
  alias grep="grep --color=auto"
fi

# ML4W Quick Access & Management
alias zshconfig="$EDITOR ~/.zshrc"
alias reload="source ~/.zshrc && echo 'Zsh configuration reloaded.'"

# Pop!_OS 24.04 System Updates (APT + Flatpak)
alias update="sudo apt update && sudo apt upgrade -y && flatpak update -y"
alias cleanup="sudo apt autoremove -y && sudo apt autoclean && flatpak uninstall --unused -y"

# Safety nets
alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"

# ------------------------------------------------------------------------------
# 6. EXTERNAL INTEGRATIONS (Starship, Zoxide, FZF)
# ------------------------------------------------------------------------------
# Zoxide (fast cd)
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi

# FZF integration
if command -v fzf &> /dev/null; then
  # Source Debian/Ubuntu default FZF location if present
  [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
  [ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --color=header:italic"
fi

# ------------------------------------------------------------------------------
# 7. PROMPT / STARSHIP INTEGRATION
# ------------------------------------------------------------------------------
if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
else
  # Minimalist fallback prompt if Starship is not installed yet
  autoload -Uz vcs_info
  precmd() { vcs_info }
  zstyle ':vcs_info:git:*' formats '%F{yellow}(%b)%f '

  setopt PROMPT_SUBST
  PROMPT='%F{cyan}%n@%m%f:%F{blue}%~%f ${vcs_info_msg_0_}%F{magenta}❯%f '
fi

# ------------------------------------------------------------------------------
# 8. DEBIAN/POP!_OS PLUGIN PATHS
# Sources plugins installed via apt (zsh-autosuggestions, zsh-syntax-highlighting)
# ------------------------------------------------------------------------------
# APT locations
[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Manual clone fallbacks (~/.zsh/)
[ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
  source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

[ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
  source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ------------------------------------------------------------------------------
# 9. WELCOME BANNER
# ------------------------------------------------------------------------------
if command -v fastfetch &> /dev/null; then
  fastfetch
elif command -v neofetch &> /dev/null; then
  neofetch
fi

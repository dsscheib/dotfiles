# ==============================================================================
# ML4W-INSPIRED ZSH CONFIGURATION (Pop!_OS 24.04 Target)
# Save to: ~/.zshrc
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. ENVIRONMENT VARIABLES & PATHS
# ------------------------------------------------------------------------------
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

if command -v nvim &>/dev/null; then
  export MANPAGER="nvim +Man!"
  export MANWIDTH=999
fi

typeset -U path
path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$HOME/go/bin"
  "$HOME/.local/share/mise/shims"
  /var/lib/flatpak/exports/bin
  "$HOME/.local/share/flatpak/exports/bin"
  /usr/local/bin
  $path
)
export PATH

eval "$(mise activate zsh)"

# ------------------------------------------------------------------------------
# 2. ZSH OPTIONS & HISTORY
# ------------------------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt SHARE_HISTORY          
setopt HIST_EXPIRE_DUPS_FIRST 
setopt HIST_IGNORE_DUPS       
setopt HIST_IGNORE_ALL_DUPS   
setopt HIST_FIND_NO_DUPS      
setopt HIST_IGNORE_SPACE      
setopt HIST_SAVE_NO_DUPS      
setopt HIST_REDUCE_BLANKS     

setopt AUTO_CD           
setopt AUTO_PUSHD        
setopt PUSHD_IGNORE_DUPS 
setopt PUSHD_SILENT      

setopt NO_BEEP              
setopt INTERACTIVE_COMMENTS 

# ------------------------------------------------------------------------------
# 3. COMPLETION SYSTEM
# ------------------------------------------------------------------------------
# Ensure custom completions directory is added to fpath BEFORE compinit runs
fpath=("$HOME/.zsh/completion" $fpath)

autoload -Uz compinit bashcompinit
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.cache/zsh/zcompcache"
compinit -d "$HOME/.cache/zsh/zcompdump"
bashcompinit

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:*:*:*:descriptions' format '%F{cyan}-- %d --%f'
zstyle ':completion:*:*:*:*:warnings' format '%F{red}-- No matches found --%f'

# Go completion via bashcompinit
if command -v gocomplete &>/dev/null; then
  complete -o nospace -C gocomplete go
fi

# ------------------------------------------------------------------------------
# 4. KEYBINDINGS (Vi Mode Enabled)
# ------------------------------------------------------------------------------
bindkey -v          
export KEYTIMEOUT=1 

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey -M viins '^[[A' up-line-or-beginning-search
bindkey -M viins '^[[B' down-line-or-beginning-search
bindkey -M vicmd '^[[A' up-line-or-beginning-search
bindkey -M vicmd '^[[B' down-line-or-beginning-search
bindkey -M vicmd 'k' up-line-or-beginning-search
bindkey -M vicmd 'j' down-line-or-beginning-search

bindkey -M viins '^?' backward-delete-char

# ------------------------------------------------------------------------------
# 5. ALIASES & UTILITIES
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

alias zshconfig="$EDITOR ~/.zshrc"
alias reload="source ~/.zshrc && echo 'Zsh configuration reloaded.'"

alias update="sudo apt update && sudo apt upgrade -y && flatpak update -y"
alias cleanup="sudo apt autoremove -y && sudo apt autoclean && flatpak uninstall --unused -y"

alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"

alias sudo="sudo "
alias vim=nvim

# ------------------------------------------------------------------------------
# 6. EXTERNAL INTEGRATIONS (Starship, Zoxide, FZF)
# ------------------------------------------------------------------------------
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
  alias cd="z"
  alias cdi="zi"
fi

if command -v fzf &>/dev/null; then
  [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
  [ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --color=header:italic"
fi

# TMUX ALIASES
alias tmux-install="~/.config/tmux/plugins/tpm/bin/install_plugins"
alias tmux-update="~/.config/tmux/plugins/tpm/bin/update_plugins all"
alias tmux-clean="~/.config/tmux/plugins/tpm/bin/clean_plugins"

# ------------------------------------------------------------------------------
# 7. PROMPT / STARSHIP INTEGRATION
# ------------------------------------------------------------------------------
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
else
  autoload -Uz vcs_info
  precmd() { vcs_info; }
  zstyle ':vcs_info:git:*' formats '%F{yellow}(%b)%f '
  setopt PROMPT_SUBST
  PROMPT='%F{cyan}%n@%m%f:%F{blue}%~%f ${vcs_info_msg_0_}%F{magenta}❯%f '
fi

# ------------------------------------------------------------------------------
# 8. DEBIAN/POP!_OS PLUGIN PATHS
# ------------------------------------------------------------------------------
[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] &&
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] &&
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ------------------------------------------------------------------------------
# 9. WELCOME BANNER
# ------------------------------------------------------------------------------
if command -v fastfetch &>/dev/null; then
  fastfetch
elif command -v neofetch &>/dev/null; then
  neofetch
fi

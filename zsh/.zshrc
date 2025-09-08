# Use powerline
USE_POWERLINE="true"
# Source manjaro-zsh-configuration
if [[ -e /usr/share/zsh/manjaro-zsh-config ]]; then
  source /usr/share/zsh/manjaro-zsh-config
fi
# Use manjaro zsh prompt
if [[ -e /usr/share/zsh/manjaro-zsh-prompt ]]; then
  source /usr/share/zsh/manjaro-zsh-prompt
fi

export PATH=$PATH:/usr/local/go/bin:$HOME/bin

# Alias
alias sudo='sudo '
alias ll='ls -l'
alias la='ls -al'
alias vim=nvim
alias git='GPG_TTY=$(tty) git'
# alias synology-drive='QT_QPA_PLATFORM=xcb synology-drive'

# Enable zplug
source ~/.zplug/init.zsh
zplug 'zplug/zplug', hook-build:'zplug --self-manage'

# Enable Rust Completions
zplug 'ryutok/rust-zsh-completions'

# zplug check returns true if all packages are installed
# Therefore, when it returns false, run zplug install
if ! zplug check; then
    zplug install
fi

# source plugins and add commands to the PATH
zplug load

# zplug check returns true if the given repository exists
if zplug check b4b4r07/enhancd; then
    # setting if enhancd is available
    export ENHANCD_FILTER=fzf-tmux
fi

fpath+=~/.zfunc

# Startup greetings
fastfetch

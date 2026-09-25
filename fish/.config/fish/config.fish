# ==============================================================================
# ML4W-INSPIRED FISH CONFIGURATION
# Save to: ~/.config/fish/config.fish
# ==============================================================================

if status is-interactive

    # --------------------------------------------------------------------------
    # 1. ENVIRONMENT VARIABLES & PATHS
    # --------------------------------------------------------------------------
    set -gx EDITOR nvim
    set -gx VISUAL nvim
    set -gx PAGER less
    set -gx LANG en_US.UTF-8

    # Use Neovim as default man page pager
    if type -q nvim
        set -gx MANPAGER "nvim +Man!"
        set -gx MANWIDTH 999
    end

    fish_add_path -g $HOME/bin
    fish_add_path -g $HOME/.local/bin
    fish_add_path -g $HOME/.cargo/bin
    fish_add_path -g /var/lib/flatpak/exports/bin
    fish_add_path -g $HOME/.local/share/flatpak/exports/bin
    fish_add_path -g /usr/local/bin
    
    # Add Mise to the PATH
    mise activate fish | source

    set -g fish_greeting

    # --------------------------------------------------------------------------
    # 2. KEYBINDINGS (Vi Mode Enabled)
    # --------------------------------------------------------------------------
    fish_vi_key_bindings

    # Preserve history search with Up/Down arrows in Vi insert and normal mode
    bind -M default \e\[A history-search-backward
    bind -M default \e\[B history-search-forward
    bind -M insert \e\[A history-search-backward
    bind -M insert \e\[B history-search-forward

    # --------------------------------------------------------------------------
    # 3. ALIASES & UTILITIES
    # --------------------------------------------------------------------------
    alias ..="cd .."
    alias ...="cd ../.."
    alias ....="cd ../../.."

    if type -q eza
        alias ls="eza --icons --group-directories-first"
        alias ll="eza -lh --icons --group-directories-first"
        alias la="eza -lah --icons --group-directories-first"
        alias tree="eza --tree --icons"
    else
        alias ls="ls --color=auto"
        alias ll="ls -lh --color=auto"
        alias la="ls -lah --color=auto"
    end

    if type -q bat
        alias cat="bat --style=plain"
    else if type -q batcat
        alias cat="batcat --style=plain"
    end

    if type -q rg
        alias grep="rg"
    else
        alias grep="grep --color=auto"
    end

    alias fishconfig="$EDITOR ~/.config/fish/config.fish"
    alias reload="source ~/.config/fish/config.fish; and echo 'Fish configuration reloaded.'"

    alias update="sudo apt update && sudo apt upgrade -y && flatpak update -y"
    alias cleanup="sudo apt autoremove -y && sudo apt autoclean && flatpak uninstall --unused -y"

    alias cp="cp -i"
    alias mv="mv -i"
    alias rm="rm -i"

    alias sudo="sudo "
    alias vim="nvim"

    # --------------------------------------------------------------------------
    # 4. EXTERNAL INTEGRATIONS
    # --------------------------------------------------------------------------
    if type -q zoxide
        zoxide init fish | source
    end

    if type -q fzf
        set -gx FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border --color=header:italic"
    end

    if type -q starship
        starship init fish | source
    end

    # --------------------------------------------------------------------------
    # ZOXIDE INTEGRATION
    # --------------------------------------------------------------------------
    if type -q zoxide
        zoxide init fish | source
        
        # Aliases
        alias cd="z"
        alias cdi="zi"
    end

    # --------------------------------------------------------------------------
    # TMUX ALIASES
    # --------------------------------------------------------------------------
    alias tmux-install="~/.config/tmux/plugins/tpm/bin/install_plugins"
    alias tmux-update="~/.config/tmux/plugins/tpm/bin/update_plugins all"
    alias tmux-clean="~/.config/tmux/plugins/tpm/bin/clean_plugins"

    # --------------------------------------------------------------------------
    # 5. WELCOME BANNER
    # --------------------------------------------------------------------------
    if type -q fastfetch
        fastfetch
    else if type -q neofetch
        neofetch
    end

end

# ==============================================================================
# ML4W-INSPIRED FISH CONFIGURATION
# Save to: ~/.config/fish/config.fish
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. ENVIRONMENT VARIABLES & PATHS
# ------------------------------------------------------------------------------
fish_add_path --path $HOME/bin $HOME/.local/bin $HOME/.cargo/bin $HOME/go/bin \
    /var/lib/flatpak/exports/bin $HOME/.local/share/flatpak/exports/bin /usr/local/bin

if type -q mise
    mise activate fish | source
end

# Detect editors only after user-local PATH and Mise are initialized. Preserve
# the inherited locale and any explicit editor/pager preferences.
set -q PAGER; or set -gx PAGER less
if type -q nvim
    set -q EDITOR; or set -gx EDITOR nvim
    set -q MANPAGER; or set -gx MANPAGER "nvim +Man!"
    set -q MANWIDTH; or set -gx MANWIDTH 999
else
    set -q EDITOR; or set -gx EDITOR vi
end
set -q VISUAL; or set -gx VISUAL $EDITOR

if test -d "$HOME/STMicroelectronics/STM32Cube/STM32CubeProgrammer/bin"
    set -gx STM32_PRG_PATH "$HOME/STMicroelectronics/STM32Cube/STM32CubeProgrammer/bin"
end

if status is-interactive

    set -g fish_greeting

    # --------------------------------------------------------------------------
    # 2. KEYBINDINGS (Vi Mode Enabled)
    # --------------------------------------------------------------------------
    fish_vi_key_bindings

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

    alias grep="grep --color=auto"

    alias fishconfig="$EDITOR ~/.config/fish/config.fish"
    alias reload="source ~/.config/fish/config.fish; and echo 'Fish configuration reloaded.'"

    # Pop!_OS / Debian (apt + flatpak) only
    alias update="sudo apt update && sudo apt upgrade -y && flatpak update -y"
    alias cleanup="sudo apt autoremove -y && sudo apt autoclean && flatpak uninstall --unused -y"

    alias cp="cp -i"
    alias mv="mv -i"
    alias rm="rm -i"

    alias vim="nvim"

    # --------------------------------------------------------------------------
    # 4. EXTERNAL INTEGRATIONS
    # --------------------------------------------------------------------------
    if type -q zoxide
        zoxide init fish --cmd cd | source
    end

    if type -q fzf
        set -gx FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border --color=header:italic"
    end

    if type -q starship
        starship init fish | source
    end

    # Use Fish's built-in Go completions, including package/file arguments.

    # Keep new tmux panes on the shell invoking the client, including when
    # connecting to an already-running server.
    function tmux
        set -l current_shell (readlink -f "/proc/$fish_pid/exe")
        or return
        if test (count $argv) -eq 0; and not set -q TMUX
            command tmux set-option -g default-shell "$current_shell" \; new-session
        else
            command tmux set-option -g default-shell "$current_shell" \; $argv
        end
    end

    # TMUX ALIASES
    alias tmux-install="~/.local/share/tmux/plugins/tpm/bin/install_plugins"
    alias tmux-update="~/.local/share/tmux/plugins/tpm/bin/update_plugins all"
    alias tmux-clean="~/.local/share/tmux/plugins/tpm/bin/clean_plugins"

    # --------------------------------------------------------------------------
    # 5. WELCOME BANNER
    # --------------------------------------------------------------------------
    if test -z "$TMUX" -a -z "$NVIM"
        if type -q fastfetch
            fastfetch
        else if type -q neofetch
            neofetch
        end
    end

end

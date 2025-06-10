if status is-interactive
    # Commands to run in interactive sessions can go here
end
starship preset nerd-font-symbols -o ~/.config/starship.toml
starship init fish | source
zoxide init --cmd cd fish | source

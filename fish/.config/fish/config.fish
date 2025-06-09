if status is-interactive
    # Commands to run in interactive sessions can go here
end
# theme_gruvbox dark medium
starship preset nerd-font-symbols -o ~/.config/starship.toml
starship init fish | source

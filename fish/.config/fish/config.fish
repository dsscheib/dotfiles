if status is-interactive
  # Commands to run in interactive sessions can go here
  set -g fish_key_bindings fish_vi_key_bindings
  
  zoxide init --cmd cd fish | source
  starship preset nerd-font-symbols -o ~/.config/starship.toml
  # starship preset tokyo-night -o ~/.config/starship.toml
  starship init fish | source

  # Djengo completions
  __fish_complete_django django-admin.py
  __fish_complete_django manage.py
end

eval "$(rbenv init -)"


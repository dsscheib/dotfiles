# Initialize completion with a daily cache refresh and a permissions audit on
# every startup. compinit -C alone would skip that audit.
dotfiles_init_completion() {
  emulate -L zsh
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
  local dump="$cache_dir/zcompdump-$ZSH_VERSION"
  local -a stale
  (umask 077; mkdir -p -- "$cache_dir") || return
  stale=( "$dump"(N.mh+24) )
  autoload -Uz compinit compaudit
  if [[ -s "$dump" ]] && (( ${#stale} == 0 )) && compaudit >/dev/null; then
    compinit -C -d "$dump"
  else
    # Ignore insecure completion directories rather than prompting or loading
    # them. A cache is used only after the audit succeeds.
    compinit -i -d "$dump" && touch -- "$dump"
  fi
}

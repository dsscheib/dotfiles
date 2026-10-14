#!/usr/bin/env bash
# Deploy the declared Stow packages as the desktop user.
set -euo pipefail
DOTFILES_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=resources/tpm.env
source "$DOTFILES_DIR/resources/tpm.env"

log_info() { printf '[INFO] %s\n' "$*"; }
log_warn() { printf '[WARN] %s\n' "$*" >&2; }
log_error() { printf '[ERROR] %s\n' "$*" >&2; }

install_stow() {
  if command -v stow >/dev/null && command -v python3 >/dev/null; then return; fi
  if command -v apt-get >/dev/null; then
    sudo apt-get update
    sudo apt-get install -y stow python3
  elif command -v pacman >/dev/null; then sudo pacman -S --needed --noconfirm stow python;
  elif command -v dnf >/dev/null; then sudo dnf install -y stow python3;
  elif command -v brew >/dev/null; then brew install stow python3;
  elif command -v zypper >/dev/null; then sudo zypper install -y stow python3;
  else log_error 'Install GNU Stow and Python 3 before continuing.'; return 1; fi
  command -v stow >/dev/null && command -v python3 >/dev/null
}

setup_tmux() {
  if [[ ${DOTFILES_SKIP_TMUX:-0} == 1 ]]; then
    log_info 'Tmux plugin setup delegated to workstation setup or explicitly skipped.'
    return
  fi
  if ! command -v tmux >/dev/null; then
    log_warn 'tmux is missing; install it and rerun bootstrap to install plugins.'
    return
  fi
  command -v git >/dev/null || { log_error 'Git is required for tmux plugin installation.'; return 1; }
  export TMUX_PLUGIN_MANAGER_PATH="$HOME/.local/share/tmux/plugins"
  local tpm_dir="$TMUX_PLUGIN_MANAGER_PATH/tpm" origin temporary
  if [[ -e $tpm_dir || -L $tpm_dir ]]; then
    [[ ! -L $tpm_dir && -d $tpm_dir/.git ]] || { log_error "TPM path is not a regular Git checkout: $tpm_dir"; return 1; }
    origin=$(git -C "$tpm_dir" remote get-url origin)
    case ${origin%.git} in
      https://github.com/tmux-plugins/tpm|git@github.com:tmux-plugins/tpm) ;;
      *) log_error "Unexpected TPM origin: $origin"; return 1 ;;
    esac
    [[ -z $(git -C "$tpm_dir" status --porcelain) ]] || { log_error "TPM has local changes: $tpm_dir"; return 1; }
    if ! git -C "$tpm_dir" cat-file -e "$TPM_COMMIT^{commit}"; then git -C "$tpm_dir" fetch origin "$TPM_COMMIT"; fi
    git -C "$tpm_dir" checkout --detach "$TPM_COMMIT"
  else
    mkdir -p "$TMUX_PLUGIN_MANAGER_PATH"
    temporary=$(mktemp -d "$TMUX_PLUGIN_MANAGER_PATH/.tpm.XXXXXX")
    if git clone --no-checkout https://github.com/tmux-plugins/tpm "$temporary" &&
       git -C "$temporary" checkout --detach "$TPM_COMMIT"; then
      mv -T -- "$temporary" "$tpm_dir"
    else
      rm -rf -- "$temporary"
      log_error 'Could not install the pinned TPM revision.'
      return 1
    fi
  fi
  log_info "Installing tmux plugins with TPM $TPM_COMMIT..."
  if "$tpm_dir/bin/install_plugins"; then return; fi
  log_error 'Tmux plugin installation failed. Dotfiles are deployed; resolve the error and rerun bootstrap.'
  return 1
}

check_dependencies() {
  local tool
  local -a missing=()
  for tool in nvim tmux starship zoxide fzf eza rg mise fastfetch; do
    command -v "$tool" >/dev/null || missing+=("$tool")
  done
  if ! command -v bat >/dev/null && ! command -v batcat >/dev/null; then missing+=(bat); fi
  if [[ ! -r /usr/share/bash-completion/bash_completion ]]; then missing+=(bash-completion); fi
  if (( ${#missing[@]} )); then log_warn "Recommended tools missing: ${missing[*]}"; fi
}

main() {
  [[ $# == 0 ]] || { log_error 'Usage: ./bootstrap.sh (DOTFILES_SKIP_TMUX=1 skips plugins)'; return 1; }
  [[ $EUID != 0 ]] || { log_error 'Run bootstrap as your desktop user, without sudo.'; return 1; }
  [[ -d $HOME && $HOME != / ]] || { log_error 'HOME must identify your home directory.'; return 1; }
  install_stow
  local -a packages=()
  mapfile -t packages < "$DOTFILES_DIR/packages.txt"
  python3 "$DOTFILES_DIR/scripts/stow_safe.py" "$DOTFILES_DIR" "$HOME" "${packages[@]}"
  setup_tmux
  check_dependencies
  log_info 'Dotfiles successfully bootstrapped.'
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then main "$@"; fi

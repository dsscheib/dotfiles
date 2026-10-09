#!/usr/bin/env bash

# ==============================================================================
# DOTFILES BOOTSTRAP SCRIPT
# Idempotent setup for fresh Linux installations.
# ==============================================================================

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${HOME}/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# List of stow packages (directories in ~/.dotfiles) to ignore
EXCLUDE_DIRS=(".git" ".github" "docs")

log_info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
log_warn() { echo -e "\033[0;33m[WARN]\033[0m $1"; }
log_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }

# ------------------------------------------------------------------------------
# 1. INSTALL STOW IF MISSING
# ------------------------------------------------------------------------------
install_stow() {
  if command -v stow &>/dev/null; then
    log_info "GNU Stow is already installed."
    return
  fi

  log_info "GNU Stow not found. Attempting installation..."

  if command -v apt &>/dev/null; then
    sudo apt update && sudo apt install -y stow
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm stow
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y stow
  elif command -v brew &>/dev/null; then
    brew install stow
  elif command -v zypper &>/dev/null; then
    sudo zypper install -y stow
  else
    log_error "Could not detect a supported package manager. Please install Stow manually."
    exit 1
  fi
}

# ------------------------------------------------------------------------------
# 2. BACK UP EXISTING NON-SYMLINK CONFLICTS
# ------------------------------------------------------------------------------
backup_conflicts() {
  log_info "Checking for conflicting target files..."

  # Dry-run stow to discover existing files that would cause a collision
  cd "${DOTFILES_DIR}"

  for pkg in */; do
    pkg="${pkg%/}"

    # Skip excluded non-package directories
    if [[ " ${EXCLUDE_DIRS[*]} " =~ " ${pkg} " ]]; then
      continue
    fi

    # Run stow simulation and parse conflict messages
    conflicts=$(stow -n -v "${pkg}" 2>&1 | grep "existing target is neither a link nor a directory" | awk '{print $NF}' || true)

    if [[ -n "${conflicts}" ]]; then
      mkdir -p "${BACKUP_DIR}"
      while IFS= read -r file; do
        target="${HOME}/${file}"
        if [[ -f "${target}" || -d "${target}" ]]; then
          log_warn "Backing up conflicting file: ${target} -> ${BACKUP_DIR}/"
          mkdir -p "$(dirname "${BACKUP_DIR}/${file}")"
          mv "${target}" "${BACKUP_DIR}/${file}"
        fi
      done <<<"${conflicts}"
    fi
  done
}

# ------------------------------------------------------------------------------
# 3. STOW PACKAGES
# ------------------------------------------------------------------------------
stow_packages() {
  log_info "Stowing configuration packages..."
  cd "${DOTFILES_DIR}"

  for pkg in */; do
    pkg="${pkg%/}"

    if [[ " ${EXCLUDE_DIRS[*]} " =~ " ${pkg} " ]]; then
      continue
    fi

    log_info "Restowing package: ${pkg}"
    stow -R "${pkg}"
  done
}

# ------------------------------------------------------------------------------
# AUTOMATE TMUX & TPM SETUP
# ------------------------------------------------------------------------------
setup_tmux() {
  local tpm_dir="${HOME}/.local/share/tmux/plugins/tpm"

  # Clone TPM if it isn't installed yet
  if [[ ! -d "${tpm_dir}" ]]; then
    log_info "Cloning Tmux Plugin Manager (TPM)..."
    mkdir -p "$(dirname "${tpm_dir}")"
    git clone https://github.com/tmux-plugins/tpm "${tpm_dir}"
  fi

  # Install plugins headlessly if tmux is available
  if command -v tmux &>/dev/null && [[ -f "${tpm_dir}/bin/install_plugins" ]]; then
    log_info "Installing Tmux plugins..."
    "${tpm_dir}/bin/install_plugins" || true
  fi
}

# ------------------------------------------------------------------------------
# 5. VERIFY SYSTEM DEPENDENCIES
# ------------------------------------------------------------------------------
check_dependencies() {
  local core_tools=("nvim" "tmux" "starship" "zoxide" "fzf" "eza" "rg" "mise" "fastfetch")
  local missing=()

  for tool in "${core_tools[@]}"; do
    if ! command -v "${tool}" &>/dev/null; then
      missing+=("${tool}")
    fi
  done

  if ! command -v bat &>/dev/null && ! command -v batcat &>/dev/null; then
    missing+=("bat")
  fi

  if [[ ${#missing[@]} -gt 0 ]]; then
    log_warn "Some recommended CLI tools are missing: ${missing[*]}"
  else
    log_info "All recommended CLI tools are installed!"
  fi
}

# ------------------------------------------------------------------------------
# MAIN EXECUTION
# ------------------------------------------------------------------------------
main() {
  log_info "Starting dotfiles setup from: ${DOTFILES_DIR}"

  install_stow
  backup_conflicts
  stow_packages
  setup_tmux
  check_dependencies

  log_info "Dotfiles successfully bootstrapped!"
  if [[ -d "${BACKUP_DIR}" ]]; then
    log_warn "Conflicting files were backed up to: ${BACKUP_DIR}"
  fi
}

main "$@"

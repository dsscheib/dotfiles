# dotfiles

Personal Pop!_OS configuration managed with GNU Stow. Shells, terminals,
Starship, tmux, and Fastfetch use the Tokyo Night palette.

## Install

```sh
git clone https://github.com/dsscheib/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh
```

Run as your desktop user. Bootstrap installs GNU Stow and Python 3 if needed,
validates every target, backs up conflicting regular files to a unique private
`~/.dotfiles_backup/install-*/` directory, and deploys the packages listed in
`packages.txt`. Test and support directories are not Stow packages.

Foreign or broken symlinks and unexpected directory layouts stop deployment
before originals are moved. Existing Stow directory links into this checkout are
supported. Concurrent deployments are rejected. If a backup move or Stow's
simulation fails, moved originals are restored when their target paths are free.
If the real Stow operation fails, inspect the reported backup directory and any
new links before retrying; backups remain available for manual recovery.

Restowing an already deployed checkout is idempotent. To restow one package:

```sh
cd ~/.dotfiles
stow -R bash
```

`.stowrc` uses `--no-folding` and ignores only repository metadata/documentation,
so configuration files such as `.gitconfig` are included.

## Packages

| Package | Target |
| --- | --- |
| bash | `~/.bashrc` |
| zsh | `~/.zshrc` |
| shell | `~/.config/shell/common.sh`, `completion.zsh` |
| fish | `~/.config/fish/config.fish` |
| git | `~/.gitconfig`, `~/.config/git/ignore` |
| tmux | `~/.config/tmux/tmux.conf` |
| starship | `~/.config/starship.toml` |
| kitty | `~/.config/kitty/kitty.conf` |
| cosmic-term | `~/.config/cosmic/com.system76.CosmicTerm/v1/*` |
| fastfetch | `~/.config/fastfetch/config.jsonc` |

Neovim configuration lives in
[dsscheib/astronvim_v6](https://github.com/dsscheib/astronvim_v6).

## Tools and shell startup

Recommended tools are `nvim`, `tmux`, `starship`, `zoxide`, `fzf`, `eza`, `bat`,
`rg`, `mise`, `fastfetch`, and JetBrainsMono Nerd Font. Bootstrap reports missing
tools; workstation setup installs them. Fastfetch's absence from an APT repository
is handled by the verified download fallback in `pop-os-system-build`.

APT tab completion requires the `bash-completion` package:

```sh
sudo apt-get install bash-completion
```

Bash loads it before fzf integrations. Fish uses its built-in Go completions;
Bash/Zsh optionally use gocomplete. User-local PATH and Mise are initialized
before checking for Neovim. Explicit editor/pager preferences and the inherited
locale are preserved. Zsh audits completion directories on every startup, reuses
its version-specific cache for about a day, and ignores insecure directories.

COSMIC Terminal uses size 18; Kitty uses 14 points. Font metrics and display
scaling differ between applications, so adjust either in its settings as needed.

## Tmux plugins

Both this repo and workstation setup use `~/.local/share/tmux/plugins`.
TPM is pinned in `resources/tpm.env`, matching workstation setup's pin. Existing
TPM checkouts must have an approved upstream origin and no local modifications.
Plugin installation failures stop bootstrap with an explicit error; deployed
configuration and backups remain available.

Plugin repositories configured in `tmux.conf` follow their upstream branches.
They are not immutable pins: TPM updates may change their behavior. Review those
updates before relying on a particular configuration.

Workstation setup delegates plugin installation to its `tmux` stage. For a
configuration-only deployment, or to work offline with Stow/Python installed:

```sh
DOTFILES_SKIP_TMUX=1 ./bootstrap.sh
```

Stow/Python package installation and TPM/plugin downloads require network access.
Older TPM copies under `~/.config/tmux/plugins` can be reviewed and removed
manually once the canonical installation works.

## Machine-specific settings

`~/.gitconfig` includes the untracked `~/.gitconfig.local`. Put local identities,
credential helpers, and work settings there.

COSMIC apps save settings by replacing files, so a settings change in the UI can
replace a symlink with a regular file. Copy the desired change into this repo and
restow `cosmic-term`; bootstrap backs up conflicting regular files when deploying
all packages.

## Checks

```sh
sudo apt-get install shellcheck stow python3 zsh fish bash-completion
bash scripts/check.sh
```

Checks cover syntax, ShellCheck, deployment into temporary homes, backup recovery,
completion behavior, editor detection, TPM validation, and cache permission
handling. CI runs on Ubuntu 22.04 and 24.04. Checks never run plugin installers or
deploy into your actual home directory. Graphical settings and third-party tmux
plugins still need testing in your desktop session.

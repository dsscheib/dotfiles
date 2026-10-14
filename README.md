# dotfiles

Personal Linux (Pop!_OS 24.04) configuration, managed with [GNU Stow](https://www.gnu.org/software/stow/).
Everything uses the Tokyo Night palette.

## Install

```sh
git clone https://github.com/dsscheib/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./bootstrap.sh
```

`bootstrap.sh` is idempotent. It installs Stow if needed, moves any conflicting
real files to `~/.dotfiles_backup/<timestamp>/`, stows every package, installs
TPM and the tmux plugins, and warns about missing CLI tools.

To (re)stow a single package by hand: `cd ~/.dotfiles && stow -R <package>`.
`.stowrc` sets `--no-folding`, so Stow links individual files rather than whole
directories, and apps can't write runtime state back into this repo.

## Packages

| Package       | Installs to                                   |
| ------------- | --------------------------------------------- |
| `bash`        | `~/.bashrc`                                   |
| `zsh`         | `~/.zshrc`                                    |
| `shell`       | `~/.config/shell/common.sh` (shared by bash and zsh) |
| `fish`        | `~/.config/fish/config.fish`                  |
| `git`         | `~/.gitconfig`, `~/.config/git/ignore`        |
| `tmux`        | `~/.config/tmux/tmux.conf`                    |
| `starship`    | `~/.config/starship.toml`                     |
| `kitty`       | `~/.config/kitty/kitty.conf`                  |
| `cosmic-term` | `~/.config/cosmic/com.system76.CosmicTerm/v1/*` |
| `fastfetch`   | `~/.config/fastfetch/config.jsonc`            |

Neovim (AstroNvim) lives in its own repo:
[dsscheib/astronvim_v6](https://github.com/dsscheib/astronvim_v6).

## Expected tools

`nvim`, `tmux`, `starship`, `zoxide`, `fzf`, `eza`, `bat`, `rg`, `mise`,
`fastfetch`, and a Nerd Font (JetBrainsMono Nerd Font). The shell configs
skip any integration whose tool is missing.

## Machine-specific settings

`~/.gitconfig` includes `~/.gitconfig.local`, which is not tracked. Put
credential helpers, work identities and similar there, e.g.:

```ini
[credential]
	helper =
	helper = /usr/local/bin/git-credential-manager
	credentialStore = gpg
```

## Notes

- tmux plugins are installed to `~/.local/share/tmux/plugins` (not in this repo).
- COSMIC apps save settings by replacing files, so changing a cosmic-term
  setting in its UI turns that symlink back into a regular file. Copy the
  change into this repo and re-run `stow -R cosmic-term`.

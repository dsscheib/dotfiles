all:
	stow --verbose --target=$$HOME --restow */

delete:
	stow --verbose --target=$$HOME --delete */

init:
	rm -rf $HOME/.bashrc
	rm -rf $HOME/.zshrc
	rm -rf $HOME/.gdbinit
	rm -rf $HOME/.config/starship.toml
	rm -rf $HOME/.config/fish/
	rm -rf $HOME/.config/foot/
	rm -rf $HOME/.config/nvim/
	rm -rf $HOME/.config/sway/
	rm -rf $HOME/.config/tmux/
	stow --verbose --target=$$HOME */

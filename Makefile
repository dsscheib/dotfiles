all:
	stow --verbose --target=$$HOME --restow */

delete:
	stow --verbose --target=$$HOME --delete */

fish:
	stow --verbose=2 --target=$$Home --restow fish

tmux:
	stow --verbose=2 --target=$$Home --restow tmux

adopt_all:
	stow --verbose=2 --target=$$HOME --adopt -S zsh
	stow --verbose=2 --target=$$HOME --adopt -S fish
	stow --verbose=2 --target=$$HOME --adopt -S tmux
	git --rest hard

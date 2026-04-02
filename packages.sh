#!/bin/bash

# e - script stops on error
# u - error if undefined variable
# o pipefail - script fails if command piped fails
set -euo pipefail

main() {
	synchronize_package_databases
	install_git
	install_packages
}

synchronize_package_databases() {
	sudo pacman -Sy
}

install_git() {
	sudo pacman -S --noconfirm --needed git
}

install_packages() {
	cd "$HOME"
	git clone https://codeberg.org/d33trik/dotfiles.git
	cd dotfiles
	git remote set-url origin git@codeberg.org/d33trik/dotfiles.git
	bash scripts/install_packages.sh
}

main "$@"

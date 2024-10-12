#!/bin/bash

# e - script stops on error
# u - error if undefined variable
# o pipefail - script fails if command piped fails
set -euo pipefail

main() {
	synchronize_package_databases
	install_git
	clone_archinstall_repository
	install_gum
}

synchronize_package_databases() {
	clear
	echo "Synchronizing package databases..."
	sleep 1
	pacman -Sy &> /dev/null
	clear
}

install_git() {
	clear
	echo "Installing git..."
	sleep 1
	pacman -S --noconfirm --needed git &> /dev/null
	clear
}

clone_archinstall_repository() {
	clear
	echo "Cloning archinstall repository..."
	sleep 1
	rm -rf archinstall
	git clone https://github.com/d33trik/archinstall.git &> /dev/null
	clear
}

install_gum() {
	clear
	echo "Installing gum..."
	sleep 1
	pacman -S --noconfirm --needed gum &> /dev/null
	source archinstall/src/gum_options.sh
	clear
}

main "$@"

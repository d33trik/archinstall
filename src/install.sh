#!/bin/bash

# e - script stops on error
# u - error if undefined variable
# o pipefail - script fails if command piped fails
set -euo pipefail

main() {
	synchronize_package_databases
	install_git
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

main "$@"

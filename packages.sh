#!/bin/bash

# e - script stops on error
# u - error if undefined variable
# o pipefail - script fails if command piped fails
set -euo pipefail

main() {
	synchronize_package_databases
	install_yay
}

synchronize_package_databases() {
	sudo pacman -Sy
}

install_yay() {
	if ! command -v yay &>/dev/null; then
		local working_directory=$(pwd)
		sudo pacman -S --noconfirm --needed git base-devel
		rm -rf /tmp/yay
		git clone https://aur.archlinux.org/yay.git /tmp/yay
		cd /tmp/yay
		makepkg --noconfirm -si
		sudo pacman -Rs --noconfirm go
		cd "$working_directory"
	fi
}

main "$@"

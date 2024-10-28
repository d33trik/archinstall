#!/bin/bash

# e - script stops on error
# u - error if undefined variable
# o pipefail - script fails if command piped fails
set -euo pipefail

main() {
	local block_device=${1:?}
	local boot_mode=${2:?}
	local hostname=${3:?}
	local keymap=${4:?}
	local locale=${5:?}
	local root_password=${6:?}
	local timezone=${7:?}
	local user_full_name=${8:?}
	local user_password=${9:?}
	local user_username=${10:?}

	synchronize_package_databases
	install_gum
	set_up_root_password
}

synchronize_package_databases() {
	clear
	echo "Synchronizing package databases..."
	sleep 1
	pacman -Sy &> /dev/null
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

set_up_root_password() {
	gum spin \
		--title="Setting up the root password..." \
		-- bash -c "
			sleep 1
			echo \"root:$root_password\" | chpasswd
		"
}

main "$@"

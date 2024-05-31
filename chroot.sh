#!/bin/bash

# e - script stops on error
# u - error if undefined variable
# o pipefail - script fails if command piped fails
set -euo pipefail

export GUM_SPIN_SHOW_ERROR=true
export GUM_SPIN_SPINNER=line
export GUM_SPIN_SPINNER_FOREGROUND=10
export GUM_SPIN_TITLE_FOREGROUND=15

main() {
	local block_device
	local boot_mode
	local hostname
	local keymap
	local locale
	local packages_to_install
	local root_password
	local timezone
	local user_full_name
	local user_password
	local user_username

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--block-device)
				block_device="$2"
				shift 2
				;;
			--boot-mode)
				boot_mode="$2"
				shift 2
				;;
			--hostname)
				hostname="$2"
				shift 2
				;;
			--keymap)
				keymap="$2"
				shift 2
				;;
			--locale)
				locale="$2"
				shift 2
				;;
			--packages-to-install)
				packages_to_install="$2"
				shift 2
				;;
			--root-password)
				root_password="$2"
				shift 2
				;;
			--timezone)
				timezone="$2"
				shift 2
				;;
			--user-full-name)
				user_full_name="$2"
				shift 2
				;;
			--user-password)
				user_password="$2"
				shift 2
				;;
			--user-username)
				user_username="$2"
				shift 2
				;;
			*)
				echo "Unknown option: $1"
				exit 1
				;;
		esac
	done

	install_gum
}

install_gum() {
	clear
	echo "Installing gum..."
	pacman -Syu --noconfirm --needed gum &> /dev/null
	clear
}

main "$@"
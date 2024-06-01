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
	local packages_to_install
	local user_username

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--packages-to-install)
				packages_to_install="$2"
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

	enable_sudo_execution_without_password
	install_yay
	install_fonts
	install_packages
}

enable_sudo_execution_without_password() {
	gum spin \
		--title="Enabling sudo execution without a password..." \
		-- bash -c "
			sleep 1
			sed -i '/^%wheel ALL=(ALL:ALL) ALL/s/^/# /' /etc/sudoers
			sed -i '/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/s/^# //' /etc/sudoers
		"
}

install_yay() {
	gum spin \
		--title="Installing yay..." \
		-- sudo -u "$user_username" bash -c "
			sudo pacman -S --noconfirm --needed git base-devel
			cd /tmp
			git clone https://aur.archlinux.org/yay.git
			cd yay
			makepkg --noconfirm -si
			sudo pacman -Rs --noconfirm go
		"
}

install_fonts() {
	gum spin \
	--title="Installing some fonts..." \
	-- bash -c "
		pacman -S --noconfirm --needed ttf-dejavu ttc-iosevka otf-monaspace ttf-monaspace-variable
	"
}

install_packages() {
	local packages=$(grep -E "$packages_to_install" "packages.csv")
	local total=$(echo "$packages" | wc -l)
	local index=0

	echo "$packages" | while read -r package; do
		local package_name=$(echo "$package" | awk -F, {'print $2'})
		local installation_method=$(echo "$package" | awk -F, {'print $3'})
		index=$(( "$index" + 1 ))

		case $installation_method in
			pacman)
				install_pakage_with_pacman
				;;
			aur)
				install_pakage_with_yay
				;;
			custom)
				custom_package_install
				;;
		esac
	done
}

install_pakage_with_pacman() {
	gum spin \
		--title="[$index/$total] Installing $package_name..." \
		-- bash -c "
			pacman -S --noconfirm --needed \"$package_name\"
		"
}

main "$@"

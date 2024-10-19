#!/bin/bash

# e - script stops on error
# u - error if undefined variable
# o pipefail - script fails if command piped fails
set -euo pipefail

main() {
	local install_dotfiles=${1:?}
	local packages=${2}
	local user_username=${3:?}

	enable_sudo_execution_without_password
	install_yay
	install_fonts
	install_packages
	disable_sudo_execution_without_password
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
	-- sudo -u "$user_username" bash -c "
		sudo pacman -S --noconfirm --needed ttf-dejavu ttf-sourcecodepro-nerd
	"
}

install_packages() {
	if [[ -v packages && -n ${packages[*]} ]]; then
		local packages_to_install=$(grep -E "$packages" "archinstall/src/packages.csv")
		local total=$(echo "$packages_to_install" | wc -l)
		local index=0

		echo "$packages_to_install" | while read -r package; do
			local package_name=$(echo "$package" | awk -F, {'print $1'})
			index=$(( "$index" + 1 ))
			install_$package_name
		done
	fi
}

install_alacritty() {
	gum spin \
	--title="[$index/$total] Installing $package_name..." \
	-- sudo -u "$user_username" bash -c "
		sudo pacman -S --noconfirm --needed alacritty
	"
}

disable_sudo_execution_without_password() {
	gum spin \
		--title="Disabling sudo execution without a password..." \
		-- bash -c "
			sleep 1
			sed -i '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers
			sed -i '/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/s/^/# /' /etc/sudoers
		"
}

main "$@"

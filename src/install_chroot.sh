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
	set_up_user_account
	set_up_timezone
	set_up_localization
	set_up_graphical_interface
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

set_up_user_account() {
	gum spin \
		--title="Setting up the user account..." \
		-- bash -c "
			sleep 1
			useradd -m -g wheel -s /bin/bash -c \"$user_full_name\" \"$user_username\"
			echo \"$user_username:$user_password\" | chpasswd
			sed -i '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers
		"
}

set_up_timezone() {
	gum spin \
		--title="Setting up the timezone..." \
		-- bash -c "
			sleep 1
			ln -sf /usr/share/zoneinfo/\"$timezone\" /etc/localtime
			timedatectl set-ntp true
			hwclock --systohc
		"
}

set_up_localization() {
	local locale_prefix=$(echo $locale | awk '{print $1}')

	gum spin \
		--title="Setting up the localization..." \
		-- bash -c "
			sleep 1
			echo \"$locale\" >> /etc/locale.gen
			locale-gen
			echo \"LANG=$locale_prefix\" > /etc/locale.conf
			echo \"KEYMAP=$keymap\" >> /etc/vconsole.conf
		"
}

set_up_graphical_interface() {
	gum spin \
		--title="Setting up the graphical interface..." \
		-- bash -c "
			pacman -S --noconfirm xorg xorg-xinit i3-wm i3status dmenu arandr
			echo \"exec i3\" > /home/\"$user_username\"/.xinitrc
			chown \"$user_username\":wheel /home/\"$user_username\"/.xinitrc
			mkdir -p /etc/X11/xorg.conf.d
			cat <<EOF > /etc/X11/xorg.conf.d/00-keyboard.conf
Section \"InputClass\"
	Identifier \"system-keyboard\"
	MatchIsKeyboard \"on\"
	Option \"XkbLayout\" \"$keymap\"
EndSection
EOF
		"
}

main "$@"

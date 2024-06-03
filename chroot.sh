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
	local dotfiles
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
			--dotfiles)
				dotfiles="$2"
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
	setup_root_password
	setup_user_account
	setup_timezone
	setup_localization
	setup_graphical_interface
	setup_audio_interface
	setup_network_interface
	setup_bootloader
	install_packages
}

install_gum() {
	clear
	echo "Installing gum..."
	pacman -Syu --noconfirm --needed gum &> /dev/null
	clear
}

setup_root_password() {
	gum spin \
		--title="Setting up the root password..." \
		-- bash -c "
			sleep 1
			echo \"root:$root_password\" | chpasswd
		"
}

setup_user_account() {
	gum spin \
		--title="Setting up the user account..." \
		-- bash -c "
			sleep 1
			useradd -m -g wheel -s /bin/bash -c \"$user_full_name\" \"$user_username\"
			echo \"$user_username:$user_password\" | chpasswd
			sed -i '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers
		"
}

setup_timezone() {
	gum spin \
		--title="Setting up the timezone..." \
		-- bash -c "
			sleep 1
			ln -sf /usr/share/zoneinfo/\"$timezone\" /etc/localtime
			timedatectl set-ntp true
			hwclock --systohc
		"
}

setup_localization() {
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

setup_graphical_interface() {
	gum spin \
		--title="Setting up the graphical interface..." \
		-- bash -c "
			pacman -S --noconfirm xorg xorg-xinit i3-wm i3status i3lock arandr dmenu
			echo \"exec i3\" > /home/\"$user_username\"/.xinitrc
			chown \"$user_username\":wheel /home/\"$user_username\"/.xinitrc
			mkdir -p /etc/X11/xorg.conf.d
			cat <<EOF > /etc/X11/xorg.conf.d/00-keyboard.conf
Section \"InputClass\"
	Identifier \"system-keyboard\"
	MatchIsKeyboard \"on\"
	Option \"XkbLayout\" \"us\"
EndSection
EOF
		"
}

setup_audio_interface() {
	gum spin \
		--title="Setting up the audio interface..." \
		-- bash -c "
			pacman -S --noconfirm pulseaudio pulseaudio-alsa pulseaudio-jack pavucontrol
			cat <<EOF >> /etc/pulse/default.pa.d/noise-cancellation.pa
### Enable Echo/Noise-Cancellation
load-module module-echo-cancel use_master_format=1 aec_method=webrtc aec_args=\"analog_gain_control=0 digital_gain_control=1\" source_name=echoCancel_source sink_name=echoCancel_sink
set-default-source echoCancel_source
set-default-sink echoCancel_sink
EOF
			pulseaudio -k
			pulseaudio --start
		"
}

setup_network_interface() {
	gum spin \
		--title="Setting up the network interface..." \
		-- bash -c "
			echo \"$hostname\" > /etc/hostname
			yes | pacman -S networkmanager iptables-nft ufw gufw
			systemctl enable NetworkManager.service 
			systemctl enable ufw.service
			systemctl start ufw.service
			ufw enable
		"
}

setup_bootloader() {
	gum spin \
		--title="Setting up the bootloader..." \
		-- bash -c "
			if [ \"$boot_mode\" = 1 ]; then
				pacman -S --noconfirm grub efibootmgr
				grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot
			else
				pacman -S --noconfirm grub
				grub-install \"$block_device\"
			fi
			grub-mkconfig -o /boot/grub/grub.cfg
		"
}

install_packages() {
	bash packages.sh \
		--dotfiles "$dotfiles" \
		--packages-to-install "$packages_to_install" \
		--user-username "$user_username"
}

main "$@"

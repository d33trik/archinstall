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
	local sound_server=${7:?}
	local timezone=${8:?}
	local user_full_name=${9:?}
	local user_password=${10:?}
	local user_username=${11:?}

	synchronize_package_databases
	install_gum
	set_up_root_password
	set_up_user_account
	set_up_timezone
	set_up_localization
	set_up_sound_server
	set_up_network_interface
	create_new_initramfs
	set_up_boot_loader
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

set_up_sound_server() {
	gum spin \
		--title="Setting up the sound server..." \
		-- bash -c "
			if [ \"$sound_server\" = \"PulseAudio\" ]; then
				pacman -S --noconfirm pulseaudio pulseaudio-alsa pulseaudio-jack pavucontrol
				cat <<EOF >> /etc/pulse/default.pa.d/noise-cancellation.pa
### Enable Echo/Noise-Cancellation
load-module module-echo-cancel use_master_format=1 aec_method=webrtc aec_args=\"analog_gain_control=0 digital_gain_control=1\" source_name=echoCancel_source sink_name=echoCancel_sink
set-default-source echoCancel_source
set-default-sink echoCancel_sink
EOF
				pulseaudio -k
				pulseaudio --start
			fi
		"
}

set_up_network_interface() {
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

create_new_initramfs() {
	gum spin \
	--title="Creating new initramfs..." \
	-- bash -c "
		mkinitcpio -P
	"
}

set_up_boot_loader() {
	gum spin \
		--title="Setting up the boot loader..." \
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

main "$@"

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
	set_up_root_password
	set_up_user_account
	set_up_timezone
	set_up_localization
	set_up_network
	create_new_initramfs
	set_up_boot_loader
}

synchronize_package_databases() {
	pacman -Sy
}

set_up_root_password() {
	echo "root:$root_password" | chpasswd
}

set_up_user_account() {
	useradd -m -g wheel -s /bin/bash -c "$user_full_name" "$user_username"
	echo "$user_username:$user_password" | chpasswd
	sed -i '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers
}

set_up_timezone() {
	ln -sf /usr/share/zoneinfo/"$timezone" /etc/localtime
	timedatectl set-ntp true
	hwclock --systohc
}

set_up_localization() {
	local locale_prefix=$(echo $locale | awk '{print $1}')
	echo "$locale" >> /etc/locale.gen
	locale-gen
	echo "LANG=$locale_prefix" > /etc/locale.conf
	echo "KEYMAP=$keymap" >> /etc/vconsole.conf
}

set_up_network() {
	echo "$hostname" > /etc/hostname
	pacman -S --noconfirm networkmanager
	systemctl enable NetworkManager.service
}

create_new_initramfs() {
	mkinitcpio -P
}

set_up_boot_loader() {
	if [ "$boot_mode" = 1 ]; then
		pacman -S --noconfirm grub efibootmgr
		grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot
	else
		pacman -S --noconfirm grub
		grub-install "$block_device"
	fi
	grub-mkconfig -o /boot/grub/grub.cfg
}

main "$@"

#!/bin/bash

# e - script stops on error
# u - error if undefined variable
# o pipefail - script fails if command piped fails
set -euo pipefail

main() {
	local boot_mode
	local boot_partition_type
	local keymap
	local locale
	local timezone
	local root_password
	local root_password_confirmation
	local user_full_name
	local user_username
	local user_password
	local user_password_confirmation
	local hostname
	local block_device
	local swap_size
	local wipe_method
	local mirrorlist_country
	local mirrorlist_country_code
	local packages
	local install_dotfiles

	display_welcome_message
	get_boot_mode
	select_keyboard_layout
	setup_keyboard_layout
	select_locale
	select_timezone
	get_root_password
	get_root_password_confirmation
	validate_root_password
	get_user_full_name
	get_user_username
	get_user_password
	get_user_password_confirmation
	validate_user_password
	get_hostname
	select_block_device
	get_swap_size
	select_wipe_method
	select_mirrorlist_country
	select_packages_to_install
	get_install_dotfiles
	display_isntallation_summary
	update_system_clock
	wipe_block_device
	partition_block_device
	format_partitions
	mount_filesystems
	uptate_pacman_mirrorlist
	install_essential_packages
	generate_fstab
	copy_files_to_mnt
	install_chroot
	clean_installation_files
	display_installation_completed_message
	reboot_the_system
}

display_welcome_message() {
	local prompt=$(
		gum format \
			--type="markdown" -- \
			"$(gum style --bold --foreground="11" "Attention!")" \
			"" \
			"Welcome to my Arch Linux installation script!" \
			"" \
			"This script will guide you through an installation of Arch Linux" \
			"based on my preferred settings." \
			"" \
			"However, feel free to modify it to fit your own needs." \
			"" \
			"$(gum style --bold --foreground="9" "Important Note:") Running this script will completely erase all data" \
			"on the disk you choose for installation." \
			"" \
			"Are you ready to proceed?" |
		gum style \
			--border="normal" \
			--margin="1" \
			--padding="1 2" \
			--border-foreground="7"
	)

	gum confirm \
		--default="false" \
		"$prompt"
}

get_boot_mode() {
	gum spin \
		--title="Getting boot mode..." \
		-- sleep 1

	if cat /sys/firmware/efi/fw_platform_size &> /dev/null; then
		boot_mode=1
		boot_partition_type=1
	else
		boot_mode=0
		boot_partition_type=4
	fi
}

select_keyboard_layout() {
	keymap=$(
		localectl list-keymaps |
		gum filter \
			--header="Keyboard Layout" \
			--placeholder="Select your keyboard layout..."
	)
}

setup_keyboard_layout() {
	gum spin \
		--title="Setting up the keyboard layout..." \
		-- bash -c "
			sleep 1
			loadkeys \"$keymap\"
		"
}

select_locale() {
	locale=$(
		cat /usr/share/i18n/SUPPORTED |
		gum filter \
			--header="Locale" \
			--placeholder="Select your preferred locale..."
	)
}

select_timezone() {
	timezone=$(
		timedatectl list-timezones |
		gum filter \
			--header="Timezone" \
			--placeholder="Select your time zone..."
	)
}

get_root_password() {
	root_password=$(
		gum input \
			--password="true" \
			--header="Root Password" \
			--placeholder="Set a secure root password..."
	)
}

get_root_password_confirmation() {
	root_password_confirmation=$(
		gum input \
			--password="true" \
			--header="Root Password Confirmation" \
			--placeholder="Confirm your root password..."
	)
}

validate_root_password() {
	if [[ $root_password != $root_password_confirmation ]]; then
		echo -e "$(gum style --bold --foreground="9" "ERROR:") Passwords do not match. Please try again."; sleep 2; clear
		get_root_password
		get_root_password_confirmation
		validate_root_password
	fi
}

get_user_full_name() {
	user_full_name=$(
		gum input \
			--header="User Full Name" \
			--placeholder="Please enter your first and last name..."
	)
}

get_user_username() {
	user_username=$(
		gum input \
			--header="User Username" \
			--placeholder="Create a username for your account...."
	)
}

get_user_password() {
	user_password=$(
		gum input \
			--password="true" \
			--header="User Password" \
			--placeholder="Set a secure password..."
	)
}

get_user_password_confirmation() {
	user_password_confirmation=$(
		gum input \
			--password="true" \
			--header="User Password Confirmation" \
			--placeholder="Confirm your password..."
	)
}

validate_user_password() {
	if [[ $user_password != $user_password_confirmation ]]; then
		echo -e "$(gum style --bold --foreground="9" "ERROR:") Passwords do not match. Please try again."; sleep 2; clear
		get_user_password
		get_user_password_confirmation
		validate_user_password
	fi
}

get_hostname() {
	hostname=$(
		gum input \
			--header="Hostname" \
			--placeholder="Enter a hostname for your system...."
	)
}

select_block_device() {
	block_device=$(
		lsblk \
			--noheadings \
			--nodeps \
			--paths \
			--output NAME,SIZE |
		gum choose \
			--header="Select the block device where you want to install the system..." \
	)

	block_device=$(
		echo $block_device |
		awk '{print $1}'
	)
}

get_swap_size() {
	local default_swap_size=8

	swap_size=$(
		gum input \
			--header="SWAP Size" \
			--placeholder="Enter a value for the swap size, leave blank to default (8GB)..."
	)

	[[ $swap_size =~ ^[0-9]+$ ]] || swap_size=$default_swap_size
}

select_wipe_method() {
	local wipe_methods=(
		"1 DD /dev/zero (Faster & Prevent Easy Recovery)"
		"2 DD /dev/random (Slower & Prevent Hard Recovery)"
		"3 No Need (The Device is Empty)"
	)

	wipe_method=$(
		printf "%s\n" "${wipe_methods[@]}" |
		gum choose \
			--header="Select your preferred wipe method..."
	)
}

select_mirrorlist_country() {
	local countries=$(awk -F, 'NR > 1 {print $1}' "archinstall/src/countries.csv")

	mirrorlist_country=$(
		echo "$countries" |
		gum filter \
			--header="Pacman Mirrorlist" \
			--placeholder="Select the region closest to your location..."
	)

	mirrorlist_country_code=$(grep "$mirrorlist_country" "archinstall/src/countries.csv" | awk -F, '{print $2}')
}

select_packages_to_install() {
	local package_list=$(awk -F, 'NR > 1 {print $1}' "archinstall/src/packages.csv" | sort)
	local pre_selected_packages_list=$(grep "true" "archinstall/src/packages.csv" | awk -F, '{print $1}' | sort)

	local pre_selected_packages=()
	for pre_selected_package in $pre_selected_packages_list; do
		pre_selected_packages+=("--selected=$pre_selected_package")
	done

	packages=$(
		echo "$package_list" |
		gum choose \
			--no-limit \
			--header="Select the packages you want to install..." \
			"${pre_selected_packages[@]}"
	)
}

get_install_dotfiles() {
	install_dotfiles=$(
		gum choose \
			--header="Install dotfiles?" \
			--height=4 \
			--selected="No" \
			"Yes" "No"
	)
}

display_isntallation_summary() {
	local prompt=$(
		gum format \
			--type="markdown" -- \
			"$(gum style --bold --foreground="10" "Ready to Install?")" \
			"" \
			"Here's a quick overview of your Arch Linux setup:" \
			"" \
			"$(gum style --bold --foreground="10" "[User]")" \
			"Name:                 $user_full_name" \
			"Username:             $user_username" \
			"" \
			"$(gum style --bold --foreground="10" "[System]")" \
			"Boot Mode:            $([[ $boot_mode = 1 ]] && echo "UEFI" || echo "BIOS")" \
			"Locale:               $locale" \
			"Timezone:             $timezone" \
			"Keyboard Layout:      $keymap" \
			"Hostname:             $hostname" \
			"Mirrorlist Country:   $mirrorlist_country" \
			"" \
			"$(gum style --bold --foreground="10" "[Instalation]")" \
			"Block Device:         $block_device" \
			"SWAP Size:            $swap_size GB" \
			"Whipe Method:         $wipe_method" \
			"" \
			"$(gum style --bold --foreground="10" "[Packages]")" \
			"Install dotfiles?     $install_dotfiles" \
			"$(gum style --width="65" "$(echo $packages | sed 's/ /, /g')")" |
		gum style \
			--border="normal" \
			--margin="1" \
			--padding="1 2" \
			--border-foreground="7"
	)

	gum confirm \
		--default="false" \
		--affirmative="Yes, Install" \
		--negative="No, Edit" \
		"$prompt"
}

update_system_clock() {
	gum spin \
		--title="Updating system clock..." \
		-- bash -c "
			sleep 1
			timedatectl set-ntp true
		"
}

wipe_block_device() {
	local block_device_size=$(sudo blockdev --getsize64 $block_device)
	local wipe_method_code=$(
		echo $wipe_method |
		awk '{print $1}'
	)

	set +e
	case $wipe_method_code in
	1)
		echo "$(gum style --foreground="15" "Wiping block device $block_device...")"
		dd if=/dev/zero | pv --progress --timer --eta --size $block_device_size | dd of=$block_device &>/dev/null
		;;
	2)
		echo "$(gum style --foreground="15" "Wiping block device $block_device...")"
		dd if=/dev/random | pv --progress --timer --eta --size $block_device_size | dd of=$block_device &>/dev/null
		;;
	3) ;;
	esac
	set -e

	sleep 1
	clear
}

partition_block_device() {
	gum spin \
		--title="Partitioning block device $block_device..." \
		-- bash -c "
			sleep 1
			partprobe \"$block_device\"
			fdisk \"$block_device\" << EOF
			g
			n


			+512M
			t
			$boot_partition_type
			n


			+${swap_size}G
			n



			w
			EOF
			partprobe \"$block_device\"
		"
}

format_partitions() {
	echo "$block_device" | grep -E 'nvme' &>/dev/null && block_device="${block_device}p"

	gum spin \
		--title="Formatting partitions..." \
		-- bash -c "
			sleep 1
			[[ \"$boot_mode\" == 1 ]] && mkfs.fat -F32 \"${block_device}1\"
			mkswap \"${block_device}2\"
			mkfs.ext4 \"${block_device}3\"
		"
}

mount_filesystems() {
	gum spin \
		--title="Mounting filesystems..." \
		-- bash -c "
			sleep 1
			mount \"${block_device}3\" /mnt
			swapon \"${block_device}2\"
			[[ \"$boot_mode\" == 1 ]] && mkdir -p /mnt/boot && mount \"${block_device}\"1 /mnt/boot
		"
}

uptate_pacman_mirrorlist() {
	local mirrorlist_url="https://archlinux.org/mirrorlist/?country=$mirrorlist_country_code&protocol=http&protocol=https&ip_version=4&use_mirror_status=on"

	gum spin \
		--title="Updating pacman mirrorlist..." \
		-- bash -c "
			pacman -S --noconfirm pacman-contrib &&
			curl -s \"$mirrorlist_url\" > /etc/pacman.d/mirrorlist.unranked &&
			sed '/^##/d; /^[[:space:]]*$/d; s/^#Server/Server/' /etc/pacman.d/mirrorlist.unranked > /etc/pacman.d/mirrorlist.tmp &&
			mv /etc/pacman.d/mirrorlist.tmp /etc/pacman.d/mirrorlist.unranked &&
			rankmirrors -n 5 /etc/pacman.d/mirrorlist.unranked > /etc/pacman.d/mirrorlist &&
			rm /etc/pacman.d/mirrorlist.unranked
		"
}

install_essential_packages() {
	echo "$(gum style --foreground="15" "Instaling essential packages...")"
	sleep 1
	pacstrap -K /mnt base base-devel linux linux-firmware
	sleep 1
	clear
}

generate_fstab() {
	gum spin \
		--title="Generating fstab..." \
		-- bash -c "
			sleep 1
			genfstab -U /mnt >> /mnt/etc/fstab
		"
}

copy_files_to_mnt() {
	gum spin \
		--title="Copying files to /mnt..." \
		-- bash -c "
			rm -rf /mnt/archinstall
			cp -r archinstall /mnt/archinstall
		"
}

install_chroot() {
	arch-chroot /mnt bash archinstall/src/install_chroot.sh \
	"$block_device" \
	"$boot_mode" \
	"$hostname" \
	"$install_dotfiles" \
	"$keymap" \
	"$locale" \
	"$packages" \
	"$root_password" \
	"$timezone" \
	"$user_full_name" \
	"$user_password" \
	"$user_username"
}

clean_installation_files() {
	gum spin \
		--title="Cleaning the installation files..." \
		-- bash -c "
			sleep 1
			rm -rf /mnt/archinstall
			umount -R /mnt
		"
}

display_installation_completed_message() {
	local prompt=$(
		gum format \
			--type="markdown" -- \
			"$(gum style --bold --foreground="10" "Installation Complete!")" \
			"" \
			"Congratulations!" \
			"" \
			"You have successfully installed and configured Arch Linux" \
			"based on the settings provided in this script." \
			"" \
			"Feel free to further customize your system as needed." \
			"" \
			"Thank you for using this installation script, and" \
			"enjoy your new Arch Linux setup!" \
			"" \
			"Do you want to restart the system now?" |
		gum style \
			--border="normal" \
			--margin="1" \
			--padding="1 2" \
			--border-foreground="7"
	)

	gum confirm \
		--default="false" \
		"$prompt"
}

reboot_the_system() {
	reboot
}

main "$@"

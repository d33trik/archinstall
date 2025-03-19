#!/bin/bash

# e - script stops on error
# u - error if undefined variable
# o pipefail - script fails if command piped fails
set -euo pipefail

export GUM_CHOOSE_CURSOR_PREFIX="[ ] "
export GUM_CHOOSE_CURSOR_FOREGROUND=10
export GUM_CHOOSE_HEADER_FOREGROUND=15
export GUM_CHOOSE_SELECTED_PREFIX="[X] "
export GUM_CHOOSE_SELECTED_FOREGROUND=10
export GUM_CHOOSE_UNSELECTED_PREFIX="[ ] "

export GUM_CONFIRM_SELECTED_BACKGROUND=7
export GUM_CONFIRM_SELECTED_FOREGROUND=0
export GUM_CONFIRM_UNSELECTED_BACKGROUND=0
export GUM_CONFIRM_UNSELECTED_FOREGROUND=7

export GUM_FILTER_CURSOR_TEXT_FOREGROUND=10
export GUM_FILTER_HEADER_FOREGROUND=15
export GUM_FILTER_INDICATOR_FOREGROUND=10
export GUM_FILTER_MATCH_FOREGROUND=10
export GUM_FILTER_PROMPT_FOREGROUND=10
export GUM_FILTER_WIDTH=0

export GUM_INPUT_CURSOR_FOREGROUND=7
export GUM_INPUT_CURSOR_MODE=static
export GUM_INPUT_PROMPT_FOREGROUND=10
export GUM_INPUT_WIDTH=0
export GUM_INPUT_HEADER_FOREGROUND=15

export GUM_SPIN_SHOW_ERROR=true
export GUM_SPIN_SPINNER=line
export GUM_SPIN_SPINNER_FOREGROUND=10
export GUM_SPIN_TITLE_FOREGROUND=15

main() {
	local github_url="https://raw.githubusercontent.com/d33trik/archinstall/trunk"

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

	synchronize_package_databases
	install_gum
	get_boot_mode
	get_keyboard_layout
	set_keyboard_layout
	get_locale
	get_timezone
	get_root_password
	get_root_password_confirmation
	validate_root_password
	get_user_full_name
	get_user_username
	get_user_password
	get_user_password_confirmation
	validate_user_password
	get_hostname
	get_block_device
	get_swap_size
	get_wipe_method
	get_mirrorlist_country
	display_isntallation_summary
	update_system_clock
	wipe_block_device
	partition_block_device
	format_partitions
	mount_filesystems
	uptate_pacman_mirrorlist
	install_base_packages
	generate_fstab
}

synchronize_package_databases() {
	pacman -Sy
}

install_gum() {
	pacman -S --noconfirm --needed gum
}

get_boot_mode() {
	if cat /sys/firmware/efi/fw_platform_size &> /dev/null; then
		boot_mode=1
		boot_partition_type=1
	else
		boot_mode=0
		boot_partition_type=4
	fi
}

get_keyboard_layout() {
	keymap=$(
		localectl list-keymaps |
		gum filter \
			--header="Keyboard Layout" \
			--placeholder="Select your keyboard layout..."
	)
}

set_keyboard_layout() {
		loadkeys "$keymap"
}

get_locale() {
	locale=$(
		cat /usr/share/i18n/SUPPORTED |
		gum filter \
			--header="Locale" \
			--placeholder="Select your preferred locale..."
	)
}

get_timezone() {
	timezone=$(
		timedatectl list-timezones |
		gum filter \
			--header="Time Zone" \
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

get_block_device() {
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

get_wipe_method() {
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

get_mirrorlist_country() {
	curl -LO "$github_url/mirrorlist_countries.csv"

	local countries=$(awk -F, 'NR > 1 {print $1}' "mirrorlist_countries.csv")

	mirrorlist_country=$(
		echo "$countries" |
		gum filter \
			--header="Pacman Mirrorlist" \
			--placeholder="Select the region closest to your location..."
	)

	mirrorlist_country_code=$(grep "$mirrorlist_country" "mirrorlist_countries.csv" | awk -F, '{print $2}')
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
			"Whipe Method:         $wipe_method" |
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
	timedatectl set-ntp true
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
	partprobe "$block_device"
	fdisk "$block_device" << EOF
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
	partprobe "$block_device"
}

format_partitions() {
	echo "$block_device" | grep -E 'nvme' &>/dev/null && block_device="${block_device}p"

	[[ "$boot_mode" == 1 ]] && mkfs.fat -F32 "${block_device}1"
	mkswap "${block_device}2"
	mkfs.ext4 "${block_device}3"
}

mount_filesystems() {
	mount "${block_device}3" /mnt
	swapon "${block_device}2"
	[[ "$boot_mode" == 1 ]] && mkdir -p /mnt/boot && mount "${block_device}"1 /mnt/boot
}

uptate_pacman_mirrorlist() {
	local mirrorlist_url="https://archlinux.org/mirrorlist/?country=$mirrorlist_country_code&protocol=http&protocol=https&ip_version=4&use_mirror_status=on"

	pacman -S --noconfirm pacman-contrib &&
	curl -s "$mirrorlist_url" > /etc/pacman.d/mirrorlist.unranked &&
	sed '/^##/d; /^[[:space:]]*$/d; s/^#Server/Server/' /etc/pacman.d/mirrorlist.unranked > /etc/pacman.d/mirrorlist.tmp &&
	mv /etc/pacman.d/mirrorlist.tmp /etc/pacman.d/mirrorlist.unranked &&
	rankmirrors -n 5 /etc/pacman.d/mirrorlist.unranked > /etc/pacman.d/mirrorlist &&
	rm /etc/pacman.d/mirrorlist.unranked
}

install_base_packages() {
	pacstrap -K /mnt base base-devel linux linux-firmware
}

generate_fstab() {
	genfstab -U /mnt >> /mnt/etc/fstab
}

main "$@"

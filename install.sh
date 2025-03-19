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

main "$@"

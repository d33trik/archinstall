#!/bin/bash

# e - script stops on error
# u - error if undefined variable
# o pipefail - script fails if command piped fails
set -euo pipefail

export GUM_CONFIRM_SELECTED_BACKGROUND=7
export GUM_CONFIRM_SELECTED_FOREGROUND=0
export GUM_CONFIRM_UNSELECTED_BACKGROUND=0
export GUM_CONFIRM_UNSELECTED_FOREGROUND=7

export GUM_FILTER_CURSOR_TEXT_FOREGROUND=10
export GUM_FILTER_HEADER_FOREGROUND=15
export GUM_FILTER_INDICATOR_FOREGROUND=10
export GUM_FILTER_MATCH_FOREGROUND=10
export GUM_FILTER_PROMPT_FOREGROUND=10
export GUM_FILTER_SELECTED_PREFIX=" + "
export GUM_FILTER_SELECTED_PREFIX_FOREGROUND=10
export GUM_FILTER_UNSELECTED_PREFIX=" - "
export GUM_FILTER_UNSELECTED_PREFIX_FOREGROUND=9
export GUM_FILTER_WIDTH=0

export GUM_INPUT_CURSOR_FOREGROUND=7
export GUM_INPUT_CURSOR_MODE=static
export GUM_INPUT_PROMPT_FOREGROUND=10
export GUM_INPUT_WIDTH=0
export GUM_INPUT_HEADER_FOREGROUND=15

export GUM_SPIN_SPINNER=line
export GUM_SPIN_SPINNER_FOREGROUND=10
export GUM_SPIN_TITLE_FOREGROUND=15

main() {
	local keymap
	local locale
	local timezone
	local root_password
	local root_password_confirmation
	local user_full_name
	local user_username
	local user_password

	install_gum
	show_installation_warning
	get_keyboard_layout
	setup_keyboard_layout
	get_locale
	get_timezone
	get_root_password
	get_root_password_confirmation
	validate_root_password
	get_user_full_name
	get_user_username
	get_user_password
}

install_gum() {
	clear
	echo "Installing gum..."
	pacman -Sy --noconfirm --needed gum &> /dev/null
	clear
}

show_installation_warning() {
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

get_keyboard_layout() {
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

main "$@"
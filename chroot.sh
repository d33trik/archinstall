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

main "$@"

#!/bin/bash

# e - script stops on error
# u - error if undefined variable
# o pipefail - script fails if command piped fails
set -euo pipefail

main() {
	local install_dotfiles=${1:?}
	local packages=${2:?}
	local user_username=${3:?}

	enable_sudo_execution_without_password
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

main "$@"

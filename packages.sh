#!/bin/bash

# e - script stops on error
# u - error if undefined variable
# o pipefail - script fails if command piped fails
set -euo pipefail

main() {
	synchronize_package_databases
	install_yay
	install_packages
	set_up_fish
	set_up_bluetooth
	set_up_pulse_audio
	set_up_firewall
	set_up_podman
	set_up_virt_manager
	set_up_dotfiles
}

synchronize_package_databases() {
	sudo pacman -Sy
}

install_yay() {
	if ! command -v yay &>/dev/null; then
		local working_directory=$(pwd)
		sudo pacman -S --noconfirm --needed git base-devel
		rm -rf /tmp/yay
		git clone https://aur.archlinux.org/yay.git /tmp/yay
		cd /tmp/yay
		makepkg --noconfirm -si
		sudo pacman -Rs --noconfirm go
		cd "$working_directory"
	fi
}

install_packages() {
	local packages
	if [ -f "data/packages.yaml" ]; then
			packages="data/packages.yaml"
	else
			packages="archinstall/data/packages.yaml"
	fi

	awk '/^ *- / {print $2}' "$packages" | while IFS= read -r package; do
		# Skip empty lines and comments
		[[ -z "$package" || "$package" == \#* ]] && continue

		# Install package
		yay -S --noconfirm --needed "$package"
	done
}

set_up_fish() {
	chsh -s /usr/bin/fish
}

set_up_bluetooth() {
	sudo systemctl enable bluetooth.service
	sudo systemctl start bluetooth.service
}

set_up_pulse_audio() {
	sudo gpasswd -a $(whoami) audio
	sudo rm -f /etc/pulse/default.pa.d/noise-cancellation.pa
	cat <<EOF >> sudo /etc/pulse/default.pa.d/noise-cancellation.pa
### Enable Echo/Noise-Cancellation
load-module module-echo-cancel use_master_format=1 aec_method=webrtc aec_args=\"analog_gain_control=0 digital_gain_control=1\" source_name=echoCancel_source sink_name=echoCancel_sink
set-default-source echoCancel_source
set-default-sink echoCancel_sink
EOF
	pulseaudio -k
	pulseaudio --start
}

set_up_firewall() {
	sudo systemctl enable ufw.service
	sudo systemctl start ufw.service
	sudo ufw enable
}

set_up_podman() {
	sudo systemctl enable podman-restart.service
	sudo rm -f /etc/containers/registries.conf.d/00-shortnames.conf
	sudo rm -f /etc/containers/registries.conf.d/00-unqualified-search-registries.conf
	echo 'unqualified-search-registries = ["docker.io"]' | sudo tee -a /etc/containers/registries.conf.d/00-unqualified-search-registries.conf
}

set_up_virt_manager() {
	sudo gpasswd -a $(whoami) libvirt
	sudo systemctl enable libvirtd.socket
	sudo rm -f /etc/libvirt/network.conf
	echo 'firewall_backend="iptables"' | sudo tee -a /etc/libvirt/network.conf
}

set_up_dotfiles() {
	cd /home/"$(whoami)"
	rm -rf dotfiles
	git clone https://github.com/d33trik/dotfiles.git
	cd dotfiles
	git remote set-url origin git@github.com:d33trik/dotfiles.git
	stow .
}

main "$@"

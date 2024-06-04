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
	local dotfiles_url="https://github.com/d33trik/dotfiles.git"

	local dotfiles
	local packages_to_install
	local user_username

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--dotfiles)
				dotfiles="$2"
				shift 2
				;;
			--packages-to-install)
				packages_to_install="$2"
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

	enable_sudo_execution_without_password
	install_yay
	install_fonts
	install_packages
	install_dotfiles
	disable_sudo_execution_without_password
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

install_yay() {
	gum spin \
		--title="Installing yay..." \
		-- sudo -u "$user_username" bash -c "
			sudo pacman -S --noconfirm --needed git base-devel
			cd /tmp
			git clone https://aur.archlinux.org/yay.git
			cd yay
			makepkg --noconfirm -si
			sudo pacman -Rs --noconfirm go
		"
}

install_fonts() {
	gum spin \
	--title="Installing some fonts..." \
	-- bash -c "
		pacman -S --noconfirm --needed ttf-dejavu ttc-iosevka otf-monaspace ttf-monaspace-variable adobe-source-code-pro-fonts
	"
}

install_packages() {
	local packages=$(grep -E "$packages_to_install" "packages.csv")
	local total=$(echo "$packages" | wc -l)
	local index=0

	echo "$packages" | while read -r package; do
		local package_name=$(echo "$package" | awk -F, {'print $2'})
		local installation_method=$(echo "$package" | awk -F, {'print $3'})
		index=$(( "$index" + 1 ))

		case $installation_method in
			pacman)
				install_pakage_with_pacman
				;;
			aur)
				install_pakage_with_yay
				;;
			custom)
				custom_package_install
				;;
		esac
	done
}

install_pakage_with_pacman() {
	gum spin \
		--title="[$index/$total] Installing $package_name..." \
		-- bash -c "
			pacman -S --noconfirm --needed \"$package_name\"
		"
}

install_pakage_with_yay() {
	gum spin \
		--title="[$index/$total] Installing $package_name..." \
		-- bash -c "
			yay -S --noconfirm --needed \"$package_name\"
		"
}

custom_package_install() {
	case $package_name in
		beekeeper-studio)
			install_beekeeper_studio
			;;
		breeze)
			install_breeze
			;;
		docker)
			install_docker
			;;
		nodejs)
			install_nodejs
			;;
		obsidian)
			install_obsidian
			;;
		virtualization)
			install_virtualization
			;;
	esac
}

install_asdf() {
	gum spin \
		--title="[$index/$total] Installing $package_name..." \
		-- sudo -u "$user_username" bash -c "
			sudo pacman -S --noconfirm --needed curl git
			git clone https://github.com/asdf-vm/asdf.git \"/home/$user_username/.asdf\" --branch v0.14.0
			echo '. \"/home/$user_username/.asdf/asdf.sh\"' >> \"/home/$user_username/.bashrc\"
			echo '. \"/home/$user_username/.asdf/completions/asdf.bash\"' >> \"/home/$user_username/.bashrc\"
		"
}

install_beekeeper_studio() {
	gum spin \
		--title="[$index/$total] Installing $package_name..." \
		-- bash -c "
			pacman -S --noconfirm --needed fuse2
			curl -sLo beekeeper-studio.AppImage $(curl -s https://api.github.com/repos/beekeeper-studio/beekeeper-studio/releases/latest | grep browser_download_url.*AppImage | grep -v "arm64" | cut -d\" -f4)
			mkdir /opt/beekeeper-studio
			mv beekeeper-studio.AppImage /opt/beekeeper-studio
			chmod +x /opt/beekeeper-studio/beekeeper-studio.AppImage
			ln -s /opt/beekeeper-studio/beekeeper-studio.AppImage /usr/bin/beekeeper-studio
		"
}

install_breeze() {
	gum spin \
		--title="[$index/$total] Installing $package_name..." \
		-- sudo -u "$user_username" bash -c "
			sudo pacman -S --noconfirm --needed breeze
			mkdir -p \"/home/$user_username/.local/share/icons/default\"
			echo \"[Icon Theme]\" > \"/home/$user_username/.local/share/icons/default/index.theme\"
			echo \"Inherits=breeze_cursors\" >> \"/home/$user_username/.local/share/icons/default/index.theme\"
			mkdir -p \"/home/$user_username/.icons/default\"
			echo \"[Icon Theme]\" > \"/home/$user_username/.icons/default/index.theme\"
			echo \"Inherits=breeze_cursors\" >> \"/home/$user_username/.icons/default/index.theme\"
			sudo mkdir -p \"/usr/share/icons/default\"
			sudo echo \"[Icon Theme]\" > \"/usr/share/icons/default/index.theme\"
			sudo echo \"Inherits=breeze_cursors\" >> \"/usr/share/icons/default/index.theme\"
			echo \"Xcursor.theme: breeze_cursors\" >> \"/home/$user_username/.Xresources\"
			sed -i \"/^exec i3/i xrdb -merge ~/.Xresources\" \"/home/$user_username/.xinitrc\"
		"
}

install_docker() {
	gum spin \
		--title="[$index/$total] Installing $package_name..." \
		-- bash -c "
			pacman -S --noconfirm --needed docker docker-compose
			systemctl enable docker.socket
		"
}

install_nodejs() {
	if [ ! -e "/home/$user_username/.asdf/asdf.sh" ]; then
		install_asdf
	fi

	gum spin \
		--title="[$index/$total] Installing $package_name..." \
		-- sudo -u "$user_username" bash -c "
			source \"/home/$user_username/.asdf/asdf.sh\"
			asdf plugin add nodejs
			asdf nodejs update-nodebuild
			asdf install nodejs \$(asdf nodejs resolve lts --latest-available)
			asdf global nodejs \$(asdf nodejs resolve lts --latest-available)
		"
}

install_obsidian() {
	gum spin \
		--title="[$index/$total] Installing $package_name..." \
		-- bash -c "
			pacman -S --noconfirm --needed fuse2
			curl -sLo obsidian.AppImage $(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest | grep browser_download_url.*AppImage | grep -v "arm64" | cut -d\" -f4)
			mkdir /opt/obsidian
			mv obsidian.AppImage /opt/obsidian
			chmod +x /opt/obsidian/obsidian.AppImage
			ln -s /opt/obsidian/obsidian.AppImage /usr/bin/obsidian
		"
}

install_virtualization() {
	gum spin \
		--title="[$index/$total] Installing $package_name..." \
		-- bash -c "
			pacman -S --noconfirm --needed qemu-full libvirt virt-manager iptables-nft dnsmasq dmidecode edk2-ovmf
			gpasswd -a \"$user_username\" libvirt
			systemctl enable libvirtd.socket
		"
}

install_dotfiles() {
	if [ "$dotfiles" = "Yes" ]; then
		gum spin \
			--title="Installing dotfiles..." \
			-- sudo -u "$user_username" bash -c "
				sudo pacman -S --noconfirm --needed git
				git clone \"$dotfiles_url\" \"/home/$user_username/dotfiles\"
				cd \"/home/$user_username/dotfiles\"
				chmod u+x install.sh
				bash install.sh
			"
	fi
}

disable_sudo_execution_without_password() {
	gum spin \
		--title="Disabling sudo execution without a password..." \
		-- bash -c "
			sleep 1
			sed -i '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers
			sed -i '/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/s/^/# /' /etc/sudoers
		"
}

main "$@"

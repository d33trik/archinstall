#!/bin/bash

# e - script stops on error
# u - error if undefined variable
# o pipefail - script fails if command piped fails
set -euo pipefail

main() {
	local install_dotfiles=${1:?}
	local packages=${2}
	local restore_vault_backup=${3:?}
	local user_username=${4:?}
	local vault_backup_device=${5}

	enable_sudo_execution_without_password
	install_yay
	install_fonts
	install_packages
	install_dotfiles
	restore_vault_backup
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
	-- sudo -u "$user_username" bash -c "
		sudo pacman -S --noconfirm --needed ttf-dejavu ttf-sourcecodepro-nerd
	"
}

install_packages() {
	if [[ -v packages && -n ${packages[*]} ]]; then
		local packages_to_install=$(grep -E "$packages" "archinstall/src/packages.csv")
		local total=$(echo "$packages_to_install" | wc -l)
		local index=0

		echo "$packages_to_install" | while read -r package; do
			local package_name=$(echo "$package" | awk -F, {'print $1'})
			index=$(( "$index" + 1 ))
			install_$package_name
		done
	fi
}

install_alacritty() {
	gum spin \
	--title="[$index/$total] Installing $package_name..." \
	-- sudo -u "$user_username" bash -c "
		sudo pacman -S --noconfirm --needed alacritty
	"
}

install_beekeeper-studio(){
	gum spin \
	--title="[$index/$total] Installing $package_name..." \
	-- sudo -u "$user_username" bash -c "
		sudo pacman -S --noconfirm --needed fuse2
		cd /tmp
		curl -sLo beekeeper-studio.AppImage $(curl -s https://api.github.com/repos/beekeeper-studio/beekeeper-studio/releases/latest | grep browser_download_url.*AppImage | grep -v "arm64" | cut -d\" -f4)
		sudo mkdir /opt/beekeeper-studio
		sudo mv beekeeper-studio.AppImage /opt/beekeeper-studio
		sudo chmod +x /opt/beekeeper-studio/beekeeper-studio.AppImage
		sudo ln -s /opt/beekeeper-studio/beekeeper-studio.AppImage /usr/bin/beekeeper-studio
	"
}

install_chromium() {
	gum spin \
	--title="[$index/$total] Installing $package_name..." \
	-- sudo -u "$user_username" bash -c "
		sudo pacman -S --noconfirm --needed chromium
	"
}

install_firefox() {
	gum spin \
	--title="[$index/$total] Installing $package_name..." \
	-- sudo -u "$user_username" bash -c "
		sudo pacman -S --noconfirm --needed firefox
	"
}

install_fish() {
	gum spin \
	--title="[$index/$total] Installing $package_name..." \
	-- sudo -u "$user_username" bash -c "
		sudo pacman -S --noconfirm --needed fish
		sudo chsh -s /usr/bin/fish \"$user_username\"
	"
}

install_gimp() {
	gum spin \
	--title="[$index/$total] Installing $package_name..." \
	-- sudo -u "$user_username" bash -c "
		sudo pacman -S --noconfirm --needed gimp
	"
}

install_git() {
	gum spin \
	--title="[$index/$total] Installing $package_name..." \
	-- sudo -u "$user_username" bash -c "
		sudo pacman -S --noconfirm --needed git
	"
}

install_klavaro() {
	gum spin \
	--title="[$index/$total] Installing $package_name..." \
	-- sudo -u "$user_username" bash -c "
		sudo pacman -S --noconfirm --needed klavaro
	"
}

install_libvirt() {
	gum spin \
	--title="[$index/$total] Installing $package_name..." \
	-- sudo -u "$user_username" bash -c "
		sudo pacman -S --noconfirm --needed qemu-full libvirt virt-manager iptables-nft dnsmasq dmidecode edk2-ovmf
		sudo gpasswd -a \"$user_username\" libvirt
		sudo systemctl enable libvirtd.socket
	"

	echo firewall_backend=\"iptables\" >> /etc/libvirt/network.conf
}

install_neovim() {
	gum spin \
	--title="[$index/$total] Installing $package_name..." \
	-- sudo -u "$user_username" bash -c "
		sudo pacman -S --noconfirm --needed neovim xclip
	"
}

install_obsidian() {
	gum spin \
	--title="[$index/$total] Installing $package_name..." \
	-- sudo -u "$user_username" bash -c "
		sudo pacman -S --noconfirm --needed fuse2
		cd /tmp
		curl -sLo obsidian.AppImage $(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest | grep browser_download_url.*AppImage | grep -v "arm64" | cut -d\" -f4)
		sudo mkdir /opt/obsidian
		sudo mv obsidian.AppImage /opt/obsidian
		sudo chmod +x /opt/obsidian/obsidian.AppImage
		sudo ln -s /opt/obsidian/obsidian.AppImage /usr/bin/obsidian
	"
}

install_podman() {
	gum spin \
	--title="[$index/$total] Installing $package_name..." \
	-- sudo -u "$user_username" bash -c "
		sudo pacman -S --noconfirm --needed podman podman-compose
		sudo systemctl enable podman-restart.service
	"

	rm /etc/containers/registries.conf.d/00-shortnames.conf
	echo unqualified-search-registries = [\"docker.io\"] > /etc/containers/registries.conf.d/00-unqualified-search-registries.conf
}

install_remmina() {
	gum spin \
	--title="[$index/$total] Installing $package_name..." \
	-- sudo -u "$user_username" bash -c "
		sudo pacman -S --noconfirm --needed remmina freerdp
	"
}

install_utils() {
	gum spin \
	--title="[$index/$total] Installing $package_name..." \
	-- sudo -u "$user_username" bash -c "
		sudo pacman -S --noconfirm --needed \
		flameshot \
		htop \
		man man-pages \
		neofetch \
		openssh \
		poppler \
		udiskie dosfstools exfatprogs ntfs-3g \
		xcape \
		zip unzip
	"
}

install_zathura() {
	gum spin \
	--title="[$index/$total] Installing $package_name..." \
	-- sudo -u "$user_username" bash -c "
		sudo pacman -S --noconfirm --needed zathura zathura-cb zathura-djvu zathura-pdf-mupdf zathura-ps
	"
}

install_dotfiles() {
	if [ "$install_dotfiles" = "Yes" ]; then
		gum spin \
			--title="Installing dotfiles..." \
			-- sudo -u "$user_username" bash -c "
				sudo pacman -S --noconfirm --needed git
				git clone https://github.com/d33trik/dotfiles.git \"/home/$user_username/dotfiles\"
				cd \"/home/$user_username/dotfiles\"
				chmod u+x install.sh
				bash install.sh
			"
	fi
}

restore_vault_backup() {
	if [ "$restore_vault_backup" = "Yes" ]; then
		gum spin \
			--title="Restoring vault backup..." \
			-- sudo -u "$user_username" bash -c "
				mkdir \"/home/$user_username/backup\"
				sudo mount -o uid=$(id -u),gid=$(id -g),dmask=002,fmask=113 \"$vault_backup_device\" \"/home/$user_username/backup\"
				cp \"/home/$user_username/backup/vault.tar.gz\" \"/home/$user_username\"
				tar -xzf \"/home/$user_username/vault.tar.gz\" -C \"/home/$user_username\"
				sudo umount \"$vault_backup_device\"
				rm -rf \"/home/$user_username/backup\"
				rm \"/home/$user_username/vault.tar.gz\"
				bash \"/home/$user_username/vault/install.sh\"
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

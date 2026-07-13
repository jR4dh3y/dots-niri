#!/usr/bin/env bash
# Upgrade dotfiles - reruns symlink commands to update after changes.

set -euo pipefail
IFS=$'\n\t'

INSTALL_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=$(cd -- "$INSTALL_DIR/.." && pwd)
USER_NAME=${SUDO_USER:-${USER}}
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)

SUDO_CMD=""

msg() { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m==>\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m==>\033[0m %s\n" "$*" 1>&2; }
die() { err "$*"; exit 1; }

run_as_invoking_user() {
	if [[ -n ${SUDO_USER:-} && $EUID -eq 0 ]]; then
		HOME="$USER_HOME" sudo -u "$SUDO_USER" --preserve-env=HOME,PATH USER="$SUDO_USER" "$@"
	else
		"$@"
	fi
}

print_banner() {
cat <<'EOF'
------------------------------------------------------------------
 |                                                              |
 |                                                              |
 |        -- jR4dh3y dotfiles upgrade/sync --                   |
 |                                                              |
 |                                                              |
------------------------------------------------------------------
EOF
}

require_arch() {
	[[ -f /etc/arch-release ]] || die "This script is intended for Arch Linux."
}

check_sudo() {
	if [[ $EUID -ne 0 ]]; then
		command -v sudo >/dev/null 2>&1 || die "sudo is required for chown operations."
		SUDO_CMD="sudo"
	fi
}

update_symlinks() {
	msg "Updating symlinks for dotfiles in $USER_HOME"
	mkdir -p "$USER_HOME/.config" "$USER_HOME/.config/autostart" "$USER_HOME/.local/share" "$USER_HOME/bin"

	if [[ -d "$REPO_DIR/.config" ]]; then
		for d in "$REPO_DIR/.config"/*; do
			[[ -e "$d" ]] || continue
			local name
			name=$(basename "$d")
			local target="$USER_HOME/.config/$name"

			if [[ -L "$target" && "$(readlink -f "$target")" == "$(readlink -f "$d")" ]]; then
				msg "Already linked: $name"
				continue
			fi

			if [[ -L "$target" || -d "$target" || -f "$target" ]]; then
				warn "Backing up existing $target to ${target}.bak"
				mv -f "$target" "${target}.bak" || true
			fi

			msg "Linking $name"
			ln -s "$d" "$target"
		done
	fi

	if [[ -d "$REPO_DIR/.local" ]]; then
		msg "Syncing .local files"
		rsync -a --info=NAME --exclude="share/icons" --exclude="share/themes" "$REPO_DIR/.local/" "$USER_HOME/.local/"
	fi

	if [[ -d "$REPO_DIR/assets/wal" ]]; then
		msg "Syncing wallpapers"
		mkdir -p "$USER_HOME/.local/share/wallpapers"
		rsync -a --info=NAME "$REPO_DIR/assets/wal/" "$USER_HOME/.local/share/wallpapers/"
	fi

	if [[ -n "$SUDO_CMD" ]]; then
		msg "Fixing ownership"
		$SUDO_CMD chown -R "$USER_NAME":"$USER_NAME" "$USER_HOME/.config" "$USER_HOME/.local" "$USER_HOME/bin"
	fi
}

apply_desktop_theme() {
	local theme_script="$INSTALL_DIR/apply-theme.sh"

	if [[ ! -x "$theme_script" ]]; then
		warn "Skipping desktop theme apply; script not found or not executable: $theme_script"
		return
	fi

	msg "Applying Nonchalant-Purple desktop theme"
	run_as_invoking_user env THEME_REPO_DIR="$REPO_DIR" THEME_USER_HOME="$USER_HOME" bash "$theme_script" || warn "Theme apply did not complete; restart apps and apply manually if needed"
}

install_ly_config() {
	local src="$INSTALL_DIR/ly/config.ini"
	local dest="/etc/ly/config.ini"
	local dur_src

	if [[ ! -f "$src" ]]; then
		warn "Skipping ly config sync; file not found: $src"
		return
	fi

	msg "Syncing ly config"
	$SUDO_CMD install -Dm644 "$src" "$dest"

	# Tracked .dur animations (used when animation = dur_file)
	shopt -s nullglob
	for dur_src in "$INSTALL_DIR"/ly/*.dur; do
		msg "Syncing ly animation: $(basename "$dur_src")"
		$SUDO_CMD install -Dm644 "$dur_src" "/etc/ly/$(basename "$dur_src")"
	done
	shopt -u nullglob
}

install_nm_iwd_config() {
	local src="$INSTALL_DIR/networkmanager/conf.d/wifi_backend.conf"
	local dest="/etc/NetworkManager/conf.d/wifi_backend.conf"

	if [[ ! -f "$src" ]]; then
		warn "Skipping NetworkManager iwd config sync; file not found: $src"
		return
	fi

	msg "Syncing NetworkManager iwd backend config"
	$SUDO_CMD install -Dm644 "$src" "$dest"
}

install_gpu_switch_config() {
	local helper_dir="$INSTALL_DIR/gpu-switch/usr-local-sbin"
	local udev_rule="$INSTALL_DIR/gpu-switch/udev/90-nvidia-no-seat.rules"
	local helper

	if [[ -d "$helper_dir" ]]; then
		msg "Syncing GPU switch helpers"
		for helper in "$helper_dir"/*; do
			[[ -f "$helper" ]] || continue
			$SUDO_CMD install -Dm755 "$helper" "/usr/local/sbin/$(basename "$helper")"
		done
	fi

	if [[ -f "$udev_rule" ]]; then
		msg "Syncing NVIDIA no-seat udev rule"
		$SUDO_CMD install -Dm644 "$udev_rule" /etc/udev/rules.d/90-nvidia-no-seat.rules
		$SUDO_CMD udevadm control --reload-rules || true
		$SUDO_CMD udevadm trigger --subsystem-match=drm --action=change || true
	fi
}

install_looking_glass_config() {
	local tmpfiles_conf="$INSTALL_DIR/looking-glass/tmpfiles/looking-glass.conf"

	if [[ -f "$tmpfiles_conf" ]]; then
		msg "Syncing Looking Glass shared-memory config"
		$SUDO_CMD install -Dm644 "$tmpfiles_conf" /etc/tmpfiles.d/looking-glass.conf
		$SUDO_CMD systemd-tmpfiles --create /etc/tmpfiles.d/looking-glass.conf || true
	fi
}

ensure_ufw_rule() {
	local match="$1"
	shift

	if ! command -v ufw >/dev/null 2>&1; then
		warn "Skipping UFW rule; ufw is not installed"
		return
	fi

	if $SUDO_CMD ufw status | grep -Fq "$match"; then
		msg "UFW rule already present: $match"
		return
	fi

	$SUDO_CMD ufw "$@"
}

install_vm_network_config() {
	if command -v virsh >/dev/null 2>&1 && virsh -c qemu:///system net-info default >/dev/null 2>&1; then
		msg "Ensuring libvirt DHCP reservation for win10-rtx3050"
		virsh -c qemu:///system net-update default add ip-dhcp-host \
			'<host mac="52:54:00:1a:cd:bd" name="win10-rtx3050" ip="192.168.122.50"/>' \
			--live --config >/dev/null 2>&1 || true
	fi

	msg "Ensuring UFW allows libvirt DNS/DHCP on virbr0"
	ensure_ufw_rule "192.168.122.1 53/udp on virbr0" allow in on virbr0 from 192.168.122.0/24 to 192.168.122.1 proto udp port 53
	ensure_ufw_rule "192.168.122.1 53/tcp on virbr0" allow in on virbr0 from 192.168.122.0/24 to 192.168.122.1 proto tcp port 53
	ensure_ufw_rule "67/udp on virbr0" allow in on virbr0 proto udp to any port 67
}

print_post_upgrade_notes() {
	cat <<EOF

Done. Dotfiles have been synced and symlinks updated.

Next steps:
	- Reload your shell configuration if needed (e.g., 'source ~/.config/fish/config.fish')
	- Restart relevant applications to pick up config changes
	- If you have significant config customizations, check the .bak files

EOF
}

main() {
	require_arch
	check_sudo
	print_banner
	update_symlinks
	apply_desktop_theme
	install_ly_config
	install_nm_iwd_config
	install_gpu_switch_config
	install_looking_glass_config
	install_vm_network_config
	print_post_upgrade_notes
}

main "$@"

#!/usr/bin/env bash
# Auto installer for dots-niri on a fresh Arch Linux system
# - Sets up pacman tweaks and Chaotic-AUR
# - Installs packages from pkg.txt and pkg-aur.txt
# - Installs paru (AUR helper) if missing
# - Symlinks configs from this repo into $HOME
# - Enables a few safe services

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
USER_NAME=${SUDO_USER:-${USER}}
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)

PACMAN=${PACMAN:-pacman}
SUDO_CMD=""

msg() { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m==>\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m==>\033[0m %s\n" "$*" 1>&2; }
die() { err "$*"; exit 1; }

require_arch() {
	[[ -f /etc/arch-release ]] || die "This script is intended for Arch Linux."
}

need_sudo() {
	if [[ $EUID -ne 0 ]]; then
		command -v sudo >/dev/null 2>&1 || die "sudo is required. Please install and re-run."
		SUDO_CMD="sudo"
	else
		SUDO_CMD=""
	fi
}

enable_pacman_tweaks() {
	msg "Tweaking pacman: Color, ILoveCandy, ParallelDownloads"
	local conf=/etc/pacman.conf
	$SUDO_CMD sed -i 's/^#Color/Color/; s/^#VerbosePkgLists/VerbosePkgLists/;' "$conf"
	# Enable ParallelDownloads (set to 10)
	if grep -qE '^#?ParallelDownloads' "$conf"; then
		$SUDO_CMD sed -i 's/^#\?ParallelDownloads.*/ParallelDownloads = 10/' "$conf"
	else
		$SUDO_CMD sed -i '/^\[options\]/a ParallelDownloads = 10' "$conf"
	fi
	# Fun candies
	if ! grep -q '^ILoveCandy' "$conf"; then
		$SUDO_CMD sed -i '/^\[options\]/a ILoveCandy' "$conf" || true
	fi
}

refresh_keys_and_system() {
	msg "Refreshing keyrings and updating system"
	$SUDO_CMD $PACMAN -Sy --noconfirm archlinux-keyring || true
	$SUDO_CMD $PACMAN -Syu --noconfirm
}

setup_prereqs() {
	msg "Installing prerequisites (base-devel, git, curl, wget)"
	$SUDO_CMD $PACMAN -S --needed --noconfirm base-devel git curl wget tar which unzip jq rsync
}

setup_chaotic_aur() {
	# Adds Chaotic-AUR repo if missing, then refreshes databases
	if grep -q "^\[chaotic-aur\]" /etc/pacman.conf; then
		msg "Chaotic-AUR already configured"
		return
	fi
	msg "Configuring Chaotic-AUR repository"
	# Import and trust key
	$SUDO_CMD pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com || true
	$SUDO_CMD pacman-key --lsign-key 3056513887B78AEB || true
	# Install keyring and mirrorlist packages
	local tmp
	tmp=$(mktemp -d)
	pushd "$tmp" >/dev/null
	wget -q --show-progress https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst
	wget -q --show-progress https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst
	$SUDO_CMD pacman -U --noconfirm ./chaotic-keyring.pkg.tar.zst ./chaotic-mirrorlist.pkg.tar.zst
	popd >/dev/null
	rm -rf "$tmp"
	# Append repo to pacman.conf
	$SUDO_CMD bash -c 'cat >>/etc/pacman.conf <<"EOF"

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF'
	$SUDO_CMD $PACMAN -Sy
}

install_official_packages() {
	local list_file="$SCRIPT_DIR/pkg.txt"
	[[ -f "$list_file" ]] || { warn "Missing pkg.txt, skipping official package install"; return; }
	msg "Installing official/chaotic packages from pkg.txt"
	# Take only the first column per line to avoid stray tokens (e.g., "niri-git 2")
	mapfile -t pkgs < <(awk '{print $1}' "$list_file" | sed -e 's/#.*//' -e '/^\s*$/d')
	if ((${#pkgs[@]})); then
		$SUDO_CMD $PACMAN -S --needed --noconfirm "${pkgs[@]}"
	else
		warn "No packages found in pkg.txt after filtering"
	fi
}

ensure_paru() {
	if command -v paru >/dev/null 2>&1; then
		msg "paru already installed"
		return
	fi
	msg "Installing paru (prefer via Chaotic-AUR, else build from AUR)"
	if $SUDO_CMD $PACMAN -S --needed --noconfirm paru; then
		return
	fi
	# Build from AUR
	local build_dir="/tmp/paru-build"
	rm -rf "$build_dir"
	git clone --depth=1 https://aur.archlinux.org/paru.git "$build_dir"
	pushd "$build_dir" >/dev/null
	makepkg -si --noconfirm
	popd >/dev/null
	rm -rf "$build_dir"
}

install_aur_packages() {
	local list_file="$SCRIPT_DIR/pkg-aur.txt"
	[[ -f "$list_file" ]] || { warn "Missing pkg-aur.txt, skipping AUR package install"; return; }
	msg "Installing AUR packages from pkg-aur.txt (using paru)"
	mapfile -t pkgs < <(awk '{print $1}' "$list_file" | sed -e 's/#.*//' -e '/^\s*$/d')
	if ((${#pkgs[@]})); then
		paru -S --needed --noconfirm "${pkgs[@]}"
	else
		warn "No AUR packages found in pkg-aur.txt after filtering"
	fi
}

link_dotfiles() {
	msg "Linking dotfiles into $USER_HOME"
	mkdir -p "$USER_HOME/.config" "$USER_HOME/.local/share" "$USER_HOME/bin"

	# Link each subdir from repo .config into ~/.config (back up existing)
	if [[ -d "$SCRIPT_DIR/.config" ]]; then
		for d in "$SCRIPT_DIR/.config"/*; do
			[[ -e "$d" ]] || continue
			local name
			name=$(basename "$d")
			local target="$USER_HOME/.config/$name"
			if [[ -L "$target" || -d "$target" || -f "$target" ]]; then
				if [[ -L "$target" && "$(readlink -f "$target")" == "$(readlink -f "$d")" ]]; then
					continue
				fi
				warn "Backing up existing $target to ${target}.bak"
				mv -f "$target" "${target}.bak" || true
			fi
			ln -s "$d" "$target"
		done
	fi

	# Link each subdir/file from repo .local into ~/.local
	if [[ -d "$SCRIPT_DIR/.local" ]]; then
		rsync -a --info=NAME --exclude="share/icons" --exclude="share/themes" \
			"$SCRIPT_DIR/.local/" "$USER_HOME/.local/"
	fi

	# Copy wallpapers assets, if any
	if [[ -d "$SCRIPT_DIR/assets/wal" ]]; then
		mkdir -p "$USER_HOME/.local/share/wallpapers"
		rsync -a --info=NAME "$SCRIPT_DIR/assets/wal/" "$USER_HOME/.local/share/wallpapers/"
	fi

	# Ensure correct ownership if run with sudo
	if [[ -n "$SUDO_CMD" ]]; then
		$SUDO_CMD chown -R "$USER_NAME":"$USER_NAME" "$USER_HOME/.config" "$USER_HOME/.local" "$USER_HOME/bin"
	fi
}

enable_services() {
	msg "Enabling relevant system services when available"
	# system services
	for svc in ly power-profiles-daemon auto-cpufreq; do
		if systemctl list-unit-files | grep -q "^${svc}\.service"; then
			$SUDO_CMD systemctl enable "$svc" || true
		fi
	done
	# user services (best-effort)
	if command -v systemctl >/dev/null 2>&1; then
		loginctl enable-linger "$USER_NAME" || true
		su - "$USER_NAME" -c 'systemctl --user daemon-reload || true'
		for usvc in mpd swayidle swaync; do
			su - "$USER_NAME" -c "systemctl --user enable --now ${usvc}.service" || true
		done
	fi
}

refresh_font_cache() {
	if command -v fc-cache >/dev/null 2>&1; then
		msg "Refreshing font cache"
		fc-cache -rfv || true
	fi
}

print_post_install_notes() {
	cat <<EOF

Done. Next steps (optional):
	- Reboot to switch to linux-zen kernel and ensure services start.
	- Log in with the 'ly' display manager and choose your Wayland session (niri).
	- Consider changing your shell to fish: chsh -s "/usr/bin/fish" "$USER_NAME"
	- For wallust-based theming, pick a wallpaper and run: wallust run /path/to/wallpaper

EOF
}

main() {
	require_arch
	need_sudo
	enable_pacman_tweaks
	refresh_keys_and_system
	setup_prereqs
	setup_chaotic_aur
	ensure_paru
	# Use paru for a unified install of both official and AUR packages
	if [[ -f "$SCRIPT_DIR/pkg.txt" || -f "$SCRIPT_DIR/pkg-aur.txt" ]]; then
		msg "Installing packages from pkg.txt and pkg-aur.txt via paru"
		mapfile -t pkgs < <( { [[ -f "$SCRIPT_DIR/pkg.txt" ]] && awk '{print $1}' "$SCRIPT_DIR/pkg.txt"; [[ -f "$SCRIPT_DIR/pkg-aur.txt" ]] && awk '{print $1}' "$SCRIPT_DIR/pkg-aur.txt"; } \
			| sed -e 's/#.*//' -e '/^\s*$/d' | sort -u )
		if ((${#pkgs[@]})); then
			paru -S --needed --noconfirm "${pkgs[@]}"
		else
			warn "No packages found after parsing lists"
		fi
	else
		warn "No package lists found; skipping package installation"
	fi
	link_dotfiles
	enable_services
	refresh_font_cache
	print_post_install_notes
}

main "$@"


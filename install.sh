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

# Helper: run a command explicitly as the invoking (non-root) user when the script
# itself is executing with elevated privileges (via sudo). This is vital for
# AUR builds (makepkg/paru) which must NOT be executed as root.
run_as_invoking_user() {
	if [[ -n ${SUDO_USER:-} && $EUID -eq 0 ]]; then
		# Preserve a minimal environment (HOME + USER + PATH). Paru/makepkg rely on HOME.
		HOME="$USER_HOME" sudo -u "$SUDO_USER" --preserve-env=HOME,PATH USER="$SUDO_USER" "$@"
	else
		"$@"
	fi
}

PACMAN=${PACMAN:-pacman}
SUDO_CMD=""

msg() { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m==>\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m==>\033[0m %s\n" "$*" 1>&2; }
die() { err "$*"; exit 1; }

print_banner() {
cat <<'EOF'
------------------------------------------------------------------
 |                                                              |
 |                                                              |
 |	         -- jR4dh3y dotfiles installer --               |
 |                                                              |
 |                                                              |
------------------------------------------------------------------ 
EOF
}

require_arch() {
	[[ -f /etc/arch-release ]] || die "This script is intended for Arch Linux."
}

need_sudo() {
	if [[ $EUID -ne 0 ]]; then
		command -v sudo >/dev/null 2>&1 || die "sudo is required. Please install and re-run."
		SUDO_CMD="sudo"
	else
		SUDO_CMD=""
		# If the script is run directly as root (not via sudo), we cannot safely
		# build AUR packages. Force the user to re-run under their normal account.
		if [[ -z ${SUDO_USER:-} ]]; then
			die "Do not run this script directly as root. Run it as your normal user with sudo privileges (e.g. 'bash install.sh' or 'sudo -E -u <user> bash install.sh')."
		fi
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

# Install paru if no AUR helper is present (or user prefers paru). Adapted to run builds as invoking user.
install_paru() {
	if command -v paru >/dev/null 2>&1; then
		msg "paru already installed"
		return
	fi
	msg "Installing paru (AUR helper)"
	# Ensure prerequisites (base-devel, git, rustup) present
	$SUDO_CMD $PACMAN -S --needed --noconfirm base-devel git rustup || true
	# Initialize rustup (as user) and set nightly default (only if rustup just installed)
	if command -v rustup >/dev/null 2>&1; then
		run_as_invoking_user rustup toolchain install nightly >/dev/null 2>&1 || true
		run_as_invoking_user rustup default nightly >/dev/null 2>&1 || true
	fi
	local build_dir="/tmp/paru-build"
	rm -rf "$build_dir"
	run_as_invoking_user git clone https://aur.archlinux.org/paru.git "$build_dir"
	pushd "$build_dir" >/dev/null
	run_as_invoking_user makepkg -si --noconfirm
	popd >/dev/null
	rm -rf "$build_dir"
}

find_aur_helper() {
	if command -v paru >/dev/null 2>&1; then
		echo "paru"
	elif command -v yay >/dev/null 2>&1; then
		echo "yay"
	else
		install_paru
		echo "paru"
	fi
}

# Ensure a single package (any repo/AUR) using the detected helper.
ensure_pkg() {
	local pkg=$1
	if ! $AURHELPER -Q "$pkg" >/dev/null 2>&1; then
		msg "Installing $pkg"
		run_as_invoking_user $AURHELPER -S --noconfirm "$pkg"
	else
		msg "$pkg already installed"
	fi
}

# Consolidated package gathering and installation
gather_package_list() {
	local files=()
	[[ -f "$SCRIPT_DIR/pkg.txt" ]] && files+=("$SCRIPT_DIR/pkg.txt")
	((${#files[@]})) || return 0
	awk '{print $1}' "${files[@]}" \
		| sed -e 's/#.*//' -e '/^\s*$/d' \
		| sort -u
}

install_all_packages() {
	mapfile -t pkgs < <(gather_package_list)
	if ((${#pkgs[@]})); then
		msg "Installing ${#pkgs[@]} packages via $AURHELPER"
		# shellcheck disable=SC2086
		run_as_invoking_user $AURHELPER -S --needed --noconfirm --skipreview ${pkgs[*]}
	else
		warn "No packages found to install"
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
	for svc in ly power-profiles-daemon NetworkManager ; do
		if systemctl list-unit-files | grep -q "^${svc}\.service"; then
			$SUDO_CMD systemctl enable "$svc" || true
		fi
	done
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
	print_banner
	enable_pacman_tweaks
	refresh_keys_and_system
	setup_prereqs
	setup_chaotic_aur
	# Detect/install an AUR helper (paru preferred, fallback to yay if present)
	AURHELPER=$(find_aur_helper)
	refresh_font_cache
	enable_services
	install_all_packages
	link_dotfiles
	print_post_install_notes
	wallpaper ~/.local/share/wallpapers/lucy.jpeg
}

main "$@"


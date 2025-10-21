#!/usr/bin/env bash
# Upgrade dotfiles - reruns symlink commands to update after changes
# This script updates all symlinks and file copies without reinstalling packages

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
USER_NAME=${SUDO_USER:-${USER}}
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)

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
 |	    -- jR4dh3y dotfiles upgrade/sync --                 |
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
	mkdir -p "$USER_HOME/.config" "$USER_HOME/.local/share" "$USER_HOME/bin"

	# Update each subdir from repo .config into ~/.config
	if [[ -d "$SCRIPT_DIR/.config" ]]; then
		for d in "$SCRIPT_DIR/.config"/*; do
			[[ -e "$d" ]] || continue
			local name
			name=$(basename "$d")
			local target="$USER_HOME/.config/$name"
			
			# If symlink already points to the right place, skip
			if [[ -L "$target" && "$(readlink -f "$target")" == "$(readlink -f "$d")" ]]; then
				msg "Already linked: $name"
				continue
			fi
			
			# Backup existing if it's not already the correct symlink
			if [[ -L "$target" || -d "$target" || -f "$target" ]]; then
				warn "Backing up existing $target to ${target}.bak"
				mv -f "$target" "${target}.bak" || true
			fi
			
			msg "Linking $name"
			ln -s "$d" "$target"
		done
	fi

	# Update each subdir/file from repo .local into ~/.local
	if [[ -d "$SCRIPT_DIR/.local" ]]; then
		msg "Syncing .local files"
		rsync -a --info=NAME --exclude="share/icons" --exclude="share/themes" \
			"$SCRIPT_DIR/.local/" "$USER_HOME/.local/"
	fi

	# Update wallpapers assets, if any
	if [[ -d "$SCRIPT_DIR/assets/wal" ]]; then
		msg "Syncing wallpapers"
		mkdir -p "$USER_HOME/.local/share/wallpapers"
		rsync -a --info=NAME "$SCRIPT_DIR/assets/wal/" "$USER_HOME/.local/share/wallpapers/"
	fi

	# Ensure correct ownership if run with sudo
	if [[ -n "$SUDO_CMD" ]]; then
		msg "Fixing ownership"
		$SUDO_CMD chown -R "$USER_NAME":"$USER_NAME" "$USER_HOME/.config" "$USER_HOME/.local" "$USER_HOME/bin"
	fi
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
	print_post_upgrade_notes
}

main "$@"

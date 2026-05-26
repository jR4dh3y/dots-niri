#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=$(cd -- "$INSTALL_DIR/.." && pwd)
USER_NAME=${SUDO_USER:-${USER}}
USER_HOME=${WAYBAR_TASKBAR_USER_HOME:-$(getent passwd "$USER_NAME" | cut -d: -f6)}

SRC_DIR="$REPO_DIR/tools/niri-taskbar-focused"
DEST_DIR="$USER_HOME/.config/waybar"
DEST="$DEST_DIR/libniri_taskbar-focused.so"
BUILT="$SRC_DIR/target/release/libniri_taskbar.so"

msg() { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m==>\033[0m %s\n" "$*" >&2; }
die() { printf "\033[1;31m==>\033[0m %s\n" "$*" >&2; exit 1; }

run_as_invoking_user() {
	if [[ -n ${SUDO_USER:-} && $EUID -eq 0 ]]; then
		HOME="$USER_HOME" sudo -u "$SUDO_USER" --preserve-env=HOME,PATH USER="$SUDO_USER" "$@"
	else
		"$@"
	fi
}

[[ -d "$SRC_DIR" ]] || die "Waybar taskbar source not found: $SRC_DIR"

if ! command -v cargo >/dev/null 2>&1; then
	die "cargo is required to build the Waybar Niri taskbar module. Install rust or rustup and rerun this script."
fi

msg "Building Waybar Niri taskbar module"
run_as_invoking_user cargo build --release --manifest-path "$SRC_DIR/Cargo.toml"

[[ -f "$BUILT" ]] || die "Build succeeded but module was not found: $BUILT"

msg "Installing $(basename "$DEST")"
mkdir -p "$DEST_DIR"
install -m 755 "$BUILT" "$DEST"

if [[ -n ${SUDO_USER:-} && $EUID -eq 0 ]]; then
	chown "$USER_NAME":"$USER_NAME" "$DEST"
fi

msg "Waybar taskbar module installed at $DEST"

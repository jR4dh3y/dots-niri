#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

REPO_URL=${REPO_URL:-https://github.com/jr4dh3y/dots-niri.git}
INSTALL_ROOT=${INSTALL_ROOT:-${HOME}/code}
CLONE_DIR=${CLONE_DIR:-${INSTALL_ROOT}/dots-niri}
BRANCH=${BRANCH:-main}
INSTALL_ARGS=()

msg() { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m==>\033[0m %s\n" "$*"; }
die() { printf "\033[1;31m==>\033[0m %s\n" "$*" >&2; exit 1; }

usage() {
	cat <<'EOF'
Usage: oneline.sh [install.sh options]

Bootstrap the dots-niri installer by cloning (or updating) the repo in a
persistent location, then running install/install.sh.

Environment overrides:
  REPO_URL      Git repository to clone
  INSTALL_ROOT  Parent directory for the clone (default: ~/code)
  CLONE_DIR     Full clone path (default: ~/code/dots-niri)
  BRANCH        Branch to clone/update (default: main)

Examples:
  curl -fsSL https://jr4.in/niri | bash
  wget -qO- https://jr4.in/niri | bash
  curl -fsSL https://jr4.in/niri | bash -s -- --sync-only
EOF
}

ensure_cmd() {
	command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

install_prereqs() {
	local missing=()
	command -v git >/dev/null 2>&1 || missing+=(git)

	if ((${#missing[@]} == 0)); then
		return 0
	fi

	msg "Installing missing prerequisites: ${missing[*]}"
	if [[ $EUID -eq 0 ]]; then
		pacman -Sy --needed --noconfirm "${missing[@]}"
	else
		if command -v sudo >/dev/null 2>&1; then
			sudo pacman -Sy --needed --noconfirm "${missing[@]}"
		else
			die "Missing ${missing[*]} is not available. Install them manually: pacman -S ${missing[*]}"
		fi
	fi
}

parse_args() {
	while (($#)); do
		case $1 in
			--)
				shift
				while (($#)); do
					INSTALL_ARGS+=("$1")
					shift
				done
				break
				;;
			-h|--help)
				usage
				exit 0
				;;
			*)
				INSTALL_ARGS+=("$1")
				;;
		esac
		shift
	done
}

clone_or_update_repo() {
	ensure_cmd git
	mkdir -p "$INSTALL_ROOT"

	if [[ -d "$CLONE_DIR/.git" ]]; then
		msg "Using existing checkout at $CLONE_DIR"
		local origin_url
		origin_url=$(git -C "$CLONE_DIR" remote get-url origin 2>/dev/null || printf '')
		if [[ -n $origin_url && $origin_url != "$REPO_URL" ]]; then
			warn "Existing repo origin is '$origin_url' (expected '$REPO_URL')."
			warn "Skipping automatic update and continuing with the existing checkout."
			return 0
		fi

		if [[ -n $(git -C "$CLONE_DIR" status --porcelain 2>/dev/null) ]]; then
			warn "Repository has local changes; skipping automatic pull."
			return 0
		fi

		msg "Updating repository"
		git -C "$CLONE_DIR" fetch --tags origin "$BRANCH"
		git -C "$CLONE_DIR" checkout "$BRANCH"
		git -C "$CLONE_DIR" pull --ff-only origin "$BRANCH"
		git -C "$CLONE_DIR" submodule update --init --recursive
		return 0
	fi

	if [[ -e "$CLONE_DIR" ]]; then
		die "Path exists but is not a git checkout: $CLONE_DIR"
	fi

	msg "Cloning repository into $CLONE_DIR"
	git clone --branch "$BRANCH" --recurse-submodules "$REPO_URL" "$CLONE_DIR"
}

run_installer() {
	local install_script="$CLONE_DIR/install/install.sh"
	[[ -f "$install_script" ]] || die "Installer not found at $install_script"

	msg "Starting installer from $CLONE_DIR"
	if [[ -r /dev/tty ]]; then
		bash "$install_script" "${INSTALL_ARGS[@]}" < /dev/tty
	else
		bash "$install_script" "${INSTALL_ARGS[@]}"
	fi
}

main() {
	parse_args "$@"
	install_prereqs
	clone_or_update_repo
	run_installer
}

main "$@"
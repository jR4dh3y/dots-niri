#!/usr/bin/env bash
# Interactive installer for dots-niri on Arch Linux.

set -euo pipefail
IFS=$'\n\t'

INSTALL_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=$(cd -- "$INSTALL_DIR/.." && pwd)
USER_NAME=${SUDO_USER:-${USER}}
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)

run_as_invoking_user() {
	if [[ -n ${SUDO_USER:-} && $EUID -eq 0 ]]; then
		HOME="$USER_HOME" SUDO_ASKPASS="${SUDO_ASKPASS:-}" sudo -u "$SUDO_USER" --preserve-env=HOME,PATH,SUDO_ASKPASS USER="$SUDO_USER" "$@"
	else
		"$@"
	fi
}

PACMAN=${PACMAN:-pacman}
SUDO_CMD=""
SUDO_KEEPALIVE_PID=""
INTERACTIVE=1
TUI_ENABLED=0
TUI_CURSOR_HIDDEN=0

CLR_RESET=$'\033[0m'
CLR_DIM=$'\033[2m'
CLR_MUTED=$'\033[38;5;245m'
CLR_ACCENT=$'\033[38;5;111m'
CLR_ACCENT_BOLD=$'\033[1;38;5;111m'
CLR_SUCCESS=$'\033[38;5;114m'
CLR_WARNING=$'\033[38;5;221m'
CLR_SELECTION=$'\033[48;5;24;38;5;255m'

RUN_PACMAN_TWEAKS=1
RUN_SYSTEM_UPDATE=1
RUN_PREREQS=1
RUN_CHAOTIC_AUR=1
RUN_PACKAGES=1
RUN_DOTFILES=1
RUN_LY_CONFIG=1
RUN_NM_IWD_CONFIG=1
RUN_SERVICES=1
RUN_SET_WALLPAPER=1
WEATHER_LOCATION=""
WEATHER_DEFAULT_LOCATION="London"

msg() { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m==>\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m==>\033[0m %s\n" "$*" 1>&2; }
die() { err "$*"; exit 1; }

print_banner() {
cat <<'EOF'
------------------------------------------------------------------
 |                                                              |
 |                                                              |
 |             -- jR4dh3y dotfiles installer --                 |
 |                                                              |
 |                                                              |
------------------------------------------------------------------
EOF
}

cleanup_terminal() {
	if [[ -n ${SUDO_KEEPALIVE_PID:-} ]] && kill -0 "$SUDO_KEEPALIVE_PID" 2>/dev/null; then
		kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
		wait "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
	fi
	if [[ $TUI_CURSOR_HIDDEN -eq 1 ]]; then
		tput cnorm >/dev/null 2>&1 || true
		TUI_CURSOR_HIDDEN=0
	fi
	printf '\033[0m' >/dev/tty 2>/dev/null || true
}

enable_tui_if_possible() {
	if [[ $INTERACTIVE -eq 1 && -t 0 && -t 1 ]] && command -v tput >/dev/null 2>&1; then
		TUI_ENABLED=1
	fi
}

tui_begin() {
	[[ $TUI_ENABLED -eq 1 ]] || return 0
	if [[ $TUI_CURSOR_HIDDEN -eq 0 ]]; then
		tput civis >/dev/null 2>&1 || true
		TUI_CURSOR_HIDDEN=1
	fi
}

tui_draw_header() {
	clear
	print_banner
	if [[ -n ${1:-} || -n ${2:-} ]]; then
		printf '\n'
		[[ -n ${1:-} ]] && printf ' %b%s%b\n' "$CLR_ACCENT_BOLD" "$1" "$CLR_RESET"
		[[ -n ${2:-} ]] && printf ' %b%s%b\n' "$CLR_MUTED" "$2" "$CLR_RESET"
		printf '\n'
	else
		printf '\n'
	fi
}

tui_draw_footer() {
	local footer_text=$1
	local lines footer_row
	[[ $TUI_ENABLED -eq 1 ]] || return 0

	lines=$(tput lines 2>/dev/null || printf '24')
	footer_row=$(( lines - 2 ))
	(( footer_row < 1 )) && footer_row=1
	printf '\033[%d;1H\033[2K' "$footer_row"
	printf ' %b%s%b' "$CLR_WARNING" "$footer_text" "$CLR_RESET"
	printf '\033[%d;1H' "$footer_row"
}

tui_read_key() {
	local key rest final
	IFS= read -rsn1 key || return 1
	case $key in
		$'\x1b')
			IFS= read -rsn1 -t 0.05 rest || {
				printf 'escape'
				return 0
			}
			if [[ $rest == "[" ]]; then
				IFS= read -rsn1 -t 0.05 final || final=''
				case $final in
					A) printf 'up' ;;
					B) printf 'down' ;;
					C) printf 'right' ;;
					D) printf 'left' ;;
					'') printf 'escape' ;;
					*) printf 'escape' ;;
				esac
			else
				printf 'escape'
			fi
			;;
		'') printf 'enter' ;;
		$' ') printf 'space' ;;
		$'\x7f'|$'\b') printf 'backspace' ;;
		$'\n'|$'\r') printf 'enter' ;;
		[kK]) printf 'up' ;;
		[jJ]) printf 'down' ;;
		[hH]) printf 'left' ;;
		[lL]) printf 'right' ;;
		[qQ]) printf 'quit' ;;
		*) printf '%s' "$key" ;;
	esac
}

tui_choose_from_menu() {
	local title=$1
	local prompt=$2
	local default_index=$3
	local -n options_ref=$4
	local selected=$default_index
	local i key

	tui_begin
	while true; do
		tui_draw_header "$title" "$prompt"
		printf '\n'
		for i in "${!options_ref[@]}"; do
			if [[ $i -eq $selected ]]; then
				printf '   %b› %s%b\n' "$CLR_SELECTION" "${options_ref[$i]}" "$CLR_RESET"
			else
				printf '     %b%s%b\n' "$CLR_ACCENT" "${options_ref[$i]}" "$CLR_RESET"
			fi
		done

		tui_draw_footer 'Use ↑/↓ (or j/k) to move, Enter to select, q to cancel.'
		key=$(tui_read_key) || return 1
		case $key in
			up)
				selected=$(( (selected - 1 + ${#options_ref[@]}) % ${#options_ref[@]} ))
				;;
			down)
				selected=$(( (selected + 1) % ${#options_ref[@]} ))
				;;
			enter)
				REPLY=$selected
				return 0
				;;
			quit|escape)
				return 1
				;;
		esac
		done
}

tui_toggle_checklist() {
	local title=$1
	local prompt=$2
	local -n labels_ref=$3
	local -n states_ref=$4
	local selected=0
	local i key mark

	tui_begin
	while true; do
		tui_draw_header "$title" "$prompt"
		printf '\n'
		for i in "${!labels_ref[@]}"; do
			if [[ ${states_ref[$i]} -eq 1 ]]; then
				mark="${CLR_SUCCESS}[x]${CLR_RESET}"
			else
				mark="${CLR_MUTED}[ ]${CLR_RESET}"
			fi
			if [[ $i -eq $selected ]]; then
				printf '   %b%s %s%b\n' "$CLR_SELECTION" "$mark" "${labels_ref[$i]}" "$CLR_RESET"
			else
				printf '    %s %b%s%b\n' "$mark" "$CLR_ACCENT" "${labels_ref[$i]}" "$CLR_RESET"
			fi
		done

		tui_draw_footer 'Use ↑/↓ (or j/k) to move, Space to toggle, Enter to continue, Backspace/b to go back, q to cancel.'
		key=$(tui_read_key) || return 1
		case $key in
			up)
				selected=$(( (selected - 1 + ${#labels_ref[@]}) % ${#labels_ref[@]} ))
				;;
			down)
				selected=$(( (selected + 1) % ${#labels_ref[@]} ))
				;;
			space)
				if [[ ${states_ref[$selected]} -eq 1 ]]; then
					states_ref[$selected]=0
				else
					states_ref[$selected]=1
				fi
				;;
			enter)
				return 0
				;;
			backspace|[bB])
				return 2
				;;
			quit|escape)
				return 1
				;;
		esac
		done
}

tui_confirm() {
	local title=$1
	local prompt=$2
	local default_yes=${3:-1}
	local options=("Continue" "Go back" "Cancel install")
	local default_index=0

	if [[ $default_yes -eq 0 ]]; then
		default_index=1
	fi

	if ! tui_choose_from_menu "$title" "$prompt" "$default_index" options; then
		return 1
	fi

	case $REPLY in
		0) return 0 ;;
		1) return 2 ;;
		*) return 1 ;;
	esac
}

bool_word() {
	if [[ ${1:-0} -eq 1 ]]; then
		printf 'yes'
	else
		printf 'no'
	fi
}

trim_whitespace() {
	printf '%s' "$1" | sed 's/^ *//; s/ *$//'
}

weather_location_file() {
	printf '%s/.local/state/waybar/weather-location\n' "$USER_HOME"
}

load_saved_weather_location() {
	local location_file location
	location_file=$(weather_location_file)
	if [[ -f "$location_file" ]]; then
		location=$(sed -n '1p' "$location_file" | tr -d '\r')
		location=$(trim_whitespace "$location")
		if [[ -n $location ]]; then
			printf '%s\n' "$location"
			return
		fi
	fi
	printf '%s\n' "$WEATHER_DEFAULT_LOCATION"
}

tui_prompt_input() {
	local title=$1
	local prompt=$2
	local default_value=${3:-}
	local reply

	tui_begin
	tui_draw_header "$title" "$prompt"
	printf ' %bEnter a city, state, full address, or pincode.%b\n\n' "$CLR_MUTED" "$CLR_RESET"
	printf ' Current value: %b%s%b\n\n' "$CLR_ACCENT" "$default_value" "$CLR_RESET"
	printf ' New value (press Enter to keep current): '
	IFS= read -r reply || return 1
	REPLY=${reply:-$default_value}
	return 0
}

prompt_yes_no() {
	local question=${1:?question is required}
	local default=${2:-Y}
	local options reply

	if [[ $TUI_ENABLED -eq 1 ]]; then
		if [[ $default =~ ^[Yy]$ ]]; then
			tui_confirm "Confirm" "$question" 1
		else
			tui_confirm "Confirm" "$question" 0
		fi
		case $? in
			0) return 0 ;;
			2) return 1 ;;
			*) die "Installation cancelled by user." ;;
		esac
	fi

	if [[ $INTERACTIVE -eq 0 || ! -t 0 ]]; then
		[[ $default =~ ^[Yy]$ ]]
		return
	fi

	if [[ $default =~ ^[Yy]$ ]]; then
		options="Y/n"
	else
		options="y/N"
	fi

	while true; do
		read -r -p "$question [$options]: " reply
		reply=${reply:-$default}
		case $reply in
			[Yy]) return 0 ;;
			[Nn]) return 1 ;;
			*) warn "Please answer y or n." ;;
		esac
	done
}

prompt_weather_location() {
	local current_location new_location
	[[ $RUN_DOTFILES -eq 1 ]] || return 0

	current_location=$(load_saved_weather_location)

	if [[ $TUI_ENABLED -eq 1 ]]; then
		if ! tui_prompt_input \
			"Weather widget setup" \
			"Choose the location used by the Waybar weather widget." \
			"$current_location"; then
			die "Installation cancelled by user."
		fi
		new_location=$REPLY
	elif [[ $INTERACTIVE -eq 1 && -t 0 ]]; then
		printf '\nWeather widget setup\n'
		printf '  You can enter a city, state, address, or pincode.\n'
		read -r -p "Weather location [$current_location]: " new_location || die "Installation cancelled by user."
		new_location=${new_location:-$current_location}
	else
		new_location=$current_location
	fi

	new_location=$(trim_whitespace "$new_location")
	WEATHER_LOCATION=${new_location:-$current_location}
}

show_install_summary() {
	cat <<EOF

Install plan
  - Pacman tweaks: $(bool_word "$RUN_PACMAN_TWEAKS")
  - System update: $(bool_word "$RUN_SYSTEM_UPDATE")
  - Prerequisites: $(bool_word "$RUN_PREREQS")
  - Chaotic-AUR: $(bool_word "$RUN_CHAOTIC_AUR")
  - Packages: $(bool_word "$RUN_PACKAGES")
  - Dotfiles sync: $(bool_word "$RUN_DOTFILES")
  - ly config sync: $(bool_word "$RUN_LY_CONFIG")
  - NetworkManager iwd config sync: $(bool_word "$RUN_NM_IWD_CONFIG")
  - Service enablement: $(bool_word "$RUN_SERVICES")
  - Apply default wallpaper: $(bool_word "$RUN_SET_WALLPAPER")

EOF
}

set_sync_only_plan() {
	RUN_PACMAN_TWEAKS=0
	RUN_SYSTEM_UPDATE=0
	RUN_PREREQS=0
	RUN_CHAOTIC_AUR=0
	RUN_PACKAGES=0
	RUN_DOTFILES=1
	RUN_LY_CONFIG=1
	RUN_NM_IWD_CONFIG=1
	RUN_SERVICES=0
	RUN_SET_WALLPAPER=0
}

set_packages_only_plan() {
	RUN_PACMAN_TWEAKS=1
	RUN_SYSTEM_UPDATE=1
	RUN_PREREQS=1
	RUN_CHAOTIC_AUR=1
	RUN_PACKAGES=1
	RUN_DOTFILES=0
	RUN_LY_CONFIG=1
	RUN_NM_IWD_CONFIG=1
	RUN_SERVICES=1
	RUN_SET_WALLPAPER=0
}

apply_plan_states() {
	local -n states_ref=$1
	RUN_PACMAN_TWEAKS=${states_ref[0]}
	RUN_SYSTEM_UPDATE=${states_ref[1]}
	RUN_PREREQS=${states_ref[2]}
	RUN_CHAOTIC_AUR=${states_ref[3]}
	RUN_PACKAGES=${states_ref[4]}
	RUN_DOTFILES=${states_ref[5]}
	RUN_LY_CONFIG=${states_ref[6]}
	RUN_NM_IWD_CONFIG=${states_ref[7]}
	RUN_SERVICES=${states_ref[8]}
	RUN_SET_WALLPAPER=${states_ref[9]}
}

configure_install_plan_tui() {
	local options=(
		"Full install      packages + dotfiles + ly + nm + services"
		"Custom install    choose every install step"
	)
	local labels=(
		"Apply pacman tweaks"
		"Refresh keys and update the system"
		"Install installer prerequisites"
		"Configure Chaotic-AUR"
		"Install packages from install/pkg*.txt"
		"Sync repo dotfiles into the home directory"
		"Install the tracked ly config into /etc/ly/config.ini"
		"Install NetworkManager iwd backend config into /etc/NetworkManager/conf.d"
		"Enable required services (ly, iwd, power-profiles-daemon)"
		"Apply the default wallpaper after sync"
	)
	local states=(1 1 1 1 1 1 1 1 1 1)
	local done=0
	local confirm_result

	while [[ $done -eq 0 ]]; do
		if ! tui_choose_from_menu \
			"" \
			"" \
			0 \
			options; then
			die "Installation cancelled by user."
		fi

		case $REPLY in
			0) ;;
			1)
				states=(1 1 1 1 1 1 1 1 1 0)
				if ! tui_toggle_checklist \
					"Custom install" \
					"Toggle the steps you want to run." \
					labels \
					states; then
					case $? in
						2) continue ;;
						*) die "Installation cancelled by user." ;;
					esac
				fi
				apply_plan_states states
				;;
		esac

		show_install_summary
		confirm_result=0
		if tui_confirm "Install summary" "Does this plan look good?" 1; then
			confirm_result=0
			else
				confirm_result=$?
			fi

		case $confirm_result in
			0) done=1 ;;
			2) continue ;;
			*) die "Installation cancelled by user." ;;
		esac
	done
	clear
}

configure_install_plan_prompt() {
	local choice

	clear
	print_banner
cat <<'EOF'
Select an install mode:
	1) Full install      (packages + dotfiles + ly + nm + services)
	2) Custom            (choose each step)
EOF

	while true; do
		read -r -p "Choice [1-2] (default: 1): " choice
		choice=${choice:-1}
		case $choice in
			1) break ;;
			2)
				RUN_PACMAN_TWEAKS=0; prompt_yes_no "Apply pacman tweaks?" Y && RUN_PACMAN_TWEAKS=1
				RUN_SYSTEM_UPDATE=0; prompt_yes_no "Refresh keys and update the system?" Y && RUN_SYSTEM_UPDATE=1
				RUN_PREREQS=0; prompt_yes_no "Install installer prerequisites?" Y && RUN_PREREQS=1
				RUN_CHAOTIC_AUR=0; prompt_yes_no "Configure Chaotic-AUR?" Y && RUN_CHAOTIC_AUR=1
				RUN_PACKAGES=0; prompt_yes_no "Install packages from install/pkg*.txt?" Y && RUN_PACKAGES=1
				RUN_DOTFILES=0; prompt_yes_no "Sync repo dotfiles into the home directory?" Y && RUN_DOTFILES=1
				RUN_LY_CONFIG=0; prompt_yes_no "Install the tracked ly config into /etc/ly/config.ini?" Y && RUN_LY_CONFIG=1
				RUN_NM_IWD_CONFIG=0; prompt_yes_no "Install NetworkManager iwd backend config into /etc/NetworkManager/conf.d?" Y && RUN_NM_IWD_CONFIG=1
				RUN_SERVICES=0; prompt_yes_no "Enable required services (ly, iwd, power-profiles-daemon)?" Y && RUN_SERVICES=1
				RUN_SET_WALLPAPER=0; prompt_yes_no "Apply the default wallpaper after sync?" N && RUN_SET_WALLPAPER=1
				break
				;;
			*) warn "Please choose 1 or 2." ;;
			esac
		done

	show_install_summary
	prompt_yes_no "Continue with this install plan?" Y || die "Installation cancelled by user."
}

configure_install_plan() {
	if [[ $INTERACTIVE -eq 0 || ! -t 0 || ! -t 1 ]]; then
		return
	fi

	if [[ $TUI_ENABLED -eq 1 ]]; then
		configure_install_plan_tui
	else
		configure_install_plan_prompt
	fi
}

parse_args() {
	while (($#)); do
		case $1 in
			-y|--yes|--non-interactive)
				INTERACTIVE=0
				;;
			--sync-only)
				INTERACTIVE=0
				set_sync_only_plan
				;;
			--packages-only)
				INTERACTIVE=0
				set_packages_only_plan
				;;
			-h|--help)
				cat <<'EOF'
Usage: install.sh [options]

Options:
  -y, --yes, --non-interactive  Run the full install without prompts
	    --sync-only               Sync dotfiles, ly config, and NM iwd config only
	    --packages-only           Install packages and enable services only
  -h, --help                    Show this help message
EOF
				exit 0
				;;
			*) die "Unknown argument: $1" ;;
			esac
		shift
	done
}

require_arch() {
	[[ -f /etc/arch-release ]] || die "This script is intended for Arch Linux."
}

need_sudo() {
	if [[ $EUID -ne 0 ]]; then
		command -v sudo >/dev/null 2>&1 || die "sudo is required. Please install and re-run."
		SUDO_CMD="sudo"

		# Ask for the password once up front. We pipe it to sudo -S -v to
		# prime the credential cache, then a background loop keeps the
		# timestamp alive so no further prompts appear during the install
		# (including those from makepkg -si).
		msg "Authenticating with sudo (you will be prompted for your password once)"
		local user_pass
		IFS= read -rsp "[sudo] password for $USER_NAME: " user_pass
		printf '\n'

		if ! printf '%s\n' "$user_pass" | sudo -S -v 2>/dev/null; then
			die "Incorrect password or failed to obtain sudo credentials."
		fi

		# Create a temporary askpass script so that any child process that
		# calls sudo (e.g. makepkg -si) can authenticate non-interactively.
		local pw_file askpass_helper
		pw_file=$(mktemp "${TMPDIR:-/tmp}/dots-niri-pw.XXXXXXXXXX")
		printf '%s\n' "$user_pass" > "$pw_file"
		chmod 600 "$pw_file"
		unset user_pass

		askpass_helper=$(mktemp "${TMPDIR:-/tmp}/dots-niri-askpass.XXXXXXXXXX")
		printf '#!/bin/sh\ncat "%s"\n' "$pw_file" > "$askpass_helper"
		chmod 700 "$askpass_helper"

		export SUDO_ASKPASS="$askpass_helper"

		# Create a sudo wrapper that always passes -A so child processes
		# (like makepkg -si calling sudo pacman -U) never prompt.
		local sudo_wrapper_dir
		sudo_wrapper_dir=$(mktemp -d "${TMPDIR:-/tmp}/dots-niri-sudo.XXXXXXXXXX")
		cat > "$sudo_wrapper_dir/sudo" <<WRAPPER
#!/bin/sh
exec /usr/bin/sudo -A "\$@"
WRAPPER
		chmod 755 "$sudo_wrapper_dir/sudo"
		export PATH="$sudo_wrapper_dir:$PATH"

		# Keep the sudo timestamp alive in the background as a fallback.
		(
			while kill -0 $$ 2>/dev/null; do
				/usr/bin/sudo -n -v 2>/dev/null
				sleep 50
			done
		) &
		SUDO_KEEPALIVE_PID=$!

		# Clean up the password files and wrapper on exit.
		# shellcheck disable=SC2064
		trap "rm -rf '$askpass_helper' '$pw_file' '$sudo_wrapper_dir'; cleanup_terminal" EXIT INT TERM
	else
		SUDO_CMD=""
		if [[ -z ${SUDO_USER:-} ]]; then
			die "Do not run this script directly as root. Run it as your normal user with sudo privileges."
		fi
	fi
}

enable_pacman_tweaks() {
	msg "Tweaking pacman: Color, ILoveCandy, ParallelDownloads"
	local conf=/etc/pacman.conf
	$SUDO_CMD sed -i 's/^#Color/Color/; s/^#VerbosePkgLists/VerbosePkgLists/;' "$conf"
	if grep -qE '^#?ParallelDownloads' "$conf"; then
		$SUDO_CMD sed -i 's/^#\?ParallelDownloads.*/ParallelDownloads = 10/' "$conf"
	else
		$SUDO_CMD sed -i '/^\[options\]/a ParallelDownloads = 10' "$conf"
	fi
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
	if grep -q "^\[chaotic-aur\]" /etc/pacman.conf; then
		msg "Chaotic-AUR already configured"
		return
	fi

	msg "Configuring Chaotic-AUR repository"
	$SUDO_CMD pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com || true
	$SUDO_CMD pacman-key --lsign-key 3056513887B78AEB || true

	local tmp
	tmp=$(mktemp -d)
	pushd "$tmp" >/dev/null
	wget -q --show-progress https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst
	wget -q --show-progress https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst
	$SUDO_CMD pacman -U --noconfirm ./chaotic-keyring.pkg.tar.zst ./chaotic-mirrorlist.pkg.tar.zst
	popd >/dev/null
	rm -rf "$tmp"

	$SUDO_CMD bash -c 'cat >>/etc/pacman.conf <<"EOF"

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF'
	$SUDO_CMD $PACMAN -Sy
}

install_paru() {
	if command -v paru >/dev/null 2>&1; then
		msg "paru already installed"
		return
	fi

	msg "Installing paru (AUR helper)"
	$SUDO_CMD $PACMAN -S --needed --noconfirm base-devel git rustup || true
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

	# Refresh the shell's command hash table so paru is found immediately
	hash -r
	if ! command -v paru >/dev/null 2>&1; then
		# makepkg installs to /usr/bin; ensure it is on PATH
		export PATH="/usr/bin:$PATH"
		hash -r
	fi
	command -v paru >/dev/null 2>&1 || die "paru installation succeeded but command is still not found in PATH."
}

find_aur_helper() {
	hash -r
	if command -v paru >/dev/null 2>&1; then
		echo "paru"
	elif command -v yay >/dev/null 2>&1; then
		echo "yay"
	else
		install_paru >&2
		echo "paru"
	fi
}

detect_cpu_vendor() {
	local vendor_id
	vendor_id=$(grep -m1 '^vendor_id' /proc/cpuinfo 2>/dev/null | awk '{print $3}')
	case $vendor_id in
		GenuineIntel) printf 'intel\n' ;;
		AuthenticAMD) printf 'amd\n' ;;
		*) printf 'unknown\n' ;;
	esac
}

detect_gpu_vendors() {
	local found=0
	local line lower vendor_id
	local -A seen=()

	if command -v lspci >/dev/null 2>&1; then
		while IFS= read -r line; do
			lower=$(printf '%s' "$line" | tr '[:upper:]' '[:lower:]')
			case $lower in
				*nvidia*) seen[nvidia]=1 ;;
				*advanced\ micro\ devices*|*amd*|*ati*|*radeon*) seen[amd]=1 ;;
				*intel*) seen[intel]=1 ;;
			esac
		done < <(lspci 2>/dev/null | grep -Ei 'vga|3d|display')
	fi

	if [[ ${#seen[@]} -eq 0 ]]; then
		for vendor_id in /sys/class/drm/card*/device/vendor; do
			[[ -f $vendor_id ]] || continue
			case $(<"$vendor_id") in
				0x10de) seen[nvidia]=1 ;;
				0x1002) seen[amd]=1 ;;
				0x8086) seen[intel]=1 ;;
			esac
		done
	fi

	for line in intel amd nvidia; do
		if [[ -n ${seen[$line]:-} ]]; then
			printf '%s\n' "$line"
			found=1
		fi
		done

	return $(( found == 0 ))
}

append_package_file_if_present() {
	local -n _apfip_ref=$1
	local file_path=$2
	[[ -f $file_path ]] || return 0
	_apfip_ref+=("$file_path")
}

add_hardware_package_files() {
	local -n _ahpf_ref=$1
	local cpu_vendor gpu_vendor
	local gpu_vendors=()

	cpu_vendor=$(detect_cpu_vendor)
	case $cpu_vendor in
		intel)
			msg "Intel CPU detected, including intel microcode" >&2
			append_package_file_if_present _ahpf_ref "$INSTALL_DIR/pkg-cpu-intel.txt"
			;;
		amd)
			msg "AMD CPU detected, including amd microcode" >&2
			append_package_file_if_present _ahpf_ref "$INSTALL_DIR/pkg-cpu-amd.txt"
			;;
		*)
			warn "Could not detect CPU vendor for microcode selection" >&2
			;;
	esac

	mapfile -t gpu_vendors < <(detect_gpu_vendors || true)
	if ((${#gpu_vendors[@]} == 0)); then
		warn "Could not detect GPU vendor; using base graphics packages only" >&2
		return
	fi

	for gpu_vendor in "${gpu_vendors[@]}"; do
		case $gpu_vendor in
			intel)
				msg "Intel GPU detected, including Intel + Mesa graphics packages" >&2
				append_package_file_if_present _ahpf_ref "$INSTALL_DIR/pkg-gpu-intel.txt"
				;;
			amd)
				msg "AMD GPU detected, including AMD + Mesa graphics packages" >&2
				append_package_file_if_present _ahpf_ref "$INSTALL_DIR/pkg-gpu-amd.txt"
				;;
			nvidia)
				msg "NVIDIA GPU detected, including NVIDIA graphics packages" >&2
				append_package_file_if_present _ahpf_ref "$INSTALL_DIR/pkg-nvi.txt"
				;;
		esac
		done
}

gather_package_list() {
	local files=()
	[[ -f "$INSTALL_DIR/pkg.txt" ]] && files+=("$INSTALL_DIR/pkg.txt")
	add_hardware_package_files files

	((${#files[@]})) || return 0
	awk '{print $1}' "${files[@]}" | sed -e 's/#.*//' -e '/^\s*$/d' | sort -u
}

is_repo_package() {
	local pkg=$1
	$PACMAN -Si "$pkg" >/dev/null 2>&1
}

is_already_satisfied() {
	# Returns 0 if the package (or a provider of it) is already installed.
	local pkg=$1
	pacman -Qi "$pkg" >/dev/null 2>&1 && return 0
	# Check if another installed package provides this one.
	local provider
	provider=$(pacman -Qq --provides "$pkg" 2>/dev/null | head -1)
	[[ -n $provider ]]
}

split_package_lists() {
	local -n _all_pkgs_ref=$1
	local -n _repo_pkgs_ref=$2
	local -n _aur_pkgs_ref=$3
	local -n _skip_pkgs_ref=$4
	local pkg

	for pkg in "${_all_pkgs_ref[@]}"; do
		if is_repo_package "$pkg"; then
			_repo_pkgs_ref+=("$pkg")
		elif is_already_satisfied "$pkg"; then
			_skip_pkgs_ref+=("$pkg")
		else
			_aur_pkgs_ref+=("$pkg")
		fi
	done
}

install_all_packages() {
	local pkgs=()
	local repo_pkgs=()
	local aur_pkgs=()
	local skip_pkgs=()
	mapfile -t pkgs < <(gather_package_list)
	if ((${#pkgs[@]} == 0)); then
		warn "No packages found to install"
		return
	fi

	msg "Classifying ${#pkgs[@]} packages (repo vs AUR)..."
	split_package_lists pkgs repo_pkgs aur_pkgs skip_pkgs

	if ((${#skip_pkgs[@]})); then
		msg "Skipping ${#skip_pkgs[@]} packages already satisfied: ${skip_pkgs[*]}"
	fi

	if ((${#repo_pkgs[@]})); then
		msg "Installing ${#repo_pkgs[@]} repo packages via pacman"
		$SUDO_CMD $PACMAN -S --needed --noconfirm "${repo_pkgs[@]}"
	fi

	if ((${#aur_pkgs[@]})); then
		msg "Installing ${#aur_pkgs[@]} AUR packages via $AURHELPER"
		local aur_flags=(--needed --noconfirm --noprovides --useask)
		if [[ $AURHELPER == "paru" ]]; then
			aur_flags+=(--skipreview --noupgrademenu --sudoloop)
		fi
		run_as_invoking_user "$AURHELPER" -S "${aur_flags[@]}" "${aur_pkgs[@]}"
	fi
}

link_dotfiles() {
	msg "Linking dotfiles into $USER_HOME"
	mkdir -p "$USER_HOME/.config" "$USER_HOME/.config/autostart" "$USER_HOME/.local/share" "$USER_HOME/bin"

	if [[ -d "$REPO_DIR/.config" ]]; then
		for d in "$REPO_DIR/.config"/*; do
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

	if [[ -d "$REPO_DIR/.local" ]]; then
		rsync -a --info=NAME --exclude="share/icons" --exclude="share/themes" "$REPO_DIR/.local/" "$USER_HOME/.local/"
	fi

	if [[ -d "$REPO_DIR/assets/wal" ]]; then
		mkdir -p "$USER_HOME/.local/share/wallpapers"
		rsync -a --info=NAME "$REPO_DIR/assets/wal/" "$USER_HOME/.local/share/wallpapers/"
	fi

	if [[ -n "$SUDO_CMD" ]]; then
		$SUDO_CMD chown -R "$USER_NAME":"$USER_NAME" "$USER_HOME/.config" "$USER_HOME/.local" "$USER_HOME/bin"
	fi
}

save_weather_location() {
	local location_file location_dir
	[[ -n $WEATHER_LOCATION ]] || return 0

	location_file=$(weather_location_file)
	location_dir=$(dirname "$location_file")
	msg "Saving weather widget location: $WEATHER_LOCATION"
	mkdir -p "$location_dir"
	printf '%s\n' "$WEATHER_LOCATION" > "$location_file"

	if [[ -n "$SUDO_CMD" ]]; then
		$SUDO_CMD chown -R "$USER_NAME":"$USER_NAME" "$USER_HOME/.local/state"
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
	local backup
	local dur_src
	local dur_dest
	local config_changed=0

	if [[ ! -f "$src" ]]; then
		warn "Skipping ly config install; file not found: $src"
		return
	fi

	if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
		msg "ly config already matches tracked config"
	else
		if [[ -f "$dest" ]]; then
			backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
			warn "Backing up existing ly config to $backup"
			$SUDO_CMD cp "$dest" "$backup"
		fi

		msg "Installing ly config"
		$SUDO_CMD install -Dm644 "$src" "$dest"
		config_changed=1
	fi

	# Tracked .dur animations (used when animation = dur_file)
	shopt -s nullglob
	for dur_src in "$INSTALL_DIR"/ly/*.dur; do
		dur_dest="/etc/ly/$(basename "$dur_src")"
		if [[ -f "$dur_dest" ]] && cmp -s "$dur_src" "$dur_dest"; then
			continue
		fi
		msg "Installing ly animation: $(basename "$dur_src")"
		$SUDO_CMD install -Dm644 "$dur_src" "$dur_dest"
		config_changed=1
	done
	shopt -u nullglob

	if [[ $config_changed -eq 0 ]]; then
		msg "ly assets already match tracked config"
	fi
}

install_nm_iwd_config() {
	local src="$INSTALL_DIR/networkmanager/conf.d/wifi_backend.conf"
	local dest="/etc/NetworkManager/conf.d/wifi_backend.conf"
	local backup

	if [[ ! -f "$src" ]]; then
		warn "Skipping NetworkManager iwd config install; file not found: $src"
		return
	fi

	if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
		msg "NetworkManager iwd backend config already matches tracked config"
		return
	fi

	if [[ -f "$dest" ]]; then
		backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
		warn "Backing up existing NetworkManager iwd config to $backup"
		$SUDO_CMD cp "$dest" "$backup"
	fi

	msg "Installing NetworkManager iwd backend config"
	$SUDO_CMD install -Dm644 "$src" "$dest"
}

install_nvidia_config() {
	local src="$INSTALL_DIR/nvidia/modprobe/nvidia.conf"

	if [[ -f "$src" ]]; then
		msg "Installing NVIDIA module configuration"
		$SUDO_CMD install -Dm644 "$src" /etc/modprobe.d/nvidia.conf
	fi
}

enable_services() {
	# ly uses a template unit (ly@.service) and needs a TTY instance.
	if systemctl list-unit-files | grep -q '^ly@\.service'; then
		msg "Enabling ly display manager on tty2"
		$SUDO_CMD systemctl enable ly@tty2 || true
	fi

	if systemctl list-unit-files | grep -q '^iwd\.service'; then
		msg "Enabling iwd service"
		$SUDO_CMD systemctl enable iwd.service || true
	fi

	if systemctl list-unit-files | grep -q '^wpa_supplicant\.service'; then
		msg "Disabling wpa_supplicant service"
		$SUDO_CMD systemctl disable wpa_supplicant.service || true
	fi

	if systemctl list-unit-files | grep -q '^wpa_supplicant@\.service'; then
		msg "Disabling wpa_supplicant template service"
		$SUDO_CMD systemctl disable wpa_supplicant@.service || true
	fi
}

refresh_font_cache() {
	if command -v fc-cache >/dev/null 2>&1; then
		msg "Refreshing font cache"
		fc-cache -rfv || true
	fi
}

apply_default_wallpaper() {
	local wallpaper_path="$USER_HOME/.local/share/wallpapers/lucy.jpeg"

	if [[ ! -f "$wallpaper_path" ]]; then
		return
	fi

	if ! command -v wallpaper >/dev/null 2>&1; then
		warn "Skipping wallpaper apply because the 'wallpaper' command is unavailable"
		return
	fi

	msg "Applying default wallpaper"
	run_as_invoking_user wallpaper "$wallpaper_path" || true
}

print_post_install_notes() {
	cat <<EOF

Done. Next steps (optional):
	- Reboot to switch to linux-zen kernel and ensure services start.
	- Log in with the 'ly' display manager and choose your Wayland session (niri).
	- NetworkManager is configured to use iwd from /etc/NetworkManager/conf.d/wifi_backend.conf.
	- If Wi-Fi does not switch immediately, restart NetworkManager or reboot once.
	- Right-click the Waybar weather widget any time to change the saved location.
	- Consider changing your shell to fish: chsh -s "/usr/bin/fish" "$USER_NAME"
	- For wallust-based theming, pick a wallpaper and run: wallust run /path/to/wallpaper

EOF
}

main() {
	trap cleanup_terminal EXIT INT TERM
	parse_args "$@"
	enable_tui_if_possible
	require_arch
	need_sudo
	configure_install_plan
	prompt_weather_location
	print_banner
	show_install_summary

	if [[ $RUN_PACMAN_TWEAKS -eq 1 ]]; then
		enable_pacman_tweaks
	fi
	if [[ $RUN_SYSTEM_UPDATE -eq 1 ]]; then
		refresh_keys_and_system
	fi
	if [[ $RUN_PREREQS -eq 1 ]]; then
		setup_prereqs
	fi
	if [[ $RUN_CHAOTIC_AUR -eq 1 ]]; then
		setup_chaotic_aur
	fi
	if [[ $RUN_PACKAGES -eq 1 ]]; then
		AURHELPER=$(find_aur_helper)
		install_all_packages
	fi
	if [[ $RUN_DOTFILES -eq 1 ]]; then
		link_dotfiles
		save_weather_location
		apply_desktop_theme
		install_nvidia_config
	fi
	if [[ $RUN_LY_CONFIG -eq 1 ]]; then
		install_ly_config
	fi
	if [[ $RUN_NM_IWD_CONFIG -eq 1 ]]; then
		install_nm_iwd_config
	fi
	if [[ $RUN_SERVICES -eq 1 ]]; then
		enable_services
	fi
	if [[ $RUN_PACKAGES -eq 1 || $RUN_DOTFILES -eq 1 ]]; then
		refresh_font_cache
	fi
	if [[ $RUN_SET_WALLPAPER -eq 1 ]]; then
		apply_default_wallpaper
	fi

	print_post_install_notes
}

main "$@"

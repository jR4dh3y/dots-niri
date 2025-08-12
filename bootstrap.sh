#!/usr/bin/env bash
# Curl-friendly bootstrap for dots-niri
# Usage examples:
#   curl -fsSL https://raw.githubusercontent.com/<user>/<repo>/<branch>/bootstrap.sh | bash -s -- \
#     --repo https://github.com/<user>/<repo>.git --branch main --dir "$HOME/code/dots-niri"
#   REPO=https://github.com/<user>/<repo>.git BRANCH=main DIR=$HOME/code/dots-niri bash bootstrap.sh

set -euo pipefail
IFS=$'\n\t'

msg() { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m==>\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m==>\033[0m %s\n" "$*" 1>&2; }
die() { err "$*"; exit 1; }

[[ -f /etc/arch-release ]] || die "This bootstrap is intended for Arch Linux."

EUID_REQ=0
SUDO_CMD=""
if [[ $EUID -ne $EUID_REQ ]]; then
  if command -v sudo >/dev/null 2>&1; then SUDO_CMD=sudo; else die "sudo is required (run as root or install sudo)"; fi
fi

# Defaults (can be overridden by flags or env)
REPO=${REPO:-}
BRANCH=${BRANCH:-main}
DIR=${DIR:-"$HOME/code/dots-niri"}

print_help() {
  cat <<EOF
Bootstrap dots-niri on Arch by cloning the repo and running its install.sh

Flags:
  --repo <url>      Git repo URL (required when piping via curl)
  --branch <name>   Branch/tag (default: ${BRANCH})
  --dir <path>      Clone directory (default: ${DIR})
  -h, --help        Show this help

Environment overrides:
  REPO, BRANCH, DIR

Examples:
  curl -fsSL https://raw.githubusercontent.com/<user>/<repo>/<branch>/bootstrap.sh | \
    bash -s -- --repo https://github.com/<user>/<repo>.git --branch main --dir "$HOME/code/dots-niri"
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo) REPO=${2:-}; shift 2;;
      --branch) BRANCH=${2:-}; shift 2;;
      --dir) DIR=${2:-}; shift 2;;
      -h|--help) print_help; exit 0;;
      *) warn "Ignoring unknown arg: $1"; shift;;
    esac
  done
}

parse_args "$@"

if [[ -z "$REPO" ]]; then
  # Try to infer when running locally inside a git clone
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    REPO=$(git config --get remote.origin.url || true)
  fi
fi

[[ -n "$REPO" ]] || die "--repo URL is required (or set REPO env)."

msg "Installing minimal prerequisites (git, curl) if needed"
$SUDO_CMD pacman -Sy --noconfirm archlinux-keyring || true
$SUDO_CMD pacman -S --needed --noconfirm git curl

msg "Cloning repo: $REPO (branch: $BRANCH) -> $DIR"
mkdir -p "$(dirname "$DIR")"
if [[ -d "$DIR/.git" ]]; then
  (cd "$DIR" && git fetch --all --tags --prune && git checkout "$BRANCH" && git pull --ff-only)
else
  git clone --depth=1 --branch "$BRANCH" "$REPO" "$DIR"
fi

INSTALL_SH="$DIR/install.sh"
[[ -f "$INSTALL_SH" ]] || die "install.sh not found in cloned repo: $DIR"

msg "Running installer: $INSTALL_SH"
chmod +x "$INSTALL_SH"
"$INSTALL_SH"

msg "Bootstrap complete."

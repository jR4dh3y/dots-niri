#!/usr/bin/env bash
# Apply the dotfiles' default desktop theme after configs are linked.

set -euo pipefail
IFS=$'\n\t'

INSTALL_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=${THEME_REPO_DIR:-$(cd -- "$INSTALL_DIR/.." && pwd)}
USER_HOME=${THEME_USER_HOME:-${HOME}}

THEME_ID="NonchalantPurple"
THEME_NAME="Nonchalant-Purple"
QT_PALETTE_NAME="nonchalant-purple.conf"
KDE_THEME_SRC="$INSTALL_DIR/themes/${THEME_ID}.colors"
KDE_THEME_DEST="$USER_HOME/.local/share/color-schemes/${THEME_ID}.colors"

install_config() {
	local src=$1
	local dest=$2

	if [[ -e "$dest" && "$(readlink -f "$src")" == "$(readlink -f "$dest")" ]]; then
		return
	fi

	install -Dm644 "$src" "$dest"
}

write_ini_key() {
	local file=$1
	local group=$2
	local key=$3
	local value=$4

	if command -v kwriteconfig6 >/dev/null 2>&1; then
		kwriteconfig6 --file "$file" --group "$group" --key "$key" "$value"
	elif command -v kwriteconfig5 >/dev/null 2>&1; then
		kwriteconfig5 --file "$file" --group "$group" --key "$key" "$value"
	fi
}

set_gsetting() {
	local schema=$1
	local key=$2
	local value=$3

	if command -v gsettings >/dev/null 2>&1 && gsettings writable "$schema" "$key" >/dev/null 2>&1; then
		gsettings set "$schema" "$key" "$value" || true
	fi
}

install_config "$KDE_THEME_SRC" "$KDE_THEME_DEST"

mkdir -p "$USER_HOME/.config/qt5ct/colors" "$USER_HOME/.config/qt6ct/colors"
install_config "$REPO_DIR/.config/qt5ct/colors/$QT_PALETTE_NAME" "$USER_HOME/.config/qt5ct/colors/$QT_PALETTE_NAME"
install_config "$REPO_DIR/.config/qt6ct/colors/$QT_PALETTE_NAME" "$USER_HOME/.config/qt6ct/colors/$QT_PALETTE_NAME"

set_gsetting org.gnome.desktop.interface gtk-theme "'adw-gtk3-dark'"
set_gsetting org.gnome.desktop.interface color-scheme "'prefer-dark'"
set_gsetting org.gnome.desktop.interface icon-theme "'Papirus-Dark'"

write_ini_key "$USER_HOME/.config/kdeglobals" General ColorScheme "$THEME_ID"
write_ini_key "$USER_HOME/.config/kdeglobals" General Name "$THEME_NAME"
write_ini_key "$USER_HOME/.config/kdeglobals" Icons Theme "Papirus-Dark"
write_ini_key "$USER_HOME/.config/kdeglobals" KDE LookAndFeelPackage "org.kde.breezedark.desktop"
write_ini_key "$USER_HOME/.config/kdeglobals" General widgetStyle "Breeze"
write_ini_key "$USER_HOME/.config/kdeglobals" KDE widgetStyle "Breeze"

write_ini_key "$USER_HOME/.config/dolphinrc" UiSettings ColorScheme "$THEME_ID"
write_ini_key "$USER_HOME/.config/dolphinrc" UiSettings ColorSchemePath "${THEME_ID}.colors"

write_ini_key "$USER_HOME/.config/qt5ct/qt5ct.conf" Appearance color_scheme_path "$USER_HOME/.config/qt5ct/colors/$QT_PALETTE_NAME"
write_ini_key "$USER_HOME/.config/qt5ct/qt5ct.conf" Appearance custom_palette "true"
write_ini_key "$USER_HOME/.config/qt5ct/qt5ct.conf" Appearance icon_theme "Papirus-Dark"
write_ini_key "$USER_HOME/.config/qt5ct/qt5ct.conf" Appearance style "Fusion"

write_ini_key "$USER_HOME/.config/qt6ct/qt6ct.conf" Appearance color_scheme_path "$USER_HOME/.config/qt6ct/colors/$QT_PALETTE_NAME"
write_ini_key "$USER_HOME/.config/qt6ct/qt6ct.conf" Appearance custom_palette "true"
write_ini_key "$USER_HOME/.config/qt6ct/qt6ct.conf" Appearance icon_theme "Papirus-Dark"
write_ini_key "$USER_HOME/.config/qt6ct/qt6ct.conf" Appearance style "Breeze"

if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
	plasma-apply-colorscheme "$THEME_ID" >/dev/null 2>&1 || true
fi

if command -v kbuildsycoca6 >/dev/null 2>&1; then
	kbuildsycoca6 >/dev/null 2>&1 || true
fi

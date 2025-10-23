#!/usr/bin/env bash
# Theme Switcher for Dots-Niri (Phase 6)
# Uses the centralized theme engine to apply themes across all 7 apps

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
THEME_ENGINE_SCRIPTS="$SCRIPT_DIR/.config/theme-engine/scripts"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Show usage
show_help() {
    cat << EOF
Theme Switcher - Apply themes across all 7 applications

Usage:
  $(basename "$0") <theme_name>
  $(basename "$0") --list
  $(basename "$0") --help

Examples:
  $(basename "$0") myoriginal
  $(basename "$0") nonchalant-purp
  $(basename "$0") --list

Available Themes:
  Run: $(basename "$0") --list

Supported Applications (7):
  • Waybar .......... Status bar
  • Kitty .......... Terminal emulator
  • Fuzzel ......... Application launcher
  • Wlogout ........ Logout menu
  • Niri ........... Tiling window manager (auto-reloads)
  • Hyprlock ....... Lock screen
  • Dunst .......... Notification daemon

After applying theme, reload apps:
  bash ~/.config/theme-engine/scripts/reload-apps.sh

EOF
}

# List available themes
list_themes() {
    log_info "Available themes:"
    python3 "$THEME_ENGINE_SCRIPTS/list-themes.py" --detailed
}

# Apply theme using Phase 6 engine
apply_theme() {
    local theme_name="$1"
    
    log_info "Applying theme: $theme_name"
    
    if python3 "$THEME_ENGINE_SCRIPTS/apply-theme.py" "$theme_name"; then
        log_success "Theme '$theme_name' applied successfully!"
        echo ""
        log_info "Next steps:"
        echo "  1. Reload apps: bash ~/.config/theme-engine/scripts/reload-apps.sh"
        echo "  2. Niri will auto-reload on next config save"
        return 0
    else
        log_error "Failed to apply theme '$theme_name'"
        return 1
    fi
}

# Main
main() {
    case "${1:-}" in
        --help|-h)
            show_help
            exit 0
            ;;
        --list|-l)
            list_themes
            exit 0
            ;;
        "")
            log_error "Missing theme name"
            show_help
            exit 1
            ;;
        *)
            apply_theme "$1"
            exit $?
            ;;
    esac
}

main "$@"

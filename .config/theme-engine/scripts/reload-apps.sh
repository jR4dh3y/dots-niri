#!/bin/bash
# Reload Apps Script - Reload applications after theme change
# 
# This script reloads applications to apply the newly changed theme.
# It handles different app reload methods (signals, commands, etc).
#
# Usage:
#   reload-apps.sh
#   reload-apps.sh --help
#   reload-apps.sh --waybar
#   reload-apps.sh --kitty
#   reload-apps.sh --fuzzel
#   reload-apps.sh --wlogout
#   reload-apps.sh --hyprlock
#   reload-apps.sh --dunst

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

log_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Reload waybar
reload_waybar() {
    log_info "Reloading waybar..."
    
    if command -v waybar &> /dev/null; then
        # Kill existing waybar
        if pgrep -x "waybar" > /dev/null; then
            pkill -f waybar || true
            sleep 0.5
        fi
        
        # Start new waybar instance
        waybar > /dev/null 2>&1 &
        sleep 1
        log_success "Waybar reloaded"
        return 0
    else
        log_warning "Waybar not installed"
        return 1
    fi
}

# Reload kitty
reload_kitty() {
    log_info "Reloading kitty..."
    
    if command -v kitty &> /dev/null; then
        # Use kitty's remote control to reload
        if pgrep -x "kitty" > /dev/null; then
            # Send reload signal to kitty
            kitty @ load-config 2>/dev/null || {
                # Fallback: send SIGUSR1 to kitty
                pkill -USR1 -x kitty 2>/dev/null || true
            }
            sleep 0.5
            log_success "Kitty reloaded"
            return 0
        else
            log_warning "Kitty not running"
            return 1
        fi
    else
        log_warning "Kitty not installed"
        return 1
    fi
}

# Reload fuzzel
reload_fuzzel() {
    log_info "Reloading fuzzel..."
    
    if command -v fuzzel &> /dev/null; then
        # Fuzzel auto-reloads on config change, no special action needed
        log_success "Fuzzel reloading on next launch"
        return 0
    else
        log_warning "Fuzzel not installed"
        return 1
    fi
}

# Reload wlogout
reload_wlogout() {
    log_info "Reloading wlogout..."
    
    if command -v wlogout &> /dev/null; then
        # Wlogout reloads on next invocation
        log_success "Wlogout will reload on next launch"
        return 0
    else
        log_warning "Wlogout not installed"
        return 1
    fi
}

# Reload hyprlock
reload_hyprlock() {
    log_info "Reloading hyprlock..."
    
    if command -v hyprlock &> /dev/null; then
        # Hyprlock reloads config on next invocation
        log_success "Hyprlock will reload on next launch"
        return 0
    else
        log_warning "Hyprlock not installed"
        return 1
    fi
}

# Reload dunst
reload_dunst() {
    log_info "Reloading dunst..."
    
    if command -v dunst &> /dev/null; then
        # Dunst reloads config via SIGUSR1 signal
        if pgrep -x "dunst" > /dev/null; then
            pkill -USR1 -x dunst 2>/dev/null || true
            sleep 0.5
            log_success "Dunst reloaded"
            return 0
        else
            log_warning "Dunst not running"
            return 1
        fi
    else
        log_warning "Dunst not installed"
        return 1
    fi
}

# Show usage
show_help() {
    cat << EOF
Reload Apps - Reload applications after theme change

Usage:
  $(basename "$0")                 Reload all applications
  $(basename "$0") --help          Show this help message
  $(basename "$0") --waybar        Reload only waybar
  $(basename "$0") --kitty         Reload only kitty
  $(basename "$0") --fuzzel        Reload only fuzzel
  $(basename "$0") --wlogout       Reload only wlogout
  $(basename "$0") --hyprlock      Reload only hyprlock
  $(basename "$0") --dunst         Reload only dunst

Examples:
  # Reload all apps
  bash ~/.config/theme-engine/scripts/reload-apps.sh
  
  # Reload specific app
  bash ~/.config/theme-engine/scripts/reload-apps.sh --waybar
  bash ~/.config/theme-engine/scripts/reload-apps.sh --dunst
  
  # Quick alias
  alias reload-apps='bash ~/.config/theme-engine/scripts/reload-apps.sh'
  reload-apps
  reload-apps --waybar

Supported Applications (6 reloadable):
  • Waybar ........... Status bar (killed and restarted)
  • Kitty ............ Terminal emulator (reloaded via config)
  • Fuzzel ........... Application launcher (reloads on next use)
  • Wlogout .......... Logout menu (reloads on next use)
  • Hyprlock ......... Lock screen (reloads on next use)
  • Dunst ............ Notification daemon (reloaded via SIGUSR1)

Note: Niri automatically detects file changes and reloads without needing
      a reload command.

EOF
}

# Reload all apps
reload_all() {
    echo ""
    log_info "Starting application reload process..."
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    
    local success_count=0
    local total_count=6
    
    # Reload each app
    reload_waybar && ((success_count++)) || true
    reload_kitty && ((success_count++)) || true
    reload_fuzzel && ((success_count++)) || true
    reload_wlogout && ((success_count++)) || true
    reload_hyprlock && ((success_count++)) || true
    reload_dunst && ((success_count++)) || true
    
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    log_info "Reload process complete: $success_count/$total_count apps reloaded"
    echo ""
    
    if [ $success_count -eq $total_count ]; then
        log_success "All apps successfully reloaded!"
        return 0
    else
        log_warning "$((total_count - success_count)) app(s) were not reloaded (may not be running)"
        return 1
    fi
}

# Main script
main() {
    # Handle arguments
    case "${1:-}" in
        --help|-h)
            show_help
            exit 0
            ;;
        --waybar)
            reload_waybar
            exit $?
            ;;
        --kitty)
            reload_kitty
            exit $?
            ;;
        --fuzzel)
            reload_fuzzel
            exit $?
            ;;
        --wlogout)
            reload_wlogout
            exit $?
            ;;
        --hyprlock)
            reload_hyprlock
            exit $?
            ;;
        --dunst)
            reload_dunst
            exit $?
            ;;
        "")
            reload_all
            exit $?
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"

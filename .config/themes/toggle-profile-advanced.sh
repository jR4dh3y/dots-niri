#!/bin/bash
# Advanced Color Profile Toggle Script
# Uses Fuzzel for interactive profile selection
# Supports multiple profiles and applications

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

THEMES_DIR="$HOME/.config/themes"
SCRIPT_NAME="toggle-profile"
VERSION="1.0"

# Application configuration paths
declare -A APP_CONFIG=(
    ["waybar"]="$HOME/.config/waybar/style.css"
    ["wlogout"]="$HOME/.config/wlogout/nova.css"
    ["wlogout-colors"]="$HOME/.config/wlogout/colors.css"
    ["kitty"]="$HOME/.config/kitty/colors.conf"
    ["hyprland"]="$HOME/.config/hypr/hyprland/colors.conf"
    ["hyprlock"]="$HOME/.config/hypr/hyprlock.conf"
    ["fuzzel"]="$HOME/.config/fuzzel/fuzzel_theme.ini"
    ["dunst"]="$HOME/.config/dunst/dunstrc"
    ["niri"]="$HOME/.config/niri/config.kdl"
)

# Available profiles with descriptions
declare -A PROFILES=(
    ["default"]="Default - Modern, vibrant green/blue accents"
    ["nonchalant-purp"]="Nonchalant Purp - Sophisticated violet/lime"
)

# Profile colors (for manual updates)
declare -A COLORS_DEFAULT=(
    ["bg"]="#1A1B26"
    ["fg"]="#C0CAF5"
    ["accent"]="#9ECE6A"
    ["highlight"]="#7AA2F7"
    ["caution"]="#E0AF68"
    ["urgent"]="#F7768E"
    ["tray"]="#414868"
    ["border"]="#414868"
    ["muted"]="#89b4fa"
)

declare -A COLORS_NONCHALANT_PURP=(
    ["bg"]="#1e1e20"
    ["fg"]="#dcd9e7"
    ["accent"]="#c59edc"
    ["highlight"]="#c3fb5b"
    ["caution"]="#ffb86c"
    ["urgent"]="#ff6e79"
    ["tray"]="#2a2a2c"
    ["border"]="#3a3a3d"
    ["muted"]="#9c96ad"
)

# ============================================================================
# FUNCTIONS
# ============================================================================

# Print usage information
usage() {
    cat << EOF
$SCRIPT_NAME v$VERSION - Color Profile Toggle Script

Usage:
  $SCRIPT_NAME              # Interactive mode (uses Fuzzel)
  $SCRIPT_NAME list         # List available profiles
  $SCRIPT_NAME current      # Show current profile
  $SCRIPT_NAME set <name>   # Set profile directly
  $SCRIPT_NAME --help       # Show this help

Examples:
  $SCRIPT_NAME                          # Open Fuzzel to select profile
  $SCRIPT_NAME set nonchalant-purp      # Switch to nonchalant-purp
  $SCRIPT_NAME list                     # Show all available profiles

Profiles:
EOF
    for profile in "${!PROFILES[@]}"; do
        echo "  - $profile: ${PROFILES[$profile]}"
    done
}

# Get current active profile
get_current_profile() {
    if [ -f "${APP_CONFIG[waybar]}" ]; then
        if grep -q "nonchalant-purp.css" "${APP_CONFIG[waybar]}" 2>/dev/null; then
            echo "nonchalant-purp"
        else
            echo "default"
        fi
    else
        echo "default"
    fi
}

# List all profiles
list_profiles() {
    echo "Available Color Profiles:"
    echo "=========================="
    local current=$(get_current_profile)
    for profile in "${!PROFILES[@]}"; do
        if [ "$profile" = "$current" ]; then
            echo "✓ $profile (active) - ${PROFILES[$profile]}"
        else
            echo "  $profile - ${PROFILES[$profile]}"
        fi
    done
}

# Show current profile
show_current() {
    local current=$(get_current_profile)
    echo "Current Profile: $current"
    echo "Description: ${PROFILES[$current]}"
}

# Update CSS-based config files
update_css_configs() {
    local from_profile=$1
    local to_profile=$2
    
    if [ "$from_profile" = "default" ] && [ "$to_profile" = "nonchalant-purp" ]; then
        echo "  Updating CSS imports: default → nonchalant-purp..."
        
        [ -f "${APP_CONFIG[waybar]}" ] && \
            sed -i 's|global-colors.css|nonchalant-purp.css|g' "${APP_CONFIG[waybar]}"
        
        [ -f "${APP_CONFIG[wlogout]}" ] && \
            sed -i 's|global-colors.css|nonchalant-purp.css|g' "${APP_CONFIG[wlogout]}"
        
        [ -f "${APP_CONFIG[wlogout-colors]}" ] && \
            sed -i 's|global-colors.css|nonchalant-purp.css|g' "${APP_CONFIG[wlogout-colors]}"
            
    elif [ "$from_profile" = "nonchalant-purp" ] && [ "$to_profile" = "default" ]; then
        echo "  Updating CSS imports: nonchalant-purp → default..."
        
        [ -f "${APP_CONFIG[waybar]}" ] && \
            sed -i 's|nonchalant-purp.css|global-colors.css|g' "${APP_CONFIG[waybar]}"
        
        [ -f "${APP_CONFIG[wlogout]}" ] && \
            sed -i 's|nonchalant-purp.css|global-colors.css|g' "${APP_CONFIG[wlogout]}"
        
        [ -f "${APP_CONFIG[wlogout-colors]}" ] && \
            sed -i 's|nonchalant-purp.css|global-colors.css|g' "${APP_CONFIG[wlogout-colors]}"
    fi
}

# Get color value from profile
get_color() {
    local profile=$1
    local color=$2
    local array_name="COLORS_${profile//\-/_}"
    array_name="${array_name^^}"
    eval "echo \${$array_name[$color]}"
}

# Print profile colors
print_profile_colors() {
    local profile=$1
    echo ""
    echo "Colors for $profile profile:"
    echo "  Background:  $(get_color "$profile" bg)"
    echo "  Foreground:  $(get_color "$profile" fg)"
    echo "  Accent:      $(get_color "$profile" accent)"
    echo "  Highlight:   $(get_color "$profile" highlight)"
    echo "  Caution:     $(get_color "$profile" caution)"
    echo "  Urgent:      $(get_color "$profile" urgent)"
    echo "  Tray:        $(get_color "$profile" tray)"
    echo "  Border:      $(get_color "$profile" border)"
}

# Reload applications
reload_apps() {
    echo ""
    echo "Reloading applications..."
    
    # Waybar - restart to pick up new CSS imports
    if pgrep -x waybar > /dev/null 2>&1; then
        echo "  🔄 Restarting Waybar..."
        killall waybar 2>/dev/null || true
        sleep 0.5
        waybar > /dev/null 2>&1 &
        sleep 0.5
    fi
    
    # Kitty - restart all instances to pick up new colors
    if pgrep -x kitty > /dev/null 2>&1; then
        echo "  🔄 Restarting Kitty terminal..."
        killall kitty 2>/dev/null || true
        sleep 0.5
    fi
    
    # Wlogout - restart to pick up new CSS
    if pgrep -x wlogout > /dev/null 2>&1; then
        echo "  🔄 Closing Wlogout..."
        killall wlogout 2>/dev/null || true
    fi
    
    # Fuzzel - no reload needed (will use new colors on next launch)
    # Dunst - will pick up environment changes
    # Hyprlock - will reload on next lock
    # Niri/Hyprland - will read new config on restart
    
    echo ""
    echo "📝 Note: Some applications may need manual restart for full color update:"
    echo "   • Hyprland/Niri: Restart compositor"
    echo "   • Hyprlock: Colors update on next lock"
    echo "   • Firefox/Other GTK apps: May need restart"
}

# Switch to a profile
switch_profile() {
    local to_profile=$1
    local current=$(get_current_profile)
    
    # Validate profile exists
    if [ -z "${PROFILES[$to_profile]}" ]; then
        echo "❌ Error: Profile '$to_profile' not found"
        echo "Available profiles: ${!PROFILES[@]}"
        exit 1
    fi
    
    # Check if already on that profile
    if [ "$current" = "$to_profile" ]; then
        echo "ℹ️  Already using $to_profile profile"
        return 0
    fi
    
    echo "🎨 Switching color profile..."
    echo "  From: $current"
    echo "  To:   $to_profile"
    
    # Update CSS configs
    update_css_configs "$current" "$to_profile"
    
    # Show profile colors
    print_profile_colors "$to_profile"
    
    # Reload applications
    reload_apps
    
    # Notify user
    if command -v notify-send &> /dev/null; then
        notify-send "🎨 Color Profile" \
            "Switched to $to_profile\n\nWaybar, Kitty, and Wlogout restarted.\nOther apps may need manual restart." \
            -t 5000 -i "preferences-desktop-theme"
    fi
    
    echo ""
    echo "✅ Profile switched successfully!"
}

# Interactive mode with Fuzzel
interactive_mode() {
    if ! command -v fuzzel &> /dev/null; then
        echo "❌ Error: Fuzzel not found. Install it first."
        echo "Falling back to menu mode..."
        
        # Simple menu if Fuzzel not available
        echo ""
        list_profiles
        echo ""
        read -p "Enter profile name to switch to: " choice
        if [ -n "$choice" ] && [ -n "${PROFILES[$choice]}" ]; then
            switch_profile "$choice"
        else
            echo "❌ Invalid choice"
            exit 1
        fi
    else
        # Use Fuzzel for selection
        local choice
        choice=$(printf '%s\n' "${!PROFILES[@]}" | fuzzel --dmenu \
            --prompt="Select Color Profile: " \
            --lines=10 \
            --width=50 \
            2>/dev/null)
        
        if [ -z "$choice" ]; then
            echo "ℹ️  Profile selection cancelled"
            exit 0
        fi
        
        switch_profile "$choice"
    fi
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    case "${1:-}" in
        "")
            interactive_mode
            ;;
        "list")
            list_profiles
            ;;
        "current")
            show_current
            ;;
        "set")
            if [ -z "$2" ]; then
                echo "❌ Error: Profile name required"
                echo "Usage: $SCRIPT_NAME set <profile_name>"
                exit 1
            fi
            switch_profile "$2"
            ;;
        "--help"|"-h"|"help")
            usage
            ;;
        *)
            echo "❌ Unknown command: $1"
            usage
            exit 1
            ;;
    esac
}

main "$@"

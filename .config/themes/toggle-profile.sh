#!/bin/bash
# Color Profile Toggle Script
# Uses Fuzzel to select and switch between color profiles
# Install: cp ~/.config/themes/toggle-profile.sh ~/.local/bin/
# Usage: toggle-profile.sh (or bind to a key)

set -e

THEMES_DIR="$HOME/.config/themes"
CONFIG_WAYBAR="$HOME/.config/waybar/style.css"
CONFIG_WLOGOUT="$HOME/.config/wlogout/nova.css"
CONFIG_WLOGOUT_COLORS="$HOME/.config/wlogout/colors.css"
CONFIG_KITTY="$HOME/.config/kitty/colors.conf"
CONFIG_HYPRLAND="$HOME/.config/hypr/hyprland/colors.conf"
CONFIG_HYPRLOCK="$HOME/.config/hypr/hyprlock.conf"
CONFIG_FUZZEL="$HOME/.config/fuzzel/fuzzel_theme.ini"
CONFIG_DUNST="$HOME/.config/dunst/dunstrc"
CONFIG_NIRI="$HOME/.config/niri/config.kdl"

# Color profiles available
declare -A PROFILES=(
    ["default"]="Default Profile - Modern, vibrant (green/blue)"
    ["nonchalant-purp"]="Nonchalant Purp - Sophisticated (violet/lime)"
)

# Display profiles in Fuzzel
SELECTION=$(printf '%s\n' "${!PROFILES[@]}" | fuzzel --dmenu --prompt="Select Color Profile: " 2>/dev/null)

if [ -z "$SELECTION" ]; then
    echo "Profile selection cancelled"
    exit 0
fi

echo "Switching to: $SELECTION"

# Get current profile
get_current_profile() {
    if [ -f "$CONFIG_WAYBAR" ]; then
        if grep -q "nonchalant-purp.css" "$CONFIG_WAYBAR" 2>/dev/null; then
            echo "nonchalant-purp"
        else
            echo "default"
        fi
    else
        echo "default"
    fi
}

CURRENT=$(get_current_profile)

if [ "$CURRENT" = "$SELECTION" ]; then
    echo "Already using $SELECTION profile"
    exit 0
fi

# Function to update CSS files
update_css_files() {
    local from_profile=$1
    local to_profile=$2
    
    if [ "$from_profile" = "default" ] && [ "$to_profile" = "nonchalant-purp" ]; then
        if [ -f "$CONFIG_WAYBAR" ]; then
            sed -i 's|global-colors.css|nonchalant-purp.css|g' "$CONFIG_WAYBAR"
        fi
        if [ -f "$CONFIG_WLOGOUT" ]; then
            sed -i 's|global-colors.css|nonchalant-purp.css|g' "$CONFIG_WLOGOUT"
        fi
        if [ -f "$CONFIG_WLOGOUT_COLORS" ]; then
            sed -i 's|global-colors.css|nonchalant-purp.css|g' "$CONFIG_WLOGOUT_COLORS"
        fi
    elif [ "$from_profile" = "nonchalant-purp" ] && [ "$to_profile" = "default" ]; then
        if [ -f "$CONFIG_WAYBAR" ]; then
            sed -i 's|nonchalant-purp.css|global-colors.css|g' "$CONFIG_WAYBAR"
        fi
        if [ -f "$CONFIG_WLOGOUT" ]; then
            sed -i 's|nonchalant-purp.css|global-colors.css|g' "$CONFIG_WLOGOUT"
        fi
        if [ -f "$CONFIG_WLOGOUT_COLORS" ]; then
            sed -i 's|nonchalant-purp.css|global-colors.css|g' "$CONFIG_WLOGOUT_COLORS"
        fi
    fi
}

# Function to update config files with hex values
update_config_files() {
    local to_profile=$1
    
    if [ "$to_profile" = "nonchalant-purp" ]; then
        # Nonchalant Purp colors
        local BG="#1e1e20"
        local FG="#dcd9e7"
        local ACCENT="#c59edc"
        local HIGHLIGHT="#c3fb5b"
        local CAUTION="#ffb86c"
        local URGENT="#ff6e79"
        local TRAY="#2a2a2c"
        local BORDER="#3a3a3d"
    else
        # Default colors
        local BG="#1A1B26"
        local FG="#C0CAF5"
        local ACCENT="#9ECE6A"
        local HIGHLIGHT="#7AA2F7"
        local CAUTION="#E0AF68"
        local URGENT="#F7768E"
        local TRAY="#414868"
        local BORDER="#414868"
    fi
    
    # Update Hyprland colors if exists
    if [ -f "$CONFIG_HYPRLAND" ]; then
        sed -i "s/col\.active_border = rgba([^)]*)/col.active_border = rgba(${HIGHLIGHT:1}AA)/g" "$CONFIG_HYPRLAND"
        sed -i "s/col\.inactive_border = rgba([^)]*)/col.inactive_border = rgba(${BORDER:1}AA)/g" "$CONFIG_HYPRLAND"
    fi
    
    # Note: Full config updates would require more complex replacements
    # For now, users can manually update or refer to documentation
}

# Perform the update
update_css_files "$CURRENT" "$SELECTION"
update_config_files "$SELECTION"

# Notify user of success
notify-send "Color Profile Switched" "Changed from $CURRENT to $SELECTION\n\nSome apps may need to be reloaded:\nkillall waybar && waybar &" -t 5000

# Try to reload Waybar if running
if command -v waybar &> /dev/null && pgrep -x waybar > /dev/null; then
    killall waybar 2>/dev/null || true
    sleep 0.5
    waybar &
fi

echo "Profile switched successfully!"
echo ""
echo "To reload other applications manually:"
echo "  killall hyprlock  # Lock screen will restart on next lock"
echo "  pkill -f 'wlogout' # Logout menu"
echo "  killall fuzzel  # App launcher"
echo "  killall dunst  # Notifications"

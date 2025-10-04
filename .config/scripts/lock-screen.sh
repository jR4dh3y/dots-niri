#!/usr/bin/env 

HYPRLOCK_DYNAMIC="${HOME}/.config/hypr/hyprlock.conf"SWAYLOCK_STATIC="${HOME}/.config/swaylock/config-static"

HYPRLOCK_STATIC="${HOME}/.config/hypr/hyprlock-static.conf"

# Check current theme mode

# Check if hyprlock is installedif [ -f "$THEME_FILE" ]; then

if ! command -v hyprlock &> /dev/null; then    CURRENT_THEME=$(cat "$THEME_FILE")

    notify-send "Lock Screen" "hyprlock not installed!\nInstall with: pacman -S hyprlock" -u criticalelse

    exit 1    CURRENT_THEME="dynamic"

fi



# Use appropriate hyprlock config        swaylock

if [ "$CURRENT_THEME" == "dynamic" ]; then    fi

    # Use wallust-generated config with wallpaper colorselse

    if [ -f "$HYPRLOCK_DYNAMIC" ]; then    # Use static theme config

        hyprlock --config "$HYPRLOCK_DYNAMIC"    if [ -f "$SWAYLOCK_STATIC" ]; then

    else        swaylock -C "$SWAYLOCK_STATIC"

        echo "Warning: Dynamic config not found at $HYPRLOCK_DYNAMIC"    else

        echo "Generating colors from current wallpaper..."        echo "Warning: Static config not found, using default"

                swaylock

        # Try to get current wallpaper and generate colors    fi

        CURRENT_WALLPAPER=$(cat ~/.cache/wallpaper 2>/dev/null)fi

        if [ -n "$CURRENT_WALLPAPER" ] && [ -f "$CURRENT_WALLPAPER" ]; then
            wallust run "$CURRENT_WALLPAPER"
            sleep 0.5
        fi
        
        # Try again with generated config
        if [ -f "$HYPRLOCK_DYNAMIC" ]; then
            hyprlock --config "$HYPRLOCK_DYNAMIC"
        else
            echo "Error: Could not generate dynamic config, using default"
            hyprlock
        fi
    fi
else
    # Use static theme config
    if [ -f "$HYPRLOCK_STATIC" ]; then
        hyprlock --config "$HYPRLOCK_STATIC"
    else
        echo "Warning: Static config not found at $HYPRLOCK_STATIC"
        echo "Creating static config..."
        
        # Create static config if it doesn't exist
        mkdir -p "$(dirname "$HYPRLOCK_STATIC")"
        cat > "$HYPRLOCK_STATIC" << 'EOF'
# Hyprlock Static Configuration - Beautiful Tokyo Night Theme
# Dimmed and blurred background with elegant input field

general {
    grace = 2
    hide_cursor = true
    ignore_empty_input = true
}

background {
    monitor =
    path = screenshot
    blur_size = 8
    blur_passes = 3
    brightness = 0.4
    contrast = 1.0
    vibrancy = 0.3
    vibrancy_darkness = 0.6
}

# Main input field
input-field {
    monitor =
    size = 350, 60
    outline_thickness = 3
    dots_size = 0.25
    dots_spacing = 0.35
    dots_center = true
    dots_rounding = -1
    outer_color = rgba(122, 162, 247, 1.0)
    inner_color = rgba(26, 27, 38, 0.6)
    font_color = rgb(192, 202, 245)
    fade_on_empty = false
    fade_timeout = 2000
    placeholder_text = <span foreground="##7aa2f7"><i>󰌾 Enter Password</i></span>
    hide_input = false
    check_color = rgba(158, 206, 106, 1.0)
    fail_color = rgba(247, 118, 142, 1.0)
    fail_text = <span foreground="##f7768e"><i>$FAIL ($ATTEMPTS)</i></span>
    capslock_color = rgba(224, 175, 104, 1.0)
    position = 0, -150
    halign = center
    valign = center
}

# Clock
label {
    monitor =
    text = cmd[update:1000] echo "<span foreground='##c0caf5'>$(date +"%H:%M:%S")</span>"
    color = rgba(192, 202, 245, 1.0)
    font_size = 90
    font_family = JetBrainsMono Nerd Font Bold
    position = 0, 250
    halign = center
    valign = center
    shadow_passes = 2
    shadow_size = 3
    shadow_color = rgba(0, 0, 0, 0.5)
}

# Date
label {
    monitor =
    text = cmd[update:1000] echo "<span foreground='##7aa2f7'>$(date +"%A, %B %d, %Y")</span>"
    color = rgba(122, 162, 247, 1.0)
    font_size = 22
    font_family = JetBrainsMono Nerd Font
    position = 0, 150
    halign = center
    valign = center
    shadow_passes = 2
    shadow_size = 3
}

# User info
label {
    monitor =
    text =   $USER
    color = rgba(192, 202, 245, 0.8)
    font_size = 16
    font_family = JetBrainsMono Nerd Font
    position = 0, -240
    halign = center
    valign = center
}

# Lock icon
label {
    monitor =
    text = 󰌾
    color = rgba(122, 162, 247, 0.8)
    font_size = 40
    font_family = JetBrainsMono Nerd Font
    position = 0, 50
    halign = center
    valign = center
    shadow_passes = 2
}

# Status/hint text
label {
    monitor =
    text = Press any key to unlock
    color = rgba(192, 202, 245, 0.5)
    font_size = 12
    font_family = JetBrainsMono Nerd Font
    position = 0, -300
    halign = center
    valign = center
}

# Battery status (if available)
label {
    monitor =
    text = cmd[update:5000] if command -v acpi &> /dev/null; then echo "  $(acpi -b | grep -oP '\d+(?=%)' | head -1)%"; fi
    color = rgba(158, 206, 106, 0.8)
    font_size = 14
    font_family = JetBrainsMono Nerd Font
    position = 30, 30
    halign = left
    valign = bottom
}

# Network status
label {
    monitor =
    text = cmd[update:5000] if command -v nmcli &> /dev/null; then nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2 | head -1 | awk '{if($0) print "  " $0; else print "  Disconnected"}'; else echo ""; fi
    color = rgba(125, 207, 255, 0.8)
    font_size = 14
    font_family = JetBrainsMono Nerd Font
    position = -30, 30
    halign = right
    valign = bottom
}
EOF
        
        hyprlock --config "$HYPRLOCK_STATIC"
    fi
fi

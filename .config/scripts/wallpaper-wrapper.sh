#!/usr/bin/env bash

# Simple wrapper for your wallpaper script with theme mode support
# This integrates your existing ~/.local/bin/wallpaper script with theme switching

WALLPAPER_BIN="${HOME}/.local/bin/wallpaper"
THEME_FILE="${HOME}/.config/.current_theme"
WALLUST_OUTPUT="${HOME}/.config/themes/colors-waybar-dynamic.css"
THEME_LINK="${HOME}/.config/themes/colors-waybar.css"

# Get current theme mode (default to dynamic)
if [ -f "$THEME_FILE" ]; then
    CURRENT_MODE=$(cat "$THEME_FILE")
else
    CURRENT_MODE="dynamic"
    echo "dynamic" > "$THEME_FILE"
fi

# Function to reload waybar
reload_waybar() {
    pkill -SIGUSR2 waybar 2>/dev/null
    sleep 0.3
    if ! pgrep -x waybar > /dev/null; then
        waybar &
    fi
}

# Parse arguments
WALLPAPER_ARGS=()
for arg in "$@"; do
    WALLPAPER_ARGS+=("$arg")
done

# Run your existing wallpaper script (it handles wallust color generation)
if [ -x "$WALLPAPER_BIN" ]; then
    "$WALLPAPER_BIN" "${WALLPAPER_ARGS[@]}"
    
    # If in dynamic mode, link the generated colors
    if [ "$CURRENT_MODE" == "dynamic" ]; then
        sleep 0.5  # Wait for wallust to finish
        if [ -f "$WALLUST_OUTPUT" ]; then
            ln -sf "$WALLUST_OUTPUT" "$THEME_LINK"
        fi
        reload_waybar
    fi
else
    echo "Error: Wallpaper script not found: $WALLPAPER_BIN"
    exit 1
fi

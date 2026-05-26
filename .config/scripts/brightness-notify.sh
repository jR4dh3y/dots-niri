#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICON_DIR="$(dirname "$SCRIPT_DIR")/dunst/icons"
APP_NAME="Brightness"
ID=9995

# Perform the brightness action
if [[ "$1" == "up" ]]; then
    brightnessctl set "${2:-+5%}"
elif [[ "$1" == "down" ]]; then
    brightnessctl set "${2:-5%-}"
fi

# Get current brightness percentage
brightness=$(brightnessctl -m | awk -F',' '{print $4}' | tr -d '%')
brightness=${brightness%.*}

icon="${ICON_DIR}/brightness.svg"
body="${brightness}%"

if command -v dunstify >/dev/null 2>&1; then
    dunstify -a "$APP_NAME" -u low -i "$icon" -r "$ID" "$APP_NAME" "$body"
else
    notify-send -a "$APP_NAME" -u low -i "$icon" "$APP_NAME" "$body"
fi

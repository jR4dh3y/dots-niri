#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICON_DIR="$(dirname "$SCRIPT_DIR")/dunst/icons"
APP_NAME="Volume"
ID=9993

# Perform the volume action
if [[ "$1" == "mute" ]]; then
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
elif [[ "$1" == "mic-mute" ]]; then
    wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
    APP_NAME="Microphone"
    ID=9994
elif [[ "$1" == "up" ]]; then
    wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ "${2:-0.05+}"
elif [[ "$1" == "down" ]]; then
    wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ "${2:-0.05-}"
fi

# Get current volume info
if [[ "$1" == "mic-mute" ]]; then
    info=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)
else
    info=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
fi

# Parse volume and mute status
volume=$(echo "$info" | awk '{print $2 * 100}')
volume=${volume%.*}
mute=$(echo "$info" | grep -o '\[MUTED\]' || true)

if [[ -n "$mute" ]]; then
    icon="${ICON_DIR}/volume-muted.svg"
    body="Muted"
    volume=0
else
    if (( volume == 0 )); then
        icon="${ICON_DIR}/volume-muted.svg"
    elif (( volume < 34 )); then
        icon="${ICON_DIR}/volume-low.svg"
    elif (( volume < 67 )); then
        icon="${ICON_DIR}/volume-medium.svg"
    else
        icon="${ICON_DIR}/volume-high.svg"
    fi
    body="${volume}%"
fi

if command -v dunstify >/dev/null 2>&1; then
    dunstify -a "$APP_NAME" -u low -i "$icon" -r "$ID" "$APP_NAME" "$body"
else
    notify-send -a "$APP_NAME" -u low -i "$icon" "$APP_NAME" "$body"
fi

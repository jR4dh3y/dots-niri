#!/usr/bin/env bash

TEMP_FILE="$HOME/.config/waybar/nightlight-temp"
DEFAULT_TEMP=4500
MIN_TEMP=2000
MAX_TEMP=6500
STEP=250

# Ensure the config directory exists
mkdir -p "$(dirname "$TEMP_FILE")"

get_current_temp() {
    busctl --user get-property rs.wl-gammarelay / rs.wl.gammarelay Temperature | awk '{print $2}'
}

set_temp() {
    local t=$1
    busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Temperature q "$t"
}

send_notification() {
    local t=$1
    local status=$2
    if [ "$status" = "active" ]; then
        if [ "$t" -ge 6500 ]; then
            notify-send -r 9988 -t 1500 -i preferences-desktop-display-color "Nightlight" "Neutral (6500K)"
        else
            notify-send -r 9988 -t 1500 -i preferences-desktop-display-color "Nightlight" "Temperature: ${t}K"
        fi
    else
        notify-send -r 9988 -t 1500 -i preferences-desktop-display-color "Nightlight" "Disabled"
    fi
}

case "$1" in
    watch)
        wl-gammarelay-rs watch "{t}" | while read -r temp; do
            if [ -z "$temp" ] || ! [[ "$temp" =~ ^[0-9]+$ ]]; then
                continue
            fi
            if [ "$temp" -eq 6500 ]; then
                echo "{\"text\": \"\", \"class\": \"deactivated\", \"tooltip\": \"Nightlight: Inactive\"}"
            else
                echo "{\"text\": \"\", \"class\": \"activated\", \"tooltip\": \"Nightlight: Active (${temp}K)\"}"
            fi
        done
        ;;
    toggle)
        CURRENT_TEMP=$(get_current_temp)
        if [ -n "$CURRENT_TEMP" ] && [ "$CURRENT_TEMP" -lt 6500 ]; then
            echo "$CURRENT_TEMP" > "$TEMP_FILE"
            set_temp 6500
            send_notification 6500 "inactive"
        else
            SAVED_TEMP=$(cat "$TEMP_FILE" 2>/dev/null || echo "$DEFAULT_TEMP")
            if [ "$SAVED_TEMP" -ge 6500 ] || ! [[ "$SAVED_TEMP" =~ ^[0-9]+$ ]]; then
                SAVED_TEMP=$DEFAULT_TEMP
            fi
            set_temp "$SAVED_TEMP"
            send_notification "$SAVED_TEMP" "active"
        fi
        ;;
    up)
        CURRENT_TEMP=$(get_current_temp)
        if [ -n "$CURRENT_TEMP" ]; then
            NEW_TEMP=$((CURRENT_TEMP + STEP))
            if [ "$NEW_TEMP" -gt "$MAX_TEMP" ]; then
                NEW_TEMP=$MAX_TEMP
            fi
            set_temp "$NEW_TEMP"
            if [ "$NEW_TEMP" -lt 6500 ]; then
                echo "$NEW_TEMP" > "$TEMP_FILE"
                send_notification "$NEW_TEMP" "active"
            else
                send_notification "$NEW_TEMP" "inactive"
            fi
        fi
        ;;
    down)
        CURRENT_TEMP=$(get_current_temp)
        if [ -n "$CURRENT_TEMP" ]; then
            NEW_TEMP=$((CURRENT_TEMP - STEP))
            if [ "$NEW_TEMP" -lt "$MIN_TEMP" ]; then
                NEW_TEMP=$MIN_TEMP
            fi
            set_temp "$NEW_TEMP"
            echo "$NEW_TEMP" > "$TEMP_FILE"
            send_notification "$NEW_TEMP" "active"
        fi
        ;;
    *)
        echo "Usage: $0 {watch|toggle|up|down}"
        exit 1
        ;;
esac

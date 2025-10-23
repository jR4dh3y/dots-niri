#!/bin/bash
# Toggle Color Profile with Fuzzel Menu
# Properly switches ALL applications to the selected profile

THEMES_DIR="$HOME/.config/themes"
PROFILES=($(ls "$THEMES_DIR"/*.css 2>/dev/null | xargs -n1 basename | sed 's/.css//'))

if [ ${#PROFILES[@]} -eq 0 ]; then
    notify-send "❌ No color profiles found" "$THEMES_DIR/*.css"
    exit 1
fi

# Try fuzzel first, fall back to dmenu or menu
if command -v fuzzel &> /dev/null; then
    SELECTED=$(printf '%s\n' "${PROFILES[@]}" | fuzzel -d)
elif command -v dmenu &> /dev/null; then
    SELECTED=$(printf '%s\n' "${PROFILES[@]}" | dmenu -p "Select color profile:")
else
    echo "Available profiles:"
    select SELECTED in "${PROFILES[@]}"; do
        break
    done
fi

if [ -z "$SELECTED" ]; then
    exit 0
fi

# Apply the profile
"$THEMES_DIR/apply-profile.sh" "$SELECTED"

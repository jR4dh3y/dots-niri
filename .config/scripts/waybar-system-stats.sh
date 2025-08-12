#!/bin/bash

STATE_FILE="/tmp/waybar-system-stats-state"

# Check if stats are shown or hidden
if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "shown" ]; then
    # Stats are currently shown - show collapse icon
    echo '{"text":"", "tooltip":"Click to hide system stats", "class":"expanded"}'
else
    # Stats are currently hidden - show expand icon
    echo '{"text":"", "tooltip":"Click to show system stats", "class":"collapsed"}'
fi

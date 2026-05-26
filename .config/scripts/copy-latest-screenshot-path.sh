#!/usr/bin/env bash

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"

if [ ! -d "$SCREENSHOT_DIR" ]; then
    notify-send -u critical "Screenshot Path" "Screenshot directory not found: $SCREENSHOT_DIR"
    exit 1
fi

# Get the most recently modified file (handles both niri and grimblast naming)
LATEST=$(ls -t "$SCREENSHOT_DIR" | head -n 1)

if [ -z "$LATEST" ]; then
    notify-send -u critical "Screenshot Path" "No screenshots found in $SCREENSHOT_DIR"
    exit 1
fi

FULLPATH="$SCREENSHOT_DIR/$LATEST"

# Copy to clipboard
echo -n "$FULLPATH" | wl-copy

# Notify
notify-send "Screenshot Path Copied" "$FULLPATH"

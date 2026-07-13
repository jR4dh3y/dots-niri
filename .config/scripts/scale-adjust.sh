#!/usr/bin/env bash
# Adjust the scale factor of the focused output by +/- 0.05.
# Usage: scale-adjust.sh +0.05   # increase
#        scale-adjust.sh -0.05   # decrease

set -euo pipefail

log=/tmp/scale-adjust.log
delta="${1:?usage: scale-adjust.sh <+/-delta>}"

echo "[$(date)] delta=$delta" >> "$log"

# Get focused output JSON
output_json=$(niri msg -j focused-output)
name=$(echo "$output_json" | jq -r '.name')
current_scale=$(echo "$output_json" | jq -r '.logical.scale')

echo "[$(date)] output=$name current_scale=$current_scale" >> "$log"

# Convert to hundredths for integer math
current_hundredths=$(echo "$current_scale" | awk '{printf "%.0f", $1 * 100}')
delta_hundredths=$(echo "$delta" | awk '{printf "%.0f", $1 * 100}')

echo "[$(date)] current_hundredths=$current_hundredths delta_hundredths=$delta_hundredths" >> "$log"

# Add/subtract and clamp
new_hundredths=$((current_hundredths + delta_hundredths))
if ((new_hundredths < 50)); then
    new_hundredths=50
elif ((new_hundredths > 300)); then
    new_hundredths=300
fi

# Convert back to float with 2 decimal places
new_scale=$(awk -v n="$new_hundredths" 'BEGIN { printf "%.2f", n / 100 }')

echo "[$(date)] new_hundredths=$new_hundredths new_scale=$new_scale" >> "$log"

notify-send "Scale" "$new_scale"
niri msg output "$name" scale "$new_scale"
echo "[$(date)] done" >> "$log"

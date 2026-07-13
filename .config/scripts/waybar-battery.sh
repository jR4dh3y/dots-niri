#!/usr/bin/env bash

set -euo pipefail

read_battery_value() {
    cat "$1" 2>/dev/null | head -1 || true
}

battery_icon() {
    local capacity=$1
    local status=$2

    if [ "$status" = "Charging" ]; then
        printf ''
        return
    fi

    if [ "$status" = "Full" ] || [ "$capacity" -ge 95 ]; then
        printf '󰁹'
    elif [ "$capacity" -ge 90 ]; then
        printf '󰂂'
    elif [ "$capacity" -ge 80 ]; then
        printf '󰂁'
    elif [ "$capacity" -ge 70 ]; then
        printf '󰂀'
    elif [ "$capacity" -ge 60 ]; then
        printf '󰁿'
    elif [ "$capacity" -ge 50 ]; then
        printf '󰁾'
    elif [ "$capacity" -ge 40 ]; then
        printf '󰁽'
    elif [ "$capacity" -ge 30 ]; then
        printf '󰁼'
    elif [ "$capacity" -ge 20 ]; then
        printf '󰁻'
    else
        printf '󰁺'
    fi
}

capacity=$(read_battery_value /sys/class/power_supply/BAT*/capacity)
status=$(read_battery_value /sys/class/power_supply/BAT*/status)
voltage_uv=$(read_battery_value /sys/class/power_supply/BAT*/voltage_now)
energy_now=$(read_battery_value /sys/class/power_supply/BAT*/energy_now)
energy_full=$(read_battery_value /sys/class/power_supply/BAT*/energy_full)
voltage=$(awk -v v="${voltage_uv:-0}" 'BEGIN { printf "%.2f", v / 1000000 }')
energy_wh=$(awk -v e="${energy_now:-0}" 'BEGIN { printf "%.2f", e / 1000000 }')
energy_full_wh=$(awk -v e="${energy_full:-0}" 'BEGIN { printf "%.2f", e / 1000000 }')
capacity_line="Capacity: ${energy_wh} / ${energy_full_wh} Wh"
voltage_line="Voltage: ${voltage} V"

# Compute power draw from energy_now changes (no root needed)
power_line=""
cache="/tmp/waybar-battery-power.cache"
if [ -n "${energy_now:-}" ] && [ -f "$cache" ]; then
    read -r prev_energy prev_ts < "$cache" 2>/dev/null || true
    if [ -n "${prev_energy:-}" ] && [ -n "${prev_ts:-}" ] && [ "$energy_now" -lt "$prev_energy" ] 2>/dev/null; then
        now=$(date +%s%N)
        dt=$(awk -v now="$now" -v prev="$prev_ts" 'BEGIN { printf "%.0f", (now - prev) }')
        if [ "$dt" -gt 1000000000 ] 2>/dev/null; then
            e_delta=$((prev_energy - energy_now))
            power_w=$(awk -v e="$e_delta" -v d="$dt" 'BEGIN { printf "%.1f", e * 3600000 / d }')
            power_line="Power: ${power_w} W"
        fi
    fi
fi
echo "$energy_now $(date +%s%N)" > "$cache"

icon=$(battery_icon "$capacity" "$status")
text="$icon $capacity%"
tooltip="Status: ${status}"
tooltip="${tooltip}\nBattery: ${capacity}%"
tooltip="${tooltip}\n${capacity_line}"
if [ -n "$power_line" ]; then
    tooltip="${tooltip}\n${power_line}"
fi
tooltip="${tooltip}\n${voltage_line}"

classes=()
if [ "$status" = "Charging" ] || [ "$status" = "Full" ] || [ "$status" = "Not charging" ]; then
    classes+=(charging)
fi
if [ "$status" = "Full" ] || [ "$capacity" -ge 95 ]; then
    classes+=(full)
elif [ "$capacity" -le 10 ]; then
    classes+=(critical)
elif [ "$capacity" -le 20 ]; then
    classes+=(warning)
fi

python3 - "$text" "$tooltip" "$status" "$capacity" "${classes[*]:-}" <<'PY'
import json
import sys

text, tooltip, status, capacity, class_names = sys.argv[1:6]
tooltip = tooltip.replace("\\n", "\n")
payload = {
    "text": text,
    "tooltip": tooltip,
    "alt": status.lower(),
    "percentage": int(capacity),
}
if class_names:
    payload["class"] = class_names.split()
print(json.dumps(payload))
PY

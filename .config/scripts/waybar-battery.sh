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
power_uw=$(read_battery_value /sys/class/power_supply/BAT*/power_now)
power=$(awk -v value="${power_uw:-0}" 'BEGIN { printf "%.2f", value / 1000000 }')

time="N/A"

if [ "$status" = "Discharging" ] && [ -n "${power_uw:-}" ] && [ "$power_uw" -gt 0 ]; then
    energy=$(read_battery_value /sys/class/power_supply/BAT*/energy_now)
    if [ -z "$energy" ]; then
        energy=$(read_battery_value /sys/class/power_supply/BAT*/charge_now)
        if [ -n "$energy" ]; then
            voltage=$(read_battery_value /sys/class/power_supply/BAT*/voltage_now)
            if [ -n "$voltage" ]; then
                energy=$((energy * voltage / 1000000))
            fi
        fi
    fi

    if [ -n "$energy" ] && [ "$energy" -gt 0 ]; then
        time=$(awk -v e="$energy" -v p="$power_uw" 'BEGIN {
            hours = e / p
            h = int(hours)
            m = int((hours - h) * 60)
            if (h > 0 || m > 0) {
                printf "%dh %dm", h, m
            } else {
                printf "N/A"
            }
        }')
    fi
fi

capacity=${capacity:-0}
status=${status:-Unknown}
icon=$(battery_icon "$capacity" "$status")
text="$icon $capacity%"
tooltip=$(printf 'Status: %s
Power: %s W
Time: %s' "$status" "$power" "$time")

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

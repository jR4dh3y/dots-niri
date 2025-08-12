#!/bin/bash

# Get battery information
capacity=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
status=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)
power=$(cat /sys/class/power_supply/BAT*/power_now 2>/dev/null | awk '{printf "%.2f", $1/1000000}' | head -1)

# Calculate time remaining
time="N/A"

if [ "$status" = "Discharging" ] && [ -n "$power" ] && [ "$power" != "0.00" ]; then
    # Manual calculation
    # Try energy_now first, then charge_now
    energy=$(cat /sys/class/power_supply/BAT*/energy_now 2>/dev/null | head -1)
    if [ -z "$energy" ]; then
        energy=$(cat /sys/class/power_supply/BAT*/charge_now 2>/dev/null | head -1)
        # If using charge_now, also get voltage to convert to energy
        if [ -n "$energy" ]; then
            voltage=$(cat /sys/class/power_supply/BAT*/voltage_now 2>/dev/null | head -1)
            if [ -n "$voltage" ]; then
                energy=$((energy * voltage / 1000000))  # Convert to µWh
            fi
        fi
    fi
    
    if [ -n "$energy" ] && [ "$energy" -gt 0 ]; then
        # Get power in µW
        power_uw=$(cat /sys/class/power_supply/BAT*/power_now 2>/dev/null | head -1)
        if [ -n "$power_uw" ] && [ "$power_uw" -gt 0 ]; then
            time=$(awk -v e="$energy" -v p="$power_uw" 'BEGIN {
                hours = e/p
                h = int(hours)
                m = int((hours - h) * 60)
                if(h > 0 || m > 0) printf "%dh %dm", h, m
            }')
        fi
    fi
fi

# Set defaults if values are empty
capacity=${capacity:-0}
status=${status:-"Unknown"}
power=${power:-"0.00"}
time=${time:-"N/A"}

# Output JSON for waybar
printf '{"capacity":%s,"status":"%s","power":"%s","time":"%s"}' \
    "$capacity" "$status" "$power" "$time"

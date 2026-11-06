#!/usr/bin/env bash
# Waybar Bluetooth right-click: turn Bluetooth on or off.
# rfkill blocks and BlueZ adapter power are separate states. `rfkill toggle`
# alone would block an adapter that was only powered off, so check both.
set -euo pipefail

if rfkill list bluetooth | grep -q "Soft blocked: yes"; then
    rfkill unblock bluetooth
    # The adapter takes a moment to come back after the unblock, and BlueZ
    # rejects power-on until it does; retry for up to ~5s.
    for _ in $(seq 1 20); do
        bluetoothctl power on 2>/dev/null | grep -q "succeeded" && exit 0
        sleep 0.25
    done
    exec bluetoothctl power on
fi

if bluetoothctl show | grep -q "Powered: yes"; then
    exec bluetoothctl power off
fi
exec bluetoothctl power on

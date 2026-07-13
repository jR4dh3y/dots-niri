#!/usr/bin/env bash

set -euo pipefail

GPU="0000:01:00.0"
AUDIO="0000:01:00.1"
VM="win10-rtx3050"
SIGNAL=9

driver_for() {
    local dev=$1
    if [[ -L "/sys/bus/pci/devices/$dev/driver" ]]; then
        basename "$(readlink -f "/sys/bus/pci/devices/$dev/driver")"
    else
        printf 'none'
    fi
}

vm_state() {
    if command -v virsh >/dev/null 2>&1; then
        virsh -c qemu:///system domstate "$VM" 2>/dev/null || printf 'missing'
    else
        printf 'virsh missing'
    fi
}

notify() {
    local title=$1
    local body=${2:-}
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$title" "$body"
    fi
}

refresh_waybar() {
    pkill -RTMIN+"$SIGNAL" waybar 2>/dev/null || true
}

wait_for_vm_shutdown() {
    local timeout=${1:-180}
    local elapsed=0
    local state

    while (( elapsed < timeout )); do
        state=$(vm_state)
        case "$state" in
            "shut off"|"missing")
                refresh_waybar
                return 0
                ;;
        esac
        sleep 2
        elapsed=$((elapsed + 2))
    done

    notify "Windows VM is still running" "Shut it down fully before switching the RTX back to Linux."
    refresh_waybar
    return 1
}

emit_json() {
    local text=$1
    local tooltip=$2
    local class_name=$3
    local percentage=${4:-0}

    python3 - "$text" "$tooltip" "$class_name" "$percentage" <<'PY'
import json
import sys

text, tooltip, class_name, percentage = sys.argv[1:5]
payload = {
    "text": text,
    "tooltip": tooltip,
    "class": class_name,
    "percentage": int(percentage),
}
print(json.dumps(payload))
PY
}

status() {
    local gpu_driver audio_driver state text class_name tooltip percentage vm_action

    gpu_driver=$(driver_for "$GPU")
    audio_driver=$(driver_for "$AUDIO")
    state=$(vm_state)
    percentage=0
    vm_action="Start Windows VM"

    case "$gpu_driver:$state" in
        nvidia:*)
            text="󰢮 PRIME"
            class_name="prime"
            percentage=100
            ;;
        vfio-pci:running|vfio-pci:paused)
            text="󰍹 Shutdown"
            class_name="vm-running"
            percentage=60
            vm_action="Shutdown Windows VM"
            ;;
        vfio-pci:*)
            text="󰌾 Start"
            class_name="vfio"
            percentage=40
            ;;
        *)
            text="󰘚 GPU"
            class_name="unknown"
            ;;
    esac

    tooltip=$(printf 'GPU: %s\nAudio: %s\nVM: %s\n\nLeft: menu\nRight: Linux PRIME\nMiddle: %s' \
        "$gpu_driver" "$audio_driver" "$state" "$vm_action")
    emit_json "$text" "$tooltip" "$class_name" "$percentage"
}

run_with_notice() {
    local title=$1
    shift
    local output

    if output=$("$@" 2>&1); then
        notify "$title" "$output"
        refresh_waybar
        return 0
    fi

    notify "$title failed" "$output"
    refresh_waybar
    return 1
}

run_root() {
    if command -v pkexec >/dev/null 2>&1; then
        run_with_notice "$1" pkexec "${@:2}"
        return
    fi

    notify "GPU switch failed" "pkexec is not installed; run the switch command from a terminal."
    return 1
}

to_linux() {
    local state
    state=$(vm_state)
    if [[ "$state" == "running" || "$state" == "paused" ]]; then
        notify "Windows VM is $state" "Requesting shutdown before switching the RTX to Linux."
        virsh -c qemu:///system shutdown "$VM" >/dev/null 2>&1 || true
        wait_for_vm_shutdown 180 || return 1
    fi

    run_root "GPU switched to Linux" /usr/local/sbin/gpu-to-nvidia
}

to_windows() {
    local gpu_driver
    gpu_driver=$(driver_for "$GPU")

    if [[ "$gpu_driver" != "vfio-pci" ]]; then
        run_root "GPU switched to VFIO" /usr/local/sbin/gpu-to-vfio || return 1
    fi

    local state
    state=$(vm_state)
    if [[ "$state" == "shut off" ]]; then
        run_with_notice "Windows VM started" virsh -c qemu:///system start "$VM" || true
    else
        refresh_waybar
    fi
}

shutdown_vm() {
    run_with_notice "Windows VM shutdown requested" virsh -c qemu:///system shutdown "$VM"
}

toggle_vm() {
    local state
    state=$(vm_state)

    case "$state" in
        running|paused)
            shutdown_vm
            ;;
        "shut off")
            to_windows
            ;;
        *)
            notify "Windows VM state unknown" "$state"
            refresh_waybar
            return 1
            ;;
    esac
}

open_looking_glass() {
    if command -v looking-glass-client >/dev/null 2>&1; then
        looking-glass-client \
            -F \
            app:shmFile=/dev/shm/looking-glass \
            spice:host=127.0.0.1 \
            spice:port=5900 \
            spice:input=yes \
            spice:clipboard=yes \
            spice:captureOnStart=yes \
            input:captureOnFocus=yes \
            input:escapeKey=KEY_RIGHTCTRL >/dev/null 2>&1 &
    else
        notify "Looking Glass unavailable" "Install the looking-glass package first."
        return 1
    fi
}

open_status_terminal() {
    if command -v kitty >/dev/null 2>&1; then
        kitty --app-id=sysadmin --title="GPU switch status" sh -lc 'gpu-status; printf "\nPress Enter to close..."; read -r _' &
    else
        notify "GPU status" "$(gpu-status 2>&1)"
    fi
}

menu() {
    local launcher choice state vm_action
    if command -v fuzzel >/dev/null 2>&1; then
        launcher=(fuzzel --dmenu --prompt="GPU: ")
    elif command -v wofi >/dev/null 2>&1; then
        launcher=(wofi --dmenu --prompt "GPU")
    else
        notify "GPU menu unavailable" "Install fuzzel or wofi, or use right/middle click."
        return 1
    fi

    state=$(vm_state)
    if [[ "$state" == "running" || "$state" == "paused" ]]; then
        vm_action="Shutdown Windows VM"
    else
        vm_action="Start Windows VM"
    fi

    choice=$(printf '%s\n' \
        "Linux PRIME" \
        "$vm_action" \
        "Open Looking Glass" \
        "Open virt-manager" \
        "Status" | "${launcher[@]}") || return 0

    case "$choice" in
        "Linux PRIME") to_linux ;;
        "Start Windows VM") to_windows ;;
        "Shutdown Windows VM") shutdown_vm ;;
        "Open Looking Glass") open_looking_glass ;;
        "Open virt-manager") virt-manager >/dev/null 2>&1 & ;;
        "Status") open_status_terminal ;;
    esac
}

case "${1:-status}" in
    status) status ;;
    menu) menu ;;
    to-linux) to_linux ;;
    to-windows) to_windows ;;
    toggle-vm) toggle_vm ;;
    shutdown-vm) shutdown_vm ;;
    *) printf 'Usage: %s [status|menu|to-linux|to-windows|toggle-vm|shutdown-vm]\n' "$0" >&2; exit 2 ;;
esac

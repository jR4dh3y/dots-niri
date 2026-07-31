#!/usr/bin/env bash
set -euo pipefail

GPU_PCI="0000:01:00.0"
GPU_SYS="/sys/bus/pci/devices/$GPU_PCI"

json() {
    local text="$1"
    local tooltip="$2"
    local class_name="${3:-}"

    printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
        "$text" \
        "${tooltip//$'\n'/\\n}" \
        "$class_name"
}

driver_for_gpu() {
    if [[ -L "$GPU_SYS/driver" ]]; then
        basename "$(readlink -f "$GPU_SYS/driver")"
        return 0
    fi

    printf 'none\n'
}

if [[ ! -d "$GPU_SYS" ]]; then
    json "MISSING" "RTX GPU PCI device was not found at $GPU_PCI" "missing"
    exit 0
fi

driver="$(driver_for_gpu)"

case "$driver" in
    none)
        json "OFF" "RTX GPU is not bound to a Linux driver" "off"
        exit 0
        ;;
esac

if ! command -v nvidia-smi >/dev/null 2>&1; then
    json "NO SMI" "nvidia-smi is not installed or not in PATH" "error"
    exit 0
fi

if ! stats="$(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw --format=csv,noheader,nounits 2>/dev/null | head -n 1)"; then
    json "DRIVER" "RTX GPU driver is $driver, but nvidia-smi failed" "error"
    exit 0
fi

if [[ -z "$stats" ]]; then
    json "DRIVER" "RTX GPU driver is $driver, but nvidia-smi returned no data" "error"
    exit 0
fi

IFS=',' read -r usage mem_used mem_total temp power <<< "$stats"
usage="${usage//[[:space:]]/}"
mem_used="${mem_used//[[:space:]]/}"
mem_total="${mem_total//[[:space:]]/}"
temp="${temp//[[:space:]]/}"
power="${power//[[:space:]]/}"

json "${usage}%" "GPU: ${usage}%\nMemory: ${mem_used}/${mem_total} MB\nTemperature: ${temp}C\nPower: ${power}W" "prime"

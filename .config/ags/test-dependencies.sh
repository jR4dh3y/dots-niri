#!/bin/bash

# AGS Dashboard Dependencies Test
# This script checks if all required dependencies are available

echo "AGS Dashboard Dependencies Test"
echo "==============================="
echo

# Function to check command availability
check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        echo "✓ $1 - Available"
        return 0
    else
        echo "✗ $1 - Not found"
        return 1
    fi
}

# Function to test command output
test_command() {
    echo "Testing: $2"
    if eval "$1" >/dev/null 2>&1; then
        echo "✓ $2 - Working"
        echo "  Output: $(eval "$1" 2>/dev/null | head -1)"
    else
        echo "✗ $2 - Failed"
    fi
    echo
}

# Core dependencies
echo "Core Dependencies:"
check_command "ags"
check_command "pactl"
check_command "brightnessctl"
echo

# Media dependencies
echo "Media Dependencies:"
check_command "playerctl"
echo

# System monitoring
echo "System Monitoring:"
check_command "sensors"
check_command "nvidia-smi"
echo

# Network
echo "Network Dependencies:"
check_command "nmcli"
check_command "ip"
echo

# Notifications
echo "Notification Dependencies:"
check_command "dunstctl"
check_command "makoctl"
echo

# Test actual functionality
echo "Functionality Tests:"
echo "===================="

test_command "pactl get-sink-volume @DEFAULT_SINK@" "PulseAudio volume"
test_command "brightnessctl get" "Brightness control"
test_command "playerctl status" "Media player status"
test_command "sensors | head -5" "Temperature sensors"
test_command "nmcli -t -f NAME c show --active | head -1" "Network connection"
test_command "ip route get 1.1.1.1 | grep -oP 'src \\K\\S+'" "IP address detection"
test_command "top -bn1 | grep 'Cpu(s)'" "CPU usage"
test_command "free | grep Mem" "Memory usage"

echo "Test completed!"
echo
echo "Note: Some failures are expected if you don't have specific hardware"
echo "(e.g., NVIDIA GPU, battery, certain notification daemons)"

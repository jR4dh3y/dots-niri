#!/bin/bash

# AGS Dashboard Launcher
# Usage: ./launch-ags.sh [toggle|restart|stop|status]

AGS_CONFIG_DIR="$HOME/.config/ags"

case "$1" in
    "toggle")
        # Toggle the dashboard
        if pgrep -x "ags" > /dev/null; then
            ags toggle dashboard
        else
            echo "AGS is not running. Starting AGS first..."
            cd "$AGS_CONFIG_DIR" && ags run . &
            sleep 2
            ags toggle dashboard
        fi
        ;;
    "restart")
        # Restart AGS
        echo "Restarting AGS..."
        pkill ags
        sleep 1
        cd "$AGS_CONFIG_DIR" && ags run . &
        echo "AGS restarted"
        ;;
    "stop")
        # Stop AGS
        echo "Stopping AGS..."
        pkill ags
        echo "AGS stopped"
        ;;
    "status")
        # Check AGS status
        if pgrep -x "ags" > /dev/null; then
            echo "AGS is running (PID: $(pgrep -x ags))"
        else
            echo "AGS is not running"
        fi
        ;;
    *)
        # Start AGS
        if pgrep -x "ags" > /dev/null; then
            echo "AGS is already running (PID: $(pgrep -x ags))"
            echo "Use '$0 toggle' to show/hide dashboard"
        else
            cd "$AGS_CONFIG_DIR" && ags run . &
            echo "AGS started with dashboard support"
            echo "Use 'ags toggle dashboard' or '$0 toggle' to show/hide dashboard"
        fi
        ;;
esac

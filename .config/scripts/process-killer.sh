#!/usr/bin/env bash

# Process Killer - Interactive process manager focused on active apps/windows
# Uses FZF to select and kill processes

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_PATH=$(readlink -f "$0")
export SCRIPT_PATH

# Determine if a PID likely represents a GUI application by checking its FDs
is_gui_process() {
    local pid="$1"
    local fd_dir="/proc/$pid/fd"

    [[ -d "$fd_dir" ]] || return 1

    local old_shopt
    old_shopt=$(shopt -p nullglob 2>/dev/null || true)
    shopt -s nullglob

    for fd in "$fd_dir"/*; do
        local target
        target=$(readlink "$fd" 2>/dev/null) || continue
        if [[ "$target" == *"wayland"* || "$target" == *"X11"* || "$target" == *".X11-unix"* ]]; then
            eval "$old_shopt" 2>/dev/null || true
            return 0
        fi
    done

    eval "$old_shopt" 2>/dev/null || true
    return 1
}

# Fetch windows from niri if available, fallback to GUI-ish processes
get_window_map() {
    local window_map=""

    if command -v niri >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
        window_map=$(
            python3 - 2>/dev/null <<'PYTHON'
import json
import subprocess
import sys

try:
    result = subprocess.run(
        ["niri", "msg", "-j", "windows"],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
    )
except Exception:
    sys.exit(0)

try:
    windows = json.loads(result.stdout)
except Exception:
    sys.exit(0)

seen = set()
for win in windows:
    pid = win.get("pid")
    if pid is None or pid in seen:
        continue
    seen.add(pid)
    if not win.get("mapped", True):
        continue
    name = win.get("title") or win.get("app_id") or f"PID {pid}"
    print(f"{pid}\t{name}")
PYTHON
        )
    fi

    if [[ -n "$window_map" ]]; then
        printf '%s\n' "$window_map"
        return
    fi

    ps -u "$USER" -o pid=,comm= | while read -r pid comm; do
        [[ -n "$pid" && -n "$comm" ]] || continue
        if is_gui_process "$pid"; then
            printf '%s\t%s\n' "$pid" "$comm"
        fi
    done
}

generate_process_lines() {
    local window_map
    window_map=$(get_window_map)

    [[ -n "$window_map" ]] || return 1

    while IFS=$'\t' read -r pid app_name; do
        [[ -n "$pid" ]] || continue
        local stats
        stats=$(ps -p "$pid" -o %cpu=,rss= --no-headers 2>/dev/null)
        [[ -n "$stats" ]] || continue

        local cpu_raw rss_kb
        cpu_raw=$(awk '{print $1}' <<<"$stats")
        rss_kb=$(awk '{print $2}' <<<"$stats")

        [[ -n "$cpu_raw" && -n "$rss_kb" ]] || continue

        local cpu_fmt ram_fmt
        cpu_fmt=$(awk '{printf "%.1f", $1}' <<<"$cpu_raw")
        ram_fmt=$(awk '{printf "%.1f", $1/1024}' <<<"$rss_kb")

        printf '%s\t%s\t%s MiB\t%s%%\n' "$pid" "$app_name" "$ram_fmt" "$cpu_fmt"
    done <<<"$window_map"
}

print_sorted_list() {
    generate_process_lines | sort -t $'\t' -k4,4nr
}

if [[ "$1" == "--print-list" ]]; then
    print_sorted_list
    exit 0
fi

# FZF configuration
fzf_args=(
    --height=100%
    --layout=reverse
    --border=rounded
    --prompt="🔪 Select App to Kill > "
    --header='ENTER:kill | CTRL-R:reload | ESC:cancel'
    --bind 'ctrl-k:execute(kill -9 {1} && notify-send "Process Killer" "Force killed PID {1}" -i process-stop)+reload($SCRIPT_PATH --print-list)'
    --bind 'ctrl-r:reload($SCRIPT_PATH --print-list)'
    --bind 'alt-p:toggle-preview'
    --color='prompt:red,pointer:red,marker:red,header:yellow'
    --multi
    --delimiter=$'\t'
    --with-nth=2,3,4
)

# Get process list with formatted output
# Format: PID USER %CPU %MEM COMMAND
echo -e "${BLUE}Loading open application windows...${NC}"

process_list=$(print_sorted_list)

if [[ -z "$process_list" ]]; then
    echo -e "${YELLOW}No open applications detected for user $USER.${NC}"
    exit 0
fi

selection=$(printf '%s\n' "$process_list" | fzf "${fzf_args[@]}")

if [[ -n "$selection" ]]; then
    # Extract PIDs from selection (can be multiple)
    pids=$(echo "$selection" | awk -F $'\t' '{print $1}')
    
    echo ""
    echo -e "${YELLOW}Selected processes:${NC}"
    echo "$selection" | awk -F $'\t' '{printf "%-30s RAM: %-10s CPU: %s\n", $2, $3, $4}'
    echo ""
    
    # Confirm before killing
    read -p "Kill these process(es) with SIGTERM? (y/N) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        while IFS= read -r pid; do
            process_name=$(ps -p "$pid" -o comm= 2>/dev/null)
            [[ -n "$process_name" ]] || process_name="PID $pid"
            if kill "$pid" 2>/dev/null; then
                echo -e "${GREEN}✓${NC} Killed process $pid ($process_name)"
                notify-send "Process Killer" "Killed: $process_name (PID: $pid)" -i process-stop
            else
                echo -e "${RED}✗${NC} Failed to kill process $pid ($process_name)"
                
                # Try with sudo if regular kill fails
                read -p "Try with sudo? (y/N) " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    if sudo kill "$pid" 2>/dev/null; then
                        echo -e "${GREEN}✓${NC} Killed process $pid with sudo"
                        notify-send "Process Killer" "Killed: $process_name (PID: $pid) with sudo" -i process-stop
                    else
                        echo -e "${RED}✗${NC} Failed to kill process $pid even with sudo"
                        notify-send "Process Killer" "Failed to kill: $process_name (PID: $pid)" -u critical
                    fi
                fi
            fi
        done <<<"$pids"
    else
        echo "Kill cancelled"
    fi
else
    echo "No process selected"
fi

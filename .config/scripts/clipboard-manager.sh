#!/usr/bin/env bash

# Clipboard Manager - View and manage clipboard history
# Requires: cliphist, wl-clipboard, fzf

# Check dependencies
if ! command -v cliphist &> /dev/null; then
    notify-send "Clipboard Manager" "cliphist not installed!\nInstall with: pacman -S cliphist" -u critical
    exit 1
fi

if ! command -v wl-paste &> /dev/null; then
    notify-send "Clipboard Manager" "wl-clipboard not installed!\nInstall with: pacman -S wl-clipboard" -u critical
    exit 1
fi

if ! command -v fzf &> /dev/null; then
    notify-send "Clipboard Manager" "fzf not installed!\nInstall with: pacman -S fzf" -u critical
    exit 1
fi

ensure_watchers() {
    local clipboard_watcher="wl-paste --watch cliphist store"
    local primary_watcher="wl-paste -p --watch cliphist store"

    if ! pgrep -af "$clipboard_watcher" > /dev/null; then
        nohup wl-paste --watch cliphist store >/dev/null 2>&1 &
    fi

    if [[ ${CLIPMAN_ENABLE_PRIMARY:-0} -eq 1 ]]; then
        if ! pgrep -af "$primary_watcher" > /dev/null; then
            nohup wl-paste -p --watch cliphist store >/dev/null 2>&1 &
        fi
    fi
}

ensure_watchers

close_kitty_window_on_exit() {
    [[ -n "${KITTY_WINDOW_ID:-}" ]] || return

    local parent_pid parent_comm
    parent_pid=$(ps -p $$ -o ppid= | awk '{print $1}')
    [[ -n "$parent_pid" ]] || return

    parent_comm=$(ps -p "$parent_pid" -o comm= | awk '{print $1}')
    if [[ "$parent_comm" == "kitty" ]]; then
        kill -s SIGTERM "$parent_pid" 2>/dev/null || true
    fi
}

trap close_kitty_window_on_exit EXIT

# FZF configuration
fzf_args=(
    --height=100%
    --layout=reverse
    --border=rounded
    --prompt="Clipboard History > "
    --delimiter=$'\t'
    --with-nth=2..
    --preview='cliphist decode {1}'
    --preview-window='up:5:wrap'
    --bind 'ctrl-d:delete-char'
    --bind 'ctrl-y:execute-silent(cliphist decode {1} | wl-copy)+abort'
    --bind 'ctrl-x:execute(cliphist delete {1})+reload(cliphist list)'
    --bind 'ctrl-a:select-all'
    --bind 'alt-p:toggle-preview'
    --header='ENTER:copy | CTRL-X:delete | ALT-P:preview'
    --color='prompt:cyan,pointer:cyan,marker:green'
)

# Get clipboard history
if ! cliphist list | grep -q .; then
    notify-send "Clipboard Manager" "Clipboard history is empty. Copy something with Ctrl+C first." -i edit-copy
    exit 0
fi

selection=$(cliphist list | fzf "${fzf_args[@]}")

if [[ -n "$selection" ]]; then
    selection_id=${selection%%$'\t'*}

    if [[ -z "$selection_id" ]]; then
        notify-send "Clipboard Manager" "Failed to identify selection entry." -u critical
        exit 1
    fi

    decoded=$(cliphist decode "$selection_id")

    if [[ -z "$decoded" ]]; then
        notify-send "Clipboard Manager" "The selected entry is empty or could not be decoded." -u normal
        exit 0
    fi

    printf '%s' "$decoded" | wl-copy

    preview=$(printf '%s' "$decoded" | head -c 50)
    if (( ${#decoded} > 50 )); then
        preview+="..."
    fi

    notify-send "Clipboard Manager" "Copied to clipboard:\n${preview}" -i edit-copy
else
    echo "No selection made"
fi

exit 0

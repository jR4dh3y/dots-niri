#!/bin/bash
set -euo pipefail

export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/1000}"

MODEL="${WHISPER_MODEL:-$HOME/random/whisper.cpp/models/ggml-medium.en.bin}"
TMPFILE="/tmp/whisper-record.wav"
PIDFILE="/tmp/whisper-recording.pid"
WHISPER="$HOME/random/whisper.cpp/build/bin/whisper-cli"

# --- stop ---
if [ -f "$PIDFILE" ]; then
    pid=$(cat "$PIDFILE")
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    rm -f "$PIDFILE"

    notify-send -t 2000 "Whisper" "Transcribing..." || true

    text=$("$WHISPER" -m "$MODEL" -f "$TMPFILE" --no-timestamps -l en --suppress-nst -nth 0.6 2>/dev/null || true)
    text=$(printf '%s' "$text" | tr '\n' ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/[[:space:]]\+/ /g')
    rm -f "$TMPFILE"

    if [ -n "$text" ]; then
        wtype "$text" || true
        notify-send -t 2000 "Whisper" "Done" || true
    fi
    exit 0
fi

# --- start ---
pw-record --rate=16000 --channels=1 "$TMPFILE" >/dev/null 2>&1 &
echo $! > "$PIDFILE"
disown

notify-send -t 2000 "Whisper" "Active" || true

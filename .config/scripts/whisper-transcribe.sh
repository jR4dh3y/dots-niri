#!/bin/bash
# Local streaming dictation toggle (Mod+Space).
# Default backend: NVIDIA Nemotron 3.5 ASR (multilingual, warm server).
#
# Press once  → listen; text types on pauses (endpointing).
# Press again → stop + flush last segment.
set -euo pipefail

export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

ROOT="${WHISPER_ROOT:-$HOME/random/whisper.cpp}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKER="${WHISPER_WORKER:-$SCRIPT_DIR/whisper-live-worker.py}"
ENSURE="${WHISPER_ENSURE:-$SCRIPT_DIR/whisper-server-ensure.sh}"
[ -f "$WORKER" ] || WORKER="$ROOT/cloud/whisper-live-worker.py"
[ -f "$ENSURE" ] || ENSURE="$ROOT/cloud/whisper-server-ensure.sh"

STATE_DIR="${WHISPER_STATE_DIR:-/tmp/whisper-live}"
PIDFILE="$STATE_DIR/worker.pid"

export WHISPER_ROOT="$ROOT"
export WHISPER_STATE_DIR="$STATE_DIR"
export WHISPER_BACKEND="${WHISPER_BACKEND:-nemotron}"
export WHISPER_LANG="${WHISPER_LANG:-en}"
export NEMOTRON_MODEL="${NEMOTRON_MODEL:-$ROOT/models/nemotron-3.5-asr-streaming-0.6b-q4_k.gguf}"
export WHISPER_MODEL="${WHISPER_MODEL:-$ROOT/models/ggml-small.en.bin}"
export WHISPER_THREADS="${WHISPER_THREADS:-6}"
export NEMOTRON_SERVER_URL="${NEMOTRON_SERVER_URL:-http://127.0.0.1:8179}"
export WHISPER_SERVER_URL="${WHISPER_SERVER_URL:-http://127.0.0.1:8178}"

mkdir -p "$STATE_DIR"

notify() {
    notify-send --expire-time="${2:-2000}" \
        -h string:x-dunst-stack-tag:whisper-live \
        -h string:x-canonical-private-synchronous:whisper-live \
        "Dictation 🎙" "$1" 2>/dev/null || true
}

# --- stop ---
if [ -f "$PIDFILE" ]; then
    pid=$(cat "$PIDFILE" 2>/dev/null || true)
    rm -f "$PIDFILE"
    if [ -n "${pid:-}" ] && kill -0 "$pid" 2>/dev/null; then
        kill -TERM "$pid" 2>/dev/null || true
        for _ in $(seq 1 100); do
            kill -0 "$pid" 2>/dev/null || break
            sleep 0.1
        done
        kill -KILL "$pid" 2>/dev/null || true
    fi
    if [ -f "$STATE_DIR/record.pid" ]; then
        rpid=$(cat "$STATE_DIR/record.pid" 2>/dev/null || true)
        [ -n "${rpid:-}" ] && kill "$rpid" 2>/dev/null || true
        rm -f "$STATE_DIR/record.pid"
    fi
    exit 0
fi

# --- start ---
if [ ! -f "$WORKER" ]; then
    notify "Worker missing: $WORKER" 5000
    exit 1
fi

if [ -f "$ENSURE" ]; then
    if ! bash "$ENSURE"; then
        notify "Warming model failed — see logs" 4000
        # still start; worker may CLI-fallback
    fi
fi

rm -f "$STATE_DIR/capture.pcm" "$STATE_DIR/status.txt"
python3 "$WORKER" >>"$STATE_DIR/worker.log" 2>&1 &
echo $! >"$PIDFILE"
disown || true
notify "Listening… (${WHISPER_BACKEND})" 0

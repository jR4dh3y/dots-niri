#!/bin/bash
# Cloudflare Workers AI streaming dictation toggle (Alt+Space).
#
# CF Whisper is batch-only at the API level (no WebSocket stream).
# We still stream text live by VAD-endpointing and POSTing each phrase —
# same UX as local, using @cf/openai/whisper-large-v3-turbo.
set -euo pipefail

export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

ROOT="${WHISPER_ROOT:-$HOME/random/whisper.cpp}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKER="${WHISPER_WORKER:-$SCRIPT_DIR/whisper-live-worker.py}"
[ -f "$WORKER" ] || WORKER="$ROOT/cloud/whisper-live-worker.py"

# Dedicated state so local + cloud can never collide
STATE_DIR="${WHISPER_CLOUD_STATE_DIR:-/tmp/whisper-cloud-live}"
PIDFILE="$STATE_DIR/worker.pid"

export WHISPER_ROOT="$ROOT"
export WHISPER_STATE_DIR="$STATE_DIR"
export WHISPER_BACKEND=cloudflare
export WHISPER_LANG="${WHISPER_LANG:-en}"
export CF_MODEL="${CF_MODEL:-@cf/openai/whisper-large-v3-turbo}"

# Prefer env; fall back to values from a previous install if present
# (set these in your shell profile for safety — avoid hardcoding tokens).
: "${CF_ACCOUNT_ID:=${CF_ACCOUNT_ID:-}}"
: "${CF_API_TOKEN:=${CF_API_TOKEN:-}}"

# Optional local defaults file (chmod 600): export CF_ACCOUNT_ID=... CF_API_TOKEN=...
if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/whisper-cloud.env" ]; then
    # shellcheck disable=SC1090
    set -a
    # shellcheck source=/dev/null
    . "${XDG_CONFIG_HOME:-$HOME/.config}/whisper-cloud.env"
    set +a
fi

mkdir -p "$STATE_DIR"

notify() {
    notify-send --expire-time="${2:-2000}" \
        -h string:x-dunst-stack-tag:whisper-cloud-live \
        -h string:x-canonical-private-synchronous:whisper-cloud-live \
        "Dictation ☁" "$1" 2>/dev/null || true
}

if [ -z "${CF_ACCOUNT_ID:-}" ] || [ -z "${CF_API_TOKEN:-}" ]; then
    notify "Set CF_ACCOUNT_ID and CF_API_TOKEN (or ~/.config/whisper-cloud.env)" 5000
    exit 1
fi
export CF_ACCOUNT_ID CF_API_TOKEN

# --- stop ---
if [ -f "$PIDFILE" ]; then
    pid=$(cat "$PIDFILE" 2>/dev/null || true)
    rm -f "$PIDFILE"
    if [ -n "${pid:-}" ] && kill -0 "$pid" 2>/dev/null; then
        kill -TERM "$pid" 2>/dev/null || true
        for _ in $(seq 1 120); do
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

rm -f "$STATE_DIR/capture.pcm" "$STATE_DIR/status.txt"
python3 "$WORKER" >>"$STATE_DIR/worker.log" 2>&1 &
echo $! >"$PIDFILE"
disown || true
notify "Listening… (cloud turbo)" 0

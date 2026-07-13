#!/bin/bash
# Ensure the warm STT server for the selected backend is up.
# WHISPER_BACKEND=nemotron|whisper  (cloudflare needs no local server)
set -euo pipefail

ROOT="${WHISPER_ROOT:-$HOME/random/whisper.cpp}"
BACKEND="${WHISPER_BACKEND:-nemotron}"
THREADS="${WHISPER_THREADS:-6}"
LANG="${WHISPER_LANG:-en}"
STATE_DIR="${WHISPER_STATE_DIR:-/tmp/whisper-live}"
mkdir -p "$STATE_DIR"

wait_url() {
    local url="$1"
    local tries="${2:-80}"
    local i
    for i in $(seq 1 "$tries"); do
        if curl -s -m 0.5 -o /dev/null "$url" 2>/dev/null; then
            return 0
        fi
        sleep 0.15
    done
    return 1
}

start_daemon() {
    local bin="$1"
    local pidfile="$2"
    local logfile="$3"
    local marker="$4"
    local model="$5"
    shift 5
    # remaining: server args

    if [ ! -x "$bin" ]; then
        echo "binary not found: $bin" >&2
        return 1
    fi
    if [ ! -f "$model" ]; then
        echo "model not found: $model" >&2
        return 1
    fi

    nohup "$bin" "$@" >"$logfile" 2>&1 &
    echo $! >"$pidfile"
    printf '%s\n' "$model" >"$marker"
    disown || true
}

case "$BACKEND" in
cloudflare)
    # No local model server
    exit 0
    ;;
nemotron)
    BIN="${NEMOTRON_SERVER_BIN:-$ROOT/build/bin/nemotron-server}"
    MODEL="${NEMOTRON_MODEL:-$ROOT/models/nemotron-3.5-asr-streaming-0.6b-q4_k.gguf}"
    HOST="${NEMOTRON_SERVER_HOST:-127.0.0.1}"
    PORT="${NEMOTRON_SERVER_PORT:-8179}"
    URL="http://${HOST}:${PORT}/"
    HEALTH="http://${HOST}:${PORT}/health"
    PIDFILE="$STATE_DIR/nemotron-server.pid"
    LOGFILE="$STATE_DIR/nemotron-server.log"
    MARKER="$STATE_DIR/nemotron-server.model"

    if curl -s -m 0.5 -o /dev/null "$HEALTH" 2>/dev/null; then
        if [ -f "$MARKER" ] && [ "$(cat "$MARKER" 2>/dev/null)" = "$MODEL" ]; then
            exit 0
        fi
    fi

    if [ -f "$PIDFILE" ]; then
        old=$(cat "$PIDFILE" 2>/dev/null || true)
        if [ -n "${old:-}" ] && kill -0 "$old" 2>/dev/null; then
            kill "$old" 2>/dev/null || true
            sleep 0.3
        fi
        rm -f "$PIDFILE"
    fi
    if command -v fuser >/dev/null 2>&1; then
        fuser -k "${PORT}/tcp" >/dev/null 2>&1 || true
        sleep 0.2
    fi

    start_daemon "$BIN" "$PIDFILE" "$LOGFILE" "$MARKER" "$MODEL" \
        -m "$MODEL" --host "$HOST" --port "$PORT" -t "$THREADS" -l "$LANG"

    if wait_url "$HEALTH" 120; then
        exit 0
    fi
    echo "nemotron-server failed to become ready; see $LOGFILE" >&2
    exit 1
    ;;
whisper)
    BIN="${WHISPER_SERVER_BIN:-$ROOT/build/bin/whisper-server}"
    MODEL="${WHISPER_MODEL:-$ROOT/models/ggml-small.en.bin}"
    HOST="${WHISPER_SERVER_HOST:-127.0.0.1}"
    PORT="${WHISPER_SERVER_PORT:-8178}"
    URL="http://${HOST}:${PORT}/"
    PIDFILE="$STATE_DIR/whisper-server.pid"
    LOGFILE="$STATE_DIR/whisper-server.log"
    MARKER="$STATE_DIR/whisper-server.model"

    if curl -s -m 0.5 -o /dev/null "$URL" 2>/dev/null; then
        if [ -f "$MARKER" ] && [ "$(cat "$MARKER" 2>/dev/null)" = "$MODEL" ]; then
            exit 0
        fi
        # try hot-swap
        if curl -s -m 120 -o /dev/null -F "model=$MODEL" "${URL%/}/load" 2>/dev/null; then
            printf '%s\n' "$MODEL" >"$MARKER"
            exit 0
        fi
    fi

    if [ -f "$PIDFILE" ]; then
        old=$(cat "$PIDFILE" 2>/dev/null || true)
        if [ -n "${old:-}" ] && kill -0 "$old" 2>/dev/null; then
            kill "$old" 2>/dev/null || true
            sleep 0.3
        fi
        rm -f "$PIDFILE"
    fi
    if command -v fuser >/dev/null 2>&1; then
        fuser -k "${PORT}/tcp" >/dev/null 2>&1 || true
        sleep 0.2
    fi

    start_daemon "$BIN" "$PIDFILE" "$LOGFILE" "$MARKER" "$MODEL" \
        -m "$MODEL" --host "$HOST" --port "$PORT" -t "$THREADS" -l en --suppress-nst

    if wait_url "$URL" 80; then
        exit 0
    fi
    echo "whisper-server failed to become ready; see $LOGFILE" >&2
    exit 1
    ;;
*)
    echo "unknown WHISPER_BACKEND=$BACKEND" >&2
    exit 1
    ;;
esac

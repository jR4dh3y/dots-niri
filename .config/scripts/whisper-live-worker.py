#!/usr/bin/env python3
"""
Streaming dictation worker — Grok-CLI-like UX with pluggable STT backends.

Backends (WHISPER_BACKEND):
  nemotron    — local NVIDIA Nemotron 3.5 ASR (warm server :8179)  [default]
  whisper     — local whisper.cpp whisper-server (:8178)
  cloudflare  — Cloudflare Workers AI whisper-large-v3-turbo (chunked)

Cloudflare does NOT expose a true streaming/WebSocket Whisper API. We still get
live dictation by endpointing on silence and POSTing each short segment — the
same shape as Grok's interim/final pipeline, just HTTP per phrase.
"""

from __future__ import annotations

import atexit
import base64
import json
import os
import re
import signal
import struct
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Optional


SAMPLE_RATE = 16000
BYTES_PER_SAMPLE = 2  # s16le mono
BYTES_PER_MS = SAMPLE_RATE * BYTES_PER_SAMPLE // 1000

ROOT = Path(os.environ.get("WHISPER_ROOT", Path.home() / "random" / "whisper.cpp"))
BACKEND = os.environ.get("WHISPER_BACKEND", "nemotron").strip().lower()

# Local servers
NEMO_URL = os.environ.get("NEMOTRON_SERVER_URL", "http://127.0.0.1:8179").rstrip("/")
WHISPER_URL = os.environ.get("WHISPER_SERVER_URL", "http://127.0.0.1:8178").rstrip("/")
NEMO_MODEL = os.environ.get(
    "NEMOTRON_MODEL",
    str(ROOT / "models" / "nemotron-3.5-asr-streaming-0.6b-q4_k.gguf"),
)
WHISPER_MODEL = os.environ.get(
    "WHISPER_MODEL",
    str(ROOT / "models" / "ggml-small.en.bin"),
)
WHISPER_CLI = os.environ.get("WHISPER_CLI", str(ROOT / "build" / "bin" / "whisper-cli"))
THREADS = int(os.environ.get("WHISPER_THREADS", "6"))
LANG = os.environ.get("WHISPER_LANG", "en")  # ISO or locale e.g. en, hi, de, en-US
NEMO_PRESET = int(os.environ.get("NEMOTRON_PRESET", "0"))  # 0=best accuracy

# Cloudflare Workers AI (batch model, used in chunked/streaming fashion)
CF_ACCOUNT_ID = os.environ.get("CF_ACCOUNT_ID", "")
CF_API_TOKEN = os.environ.get("CF_API_TOKEN", "")
CF_MODEL = os.environ.get("CF_MODEL", "@cf/openai/whisper-large-v3-turbo")

# Endpointing
SILENCE_MS = int(os.environ.get("WHISPER_SILENCE_MS", "450"))
MIN_SPEECH_MS = int(os.environ.get("WHISPER_MIN_SPEECH_MS", "280"))
MAX_SPEECH_MS = int(os.environ.get("WHISPER_MAX_SPEECH_MS", "8000"))
PAD_MS = int(os.environ.get("WHISPER_PAD_MS", "120"))
ENERGY_THRESH = float(os.environ.get("WHISPER_ENERGY", "520"))
HEARTBEAT_MS = int(os.environ.get("WHISPER_HEARTBEAT_MS", "800"))
SHOW_PARTIALS = os.environ.get("WHISPER_SHOW_PARTIALS", "0") == "1"
PARTIAL_EVERY_MS = int(os.environ.get("WHISPER_PARTIAL_MS", "1500"))

STATE_DIR = Path(os.environ.get("WHISPER_STATE_DIR", "/tmp/whisper-live"))
PCM_PATH = STATE_DIR / "capture.pcm"
REC_PID_PATH = STATE_DIR / "record.pid"
STATUS_PATH = STATE_DIR / "status.txt"
NOTIFY_ID = "whisper-live"

ENV = os.environ.copy()
ENV.setdefault("WAYLAND_DISPLAY", "wayland-1")
ENV.setdefault("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")

_LANG_TAG_RE = re.compile(r"\s*<[a-zA-Z]{2,3}(?:-[a-zA-Z0-9]+)?>\s*")

_stop = False
_record_proc: Optional[subprocess.Popen] = None
_typed_count = 0


def log(msg: str) -> None:
    sys.stderr.write(f"[whisper-live] {msg}\n")
    sys.stderr.flush()


def notify(body: str, *, critical: bool = False, timeout_ms: int = 0) -> None:
    urgency = "critical" if critical else "normal"
    cmd = [
        "notify-send",
        f"--urgency={urgency}",
        f"--expire-time={timeout_ms}",
        "-h",
        f"string:x-dunst-stack-tag:{NOTIFY_ID}",
        "-h",
        f"string:x-canonical-private-synchronous:{NOTIFY_ID}",
        "Dictation 🎙",
        body,
    ]
    try:
        subprocess.run(cmd, env=ENV, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except FileNotFoundError:
        pass
    try:
        STATUS_PATH.write_text(body + "\n", encoding="utf-8")
    except OSError:
        pass


def cleanup() -> None:
    global _record_proc
    if _record_proc and _record_proc.poll() is None:
        try:
            _record_proc.terminate()
            _record_proc.wait(timeout=1.5)
        except Exception:
            try:
                _record_proc.kill()
            except Exception:
                pass
    if REC_PID_PATH.exists():
        try:
            REC_PID_PATH.unlink()
        except OSError:
            pass


def handle_signal(signum, _frame) -> None:  # noqa: ANN001
    global _stop
    log(f"signal {signum}, stopping…")
    _stop = True


def start_recorder() -> None:
    global _record_proc
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    if PCM_PATH.exists():
        PCM_PATH.unlink()
    _record_proc = subprocess.Popen(
        ["pw-record", "--rate=16000", "--channels=1", "--format=s16", str(PCM_PATH)],
        env=ENV,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    REC_PID_PATH.write_text(str(_record_proc.pid), encoding="utf-8")
    log(f"recording pid={_record_proc.pid} → {PCM_PATH}")


def pcm_size() -> int:
    try:
        return PCM_PATH.stat().st_size
    except OSError:
        return 0


def read_pcm(start: int, end: int) -> bytes:
    if end <= start:
        return b""
    with open(PCM_PATH, "rb") as f:
        f.seek(start)
        return f.read(end - start)


def rms_energy(pcm: bytes) -> float:
    if len(pcm) < 2:
        return 0.0
    n = len(pcm) // 2
    total = 0.0
    count = 0
    for i in range(0, n, 4):
        (sample,) = struct.unpack_from("<h", pcm, i * 2)
        total += float(sample) * float(sample)
        count += 1
    if count == 0:
        return 0.0
    return (total / count) ** 0.5


def write_wav(path: Path, pcm: bytes) -> None:
    data_size = len(pcm)
    byte_rate = SAMPLE_RATE * BYTES_PER_SAMPLE
    header = struct.pack(
        "<4sI4s4sIHHIIHH4sI",
        b"RIFF",
        36 + data_size,
        b"WAVE",
        b"fmt ",
        16,
        1,
        1,
        SAMPLE_RATE,
        byte_rate,
        BYTES_PER_SAMPLE,
        16,
        b"data",
        data_size,
    )
    path.write_bytes(header + pcm)


def clean_text(text: str) -> str:
    text = _LANG_TAG_RE.sub(" ", text)
    text = text.replace("\n", " ").replace("\r", " ")
    text = " ".join(text.split()).strip()
    if text.lower() in {"", ".", "..", "...", "thank you", "thanks for watching", "you"}:
        return ""
    return text


def http_alive(url: str) -> bool:
    try:
        req = urllib.request.Request(url if url.endswith("/") else url + "/", method="GET")
        with urllib.request.urlopen(req, timeout=0.5) as resp:
            return resp.status < 500
    except Exception:
        try:
            # health endpoints
            for path in ("/health",):
                req = urllib.request.Request(url.rstrip("/") + path, method="GET")
                with urllib.request.urlopen(req, timeout=0.5) as resp:
                    return resp.status < 500
        except Exception:
            return False
    return False


def multipart_post(url: str, fields: dict, file_field: str, file_path: Path, headers: Optional[dict] = None) -> str:
    boundary = f"----dictation{os.getpid()}{int(time.time() * 1000)}"
    chunks: list[bytes] = []
    for name, value in fields.items():
        chunks.append(
            (
                f"--{boundary}\r\n"
                f'Content-Disposition: form-data; name="{name}"\r\n\r\n'
                f"{value}\r\n"
            ).encode()
        )
    file_bytes = file_path.read_bytes()
    chunks.append(
        (
            f"--{boundary}\r\n"
            f'Content-Disposition: form-data; name="{file_field}"; filename="seg.wav"\r\n'
            f"Content-Type: audio/wav\r\n\r\n"
        ).encode()
    )
    chunks.append(file_bytes)
    chunks.append(f"\r\n--{boundary}--\r\n".encode())
    body = b"".join(chunks)
    hdrs = {"Content-Type": f"multipart/form-data; boundary={boundary}"}
    if headers:
        hdrs.update(headers)
    req = urllib.request.Request(url, data=body, headers=hdrs, method="POST")
    with urllib.request.urlopen(req, timeout=45) as resp:
        return resp.read().decode("utf-8", errors="replace")


def transcribe_local_server(base_url: str, wav_path: Path, extra_fields: Optional[dict] = None) -> str:
    fields = {"response_format": "json", "temperature": "0.0"}
    if extra_fields:
        fields.update(extra_fields)
    raw = multipart_post(base_url.rstrip("/") + "/inference", fields, "file", wav_path)
    try:
        data = json.loads(raw)
        return clean_text(str(data.get("text") or ""))
    except json.JSONDecodeError:
        return clean_text(raw)


def transcribe_cloudflare(wav_path: Path) -> str:
    if not CF_ACCOUNT_ID or not CF_API_TOKEN:
        raise RuntimeError("CF_ACCOUNT_ID / CF_API_TOKEN not set")

    url = (
        f"https://api.cloudflare.com/client/v4/accounts/{CF_ACCOUNT_ID}"
        f"/ai/run/{CF_MODEL}"
    )
    # Prefer base64 JSON body (supports language); fall back to raw octet-stream
    audio_b64 = base64.b64encode(wav_path.read_bytes()).decode("ascii")
    payload = {"audio": audio_b64}
    if LANG and LANG != "auto":
        # CF accepts ISO 639-1; strip region if present
        payload["language"] = LANG.split("-")[0]

    body = json.dumps(payload).encode()
    req = urllib.request.Request(
        url,
        data=body,
        headers={
            "Authorization": f"Bearer {CF_API_TOKEN}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=45) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as e:
        # Some accounts work better with raw binary
        if e.code in (400, 415, 422):
            req2 = urllib.request.Request(
                url,
                data=wav_path.read_bytes(),
                headers={
                    "Authorization": f"Bearer {CF_API_TOKEN}",
                    "Content-Type": "application/octet-stream",
                },
                method="POST",
            )
            with urllib.request.urlopen(req2, timeout=45) as resp:
                raw = resp.read().decode("utf-8", errors="replace")
        else:
            raise

    data = json.loads(raw)
    # CF wraps as { result: { text: ... }, success: true }
    if isinstance(data.get("result"), dict):
        text = data["result"].get("text") or data["result"].get("transcription") or ""
    else:
        text = data.get("text") or ""
    return clean_text(str(text))


def transcribe_cli(wav_path: Path) -> str:
    model = NEMO_MODEL if BACKEND == "nemotron" else WHISPER_MODEL
    cmd = [
        WHISPER_CLI,
        "-m",
        model,
        "-f",
        str(wav_path),
        "--no-timestamps",
        "-l",
        LANG if LANG != "auto" else "en",
        "-t",
        str(THREADS),
    ]
    if not str(model).endswith(".gguf"):
        cmd += ["--suppress-nst", "-nth", "0.6"]
    proc = subprocess.run(cmd, capture_output=True, text=True, env=ENV, check=False, timeout=90)
    lines = []
    for line in (proc.stdout or "").splitlines():
        s = line.strip()
        if not s or s.startswith(("whisper_", "main:", "system_info", "ggml_", "nemotron:")):
            continue
        lines.append(s)
    return clean_text(" ".join(lines))


def transcribe(pcm: bytes) -> str:
    if len(pcm) < BYTES_PER_MS * MIN_SPEECH_MS:
        return ""
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tf:
        wav_path = Path(tf.name)
    try:
        write_wav(wav_path, pcm)
        if BACKEND == "cloudflare":
            return transcribe_cloudflare(wav_path)
        if BACKEND == "nemotron":
            if http_alive(NEMO_URL):
                try:
                    return transcribe_local_server(
                        NEMO_URL,
                        wav_path,
                        {"language": LANG, "preset": str(NEMO_PRESET)},
                    )
                except Exception as e:
                    log(f"nemotron server failed ({e}), CLI fallback")
            return transcribe_cli(wav_path)
        # whisper
        if http_alive(WHISPER_URL):
            try:
                return transcribe_local_server(WHISPER_URL, wav_path)
            except Exception as e:
                log(f"whisper server failed ({e}), CLI fallback")
        return transcribe_cli(wav_path)
    finally:
        try:
            wav_path.unlink()
        except OSError:
            pass


def type_text(text: str) -> None:
    global _typed_count
    if not text:
        return
    payload = text if _typed_count == 0 else (" " + text)
    try:
        subprocess.run(["wtype", "--", payload], env=ENV, check=False, timeout=10)
        _typed_count += 1
        log(f"typed: {text!r}")
    except Exception as e:
        log(f"wtype failed: {e}")


def ms_of(nbytes: int) -> int:
    return nbytes // BYTES_PER_MS


def backend_label() -> str:
    if BACKEND == "cloudflare":
        return "cloud"
    if BACKEND == "nemotron":
        return "nemotron"
    return "whisper"


def main() -> int:
    global _stop
    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGINT, handle_signal)
    atexit.register(cleanup)

    if BACKEND not in {"nemotron", "whisper", "cloudflare"}:
        notify(f"Unknown backend: {BACKEND}", critical=True, timeout_ms=5000)
        return 2
    if BACKEND == "cloudflare" and (not CF_ACCOUNT_ID or not CF_API_TOKEN):
        notify("Missing CF_ACCOUNT_ID / CF_API_TOKEN", critical=True, timeout_ms=5000)
        return 2

    STATE_DIR.mkdir(parents=True, exist_ok=True)
    start_recorder()

    for _ in range(50):
        if pcm_size() > 0 or _stop:
            break
        time.sleep(0.05)

    bl = backend_label()
    notify(f"Listening… ({bl})", timeout_ms=0)
    log(f"backend={BACKEND} lang={LANG}")

    commit_pos = 0
    speech_start: Optional[int] = None
    last_voice_pos = 0
    last_partial_t = 0.0
    last_partial_text = ""
    t0 = time.time()
    last_heartbeat_t = 0.0

    window_ms = 80
    window_bytes = window_ms * BYTES_PER_MS

    while not _stop:
        size = pcm_size()
        now = time.time()
        elapsed = now - t0

        if (now - last_heartbeat_t) * 1000 >= HEARTBEAT_MS and speech_start is None:
            state = "Listening" if size > 0 else "Waiting for mic"
            notify(f"{state}…  {elapsed:0.1f}s · {bl}", timeout_ms=0)
            last_heartbeat_t = now

        if size < commit_pos + window_bytes:
            time.sleep(0.04)
            continue

        look_start = max(commit_pos, size - window_bytes * 3)
        chunk = read_pcm(look_start, size)
        energy = rms_energy(chunk)
        voiced = energy >= ENERGY_THRESH

        if voiced:
            if speech_start is None:
                speech_start = max(commit_pos, size - PAD_MS * BYTES_PER_MS)
            last_voice_pos = size

            speech_ms = ms_of(size - speech_start)
            if (now - last_heartbeat_t) * 1000 >= HEARTBEAT_MS:
                notify(f"Hearing…  {speech_ms / 1000:0.1f}s · {bl}", timeout_ms=0)
                last_heartbeat_t = now

            if SHOW_PARTIALS and BACKEND != "cloudflare" and (now - last_partial_t) * 1000 >= PARTIAL_EVERY_MS:
                seg = read_pcm(speech_start, size)
                if ms_of(len(seg)) >= MIN_SPEECH_MS:
                    partial = transcribe(seg)
                    if partial and partial != last_partial_text:
                        last_partial_text = partial
                        preview = partial if len(partial) < 90 else ("…" + partial[-89:])
                        notify(f"… {preview}", timeout_ms=0)
                last_partial_t = now

            if speech_start is not None and ms_of(size - speech_start) >= MAX_SPEECH_MS:
                end = size
                pcm = read_pcm(speech_start, end)
                text = transcribe(pcm)
                if text:
                    type_text(text)
                    notify(f"✓ {text if len(text) < 90 else text[:89] + '…'}", timeout_ms=0)
                commit_pos = end
                speech_start = None
                last_partial_text = ""
        else:
            if speech_start is not None:
                silence_bytes = size - last_voice_pos
                if ms_of(silence_bytes) >= SILENCE_MS:
                    end = min(size, last_voice_pos + PAD_MS * BYTES_PER_MS)
                    if end > speech_start and ms_of(end - speech_start) >= MIN_SPEECH_MS:
                        pcm = read_pcm(speech_start, end)
                        text = transcribe(pcm)
                        if text:
                            type_text(text)
                            notify(f"✓ {text if len(text) < 90 else text[:89] + '…'}", timeout_ms=0)
                        else:
                            notify(f"Listening… · {bl}", timeout_ms=0)
                    commit_pos = end
                    speech_start = None
                    last_partial_text = ""

        time.sleep(0.04)

    # flush
    size = pcm_size()
    if speech_start is None:
        tail = read_pcm(commit_pos, size)
        if ms_of(len(tail)) >= MIN_SPEECH_MS and rms_energy(tail) >= ENERGY_THRESH * 0.7:
            speech_start = commit_pos

    if speech_start is not None and size > speech_start:
        pcm = read_pcm(speech_start, size)
        if ms_of(len(pcm)) >= MIN_SPEECH_MS:
            notify("Finalizing…", timeout_ms=2500)
            text = transcribe(pcm)
            if text:
                type_text(text)

    cleanup()
    if _typed_count:
        notify(f"Done · {_typed_count} segment(s) · {bl}", timeout_ms=2000)
    else:
        notify(f"Done · no speech · {bl}", timeout_ms=2500)
    log(f"exit, typed_segments={_typed_count}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

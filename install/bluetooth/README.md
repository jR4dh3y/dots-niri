# Bluetooth stability (MT7921 + Airdopes TWS)

## Problem
Airdopes 219 (and similar TWS) connect then drop after a few seconds on this
HP laptop. Logs show:

- `spa.bluez5.sink.media: Missing completion reports … firmware bug?`
- `avdtp: No reply to Close request`
- `a2dp: Unable to load LastUsed: rseid N not found`
- HFP/hands-free SDP failures when profiles flip

Root causes (stacked):
1. WirePlumber HFP autoswitch / handsfree negotiation on cheap TWS
2. MediaTek MT7921 USB Bluetooth autosuspend during A2DP
3. Stale BlueZ A2DP SEP (LastUsed rseid) after failed sessions
4. Seat monitoring tearing down bluez when Ly seat is flaky

## Install (once, needs root)

```bash
~/code/dots-niri/install/bluetooth/install-bt-fix.sh
systemctl --user restart wireplumber pipewire pipewire-pulse
```

User WirePlumber policy also lives in:

- `~/.config/wireplumber/wireplumber.conf.d/50-bluez-no-seat-monitoring.conf`
- `~/.config/wireplumber/wireplumber.conf.d/51-bluetooth-a2dp-only.conf`

Tracked copies: `dots-niri/.config/wireplumber/...` and `install/bluetooth/`.

## Re-pair Airdopes

```bash
airdopes-repair
# or: ~/.local/bin/airdopes-repair
```

Put buds in pairing mode when prompted. Mic over Bluetooth is disabled
(A2DP only) — use the laptop mic for calls.

## Note
Do **not** rename `51-bluetooth-a2dp-only.conf` to `.disabled` again unless you
intentionally need HFP headset mic (which tends to reintroduce the drop loop).

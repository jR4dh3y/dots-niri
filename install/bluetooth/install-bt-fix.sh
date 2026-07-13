#!/usr/bin/env bash
# System-level Bluetooth stability for HP + MediaTek MT7921 + Airdopes-class TWS.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SUDO="${SUDO:-sudo}"

echo "==> WirePlumber A2DP-only policy"
$SUDO install -Dm644 \
  "$ROOT/.config/wireplumber/wireplumber.conf.d/51-bluetooth-a2dp-only.conf" \
  /etc/wireplumber/wireplumber.conf.d/51-bluetooth-a2dp-only.conf
# Prefer live user copy if newer
if [ -f /home/radhey/.config/wireplumber/wireplumber.conf.d/51-bluetooth-a2dp-only.conf ]; then
  $SUDO install -Dm644 \
    /home/radhey/.config/wireplumber/wireplumber.conf.d/51-bluetooth-a2dp-only.conf \
    /etc/wireplumber/wireplumber.conf.d/51-bluetooth-a2dp-only.conf
fi
$SUDO rm -f /etc/wireplumber/wireplumber.conf.d/51-bluetooth-a2dp-only.conf.disabled

echo "==> USB no-autosuspend udev rule for MT7921 BT (13d3:3567)"
$SUDO install -Dm644 \
  "$ROOT/install/bluetooth/91-mt7921-bt-no-autosuspend.rules" \
  /etc/udev/rules.d/91-mt7921-bt-no-autosuspend.rules
$SUDO udevadm control --reload-rules
$SUDO udevadm trigger --subsystem-match=usb --action=change || true

for dev in /sys/bus/usb/devices/*; do
  if [ -f "$dev/idVendor" ] && [ "$(cat "$dev/idVendor")" = "13d3" ] \
     && [ -f "$dev/idProduct" ] && [ "$(cat "$dev/idProduct")" = "3567" ]; then
    echo "    fixing power on $dev"
    echo on | $SUDO tee "$dev/power/control" >/dev/null
    echo -1 | $SUDO tee "$dev/power/autosuspend" >/dev/null || true
    parent="$(dirname "$(readlink -f "$dev")")"
    if [ -f "$parent/power/control" ]; then
      echo "    fixing parent $parent"
      echo on | $SUDO tee "$parent/power/control" >/dev/null || true
    fi
  fi
done
# Always wake usb1 hub used by this machine
if [ -f /sys/bus/usb/devices/usb1/power/control ]; then
  echo on | $SUDO tee /sys/bus/usb/devices/usb1/power/control >/dev/null || true
fi

echo "==> BlueZ main.conf: AutoEnable on, Experimental OFF (LE thrash on MT7921)"
if [ -f /etc/bluetooth/main.conf ]; then
  $SUDO cp -a /etc/bluetooth/main.conf \
    "/etc/bluetooth/main.conf.bak-$(date +%Y%m%d-%H%M%S)"
fi
$SUDO sed -i \
  -e 's/^#\?Experimental = .*/Experimental = false/' \
  -e 's/^#\?AutoEnable=.*/AutoEnable=true/' \
  -e 's/^#\?FastConnectable = .*/FastConnectable = true/' \
  /etc/bluetooth/main.conf
if ! grep -qE '^Experimental = ' /etc/bluetooth/main.conf; then
  printf '\nExperimental = false\n' | $SUDO tee -a /etc/bluetooth/main.conf >/dev/null
fi
if ! grep -qE '^AutoEnable=' /etc/bluetooth/main.conf; then
  printf 'AutoEnable=true\n' | $SUDO tee -a /etc/bluetooth/main.conf >/dev/null
fi
$SUDO rm -f /etc/bluetooth/main.conf.new

echo "==> btusb: disable module autosuspend"
echo 'options btusb enable_autosuspend=0' | $SUDO tee /etc/modprobe.d/btusb-no-autosuspend.conf >/dev/null

echo "==> Clear stale A2DP SEP/cache for Airdopes (rseid not found)"
ADAPTER=$(ls /var/lib/bluetooth 2>/dev/null | head -1 || true)
MAC_DIR="41:86:4E:DF:B0:B6"
if [ -n "$ADAPTER" ] && [ -d "/var/lib/bluetooth/$ADAPTER/$MAC_DIR" ]; then
  $SUDO rm -f "/var/lib/bluetooth/$ADAPTER/$MAC_DIR/attributes" || true
  $SUDO rm -f "/var/lib/bluetooth/$ADAPTER/cache/$MAC_DIR" || true
  if [ -f "/var/lib/bluetooth/$ADAPTER/$MAC_DIR/info" ]; then
    $SUDO sed -i '/^LastUsed/d' "/var/lib/bluetooth/$ADAPTER/$MAC_DIR/info" || true
  fi
  echo "    cleared SEP/cache for $MAC_DIR on $ADAPTER"
else
  echo "    (no store for $MAC_DIR — ok if unpaired)"
fi

echo "==> Restart bluetooth service"
$SUDO systemctl restart bluetooth

echo "==> Done."
echo "USB 1-4: $(cat /sys/bus/usb/devices/1-4/power/control 2>/dev/null || echo n/a)"
echo "USB1 hub: $(cat /sys/bus/usb/devices/usb1/power/control 2>/dev/null || echo n/a)"
echo "Experimental: $(grep -E '^Experimental' /etc/bluetooth/main.conf || true)"
echo
echo "As user:"
echo "  systemctl --user restart wireplumber pipewire pipewire-pulse"
echo "  systemctl --user daemon-reload"
echo "  systemctl --user enable --now bt-stabilize.service"
echo "  # or: bt-stabilize"

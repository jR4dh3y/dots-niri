import { Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"

export default function NetworkInfo() {
  const connection = createPoll("Disconnected", 3000, `
    set -euo pipefail
    nmcli -t -f NAME c show --active 2>/dev/null | head -1 || echo 'Disconnected'
  `)
  const ipAddress = createPoll("0.0.0.0", 5000, `
    set -euo pipefail
    ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \\K\\S+' || echo '0.0.0.0'
  `)
  const networkStats = createPoll("↓ 0 KB/s ↑ 0 KB/s", 3000, `
    set -euo pipefail
    INTERFACE=$(ip route 2>/dev/null | awk '/default/ { print $5 ; exit }' || echo '')
    if [ -n "$INTERFACE" ] && [ -f "/sys/class/net/$INTERFACE/statistics/rx_bytes" ]; then
      RX1=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes 2>/dev/null || echo 0)
      TX1=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes 2>/dev/null || echo 0)
      sleep 1
      RX2=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes 2>/dev/null || echo 0)
      TX2=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes 2>/dev/null || echo 0)
      RX_RATE=$(( (RX2 - RX1) / 1024 ))
      TX_RATE=$(( (TX2 - TX1) / 1024 ))
      echo "↓ \${RX_RATE} KB/s ↑ \${TX_RATE} KB/s"
    else
      echo "↓ 0 KB/s ↑ 0 KB/s"
    fi
  `)

  return (
    <box class="network-info-widget" orientation={Gtk.Orientation.VERTICAL} spacing={8}>
      <box class="widget-header">
        <label label="🌐" class="widget-icon" />
        <label label="Network" class="widget-title" hexpand />
      </box>
      
      <box class="network-details" orientation={Gtk.Orientation.VERTICAL} spacing={6}>
        <box spacing={8}>
          <label label="Connection:" class="network-label" />
          <label label={connection} class="network-value" hexpand halign={Gtk.Align.END} />
        </box>
        
        <box spacing={8}>
          <label label="IP Address:" class="network-label" />
          <label label={ipAddress} class="network-value" hexpand halign={Gtk.Align.END} />
        </box>
        
        <box spacing={8}>
          <label label="Speed:" class="network-label" />
          <label label={networkStats} class="network-value" hexpand halign={Gtk.Align.END} />
        </box>
      </box>
    </box>
  )
}

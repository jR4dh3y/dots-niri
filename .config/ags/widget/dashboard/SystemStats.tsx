import { Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"

export default function SystemStats() {
  const cpu = createPoll("0%", 2000, "top -bn1 2>/dev/null | grep 'Cpu(s)' | sed 's/.*, *\\([0-9.]*\\)%* id.*/\\1/' | awk '{print 100 - $1\"%\"}' || echo '0%'")
  const memory = createPoll("0%", 2000, "free 2>/dev/null | grep Mem | awk '{printf \"%.1f%%\", $3/$2 * 100.0}' || echo '0%'")
  const temp = createPoll("0°C", 3000, "sensors 2>/dev/null | grep -i 'Package id 0:' | awk '{print $4}' | head -1 || sensors 2>/dev/null | grep -i 'core 0:' | awk '{print $3}' | head -1 || echo '0°C'")
  const gpu = createPoll("N/A", 3000, "nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 | awk '{print $1\"%\"}' || echo 'N/A'")
  const power = createPoll("N/A", 5000, "cat /sys/class/power_supply/BAT*/power_now 2>/dev/null | awk '{sum+=$1} END {printf \"%.1fW\", sum/1000000}' || echo 'N/A'")

  return (
    <box class="system-stats-widget" orientation={Gtk.Orientation.VERTICAL} spacing={8}>
      <box class="widget-header">
        <label label="📊" class="widget-icon" />
        <label label="System Stats" class="widget-title" hexpand />
      </box>
      
      <box class="stats-grid" orientation={Gtk.Orientation.VERTICAL} spacing={6}>
        <box spacing={8}>
          <label label="CPU:" class="stat-label" />
          <label label={cpu} class="stat-value" hexpand halign={Gtk.Align.END} />
        </box>
        
        <box spacing={8}>
          <label label="Memory:" class="stat-label" />
          <label label={memory} class="stat-value" hexpand halign={Gtk.Align.END} />
        </box>
        
        <box spacing={8}>
          <label label="GPU:" class="stat-label" />
          <label label={gpu} class="stat-value" hexpand halign={Gtk.Align.END} />
        </box>
        
        <box spacing={8}>
          <label label="Temperature:" class="stat-label" />
          <label label={temp} class="stat-value" hexpand halign={Gtk.Align.END} />
        </box>
        
        <box spacing={8}>
          <label label="Power:" class="stat-label" />
          <label label={power} class="stat-value" hexpand halign={Gtk.Align.END} />
        </box>
      </box>
    </box>
  )
}

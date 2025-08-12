import { Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"
import { execAsync } from "ags/process"

export default function VolumeControl() {
  const volume = createPoll("0%", 500, `
    set -euo pipefail
    pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -Po '\\d+%' | head -1 || echo '0%'
  `)
  const muteStatus = createPoll("🔊", 500, `
    set -euo pipefail
    MUTE=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -o 'yes\\|no' || echo 'no')
    if [ "$MUTE" = "yes" ]; then
      echo "🔇"
    else
      echo "🔊"
    fi
  `)

  const toggleMute = () => {
    execAsync("pactl set-sink-mute @DEFAULT_SINK@ toggle").catch((err: any) => {
      console.error("Failed to toggle mute:", err)
    })
  }

  const volumeUp = () => {
    execAsync("pactl set-sink-volume @DEFAULT_SINK@ +5%").catch((err: any) => {
      console.error("Failed to increase volume:", err)
    })
  }

  const volumeDown = () => {
    execAsync("pactl set-sink-volume @DEFAULT_SINK@ -5%").catch((err: any) => {
      console.error("Failed to decrease volume:", err)
    })
  }

  return (
    <box class="volume-control-widget" orientation={Gtk.Orientation.VERTICAL} spacing={6} hexpand>
      <box class="volume-info" spacing={2} halign={Gtk.Align.CENTER} orientation={Gtk.Orientation.VERTICAL}>
        <label label={volume} class="volume-level" />
      </box>
      
      <box class="volume-knob-area" halign={Gtk.Align.CENTER}>
        <button class="volume-knob" onClicked={toggleMute}>
          <label label={muteStatus} class="volume-icon" />
        </button>
      </box>
      
      <box class="volume-scroll-controls" spacing={2} halign={Gtk.Align.CENTER} orientation={Gtk.Orientation.HORIZONTAL}>
        <button class="volume-scroll-btn" onClicked={volumeDown}>
          <label label="−" />
        </button>
        <button class="volume-scroll-btn" onClicked={volumeUp}>
          <label label="+" />
        </button>
      </box>
    </box>
  )
}

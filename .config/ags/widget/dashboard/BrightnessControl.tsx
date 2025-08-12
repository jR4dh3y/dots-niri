import { Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"
import { execAsync } from "ags/process"

export default function BrightnessControl() {
  const brightness = createPoll("0%", 1000, `
    set -euo pipefail
    if command -v brightnessctl >/dev/null 2>&1; then
      brightnessctl get 2>/dev/null | awk '{print int($1/$(brightnessctl max 2>/dev/null)*100)"%"}' || echo '0%'
    else
      echo '0%'
    fi
  `)

  const brightnessUp = () => {
    execAsync("brightnessctl set +10%").catch((err: any) => {
      console.error("Failed to increase brightness:", err)
    })
  }

  const brightnessDown = () => {
    execAsync("brightnessctl set 10%-").catch((err: any) => {
      console.error("Failed to decrease brightness:", err)
    })
  }

  return (
    <box class="brightness-control-widget" orientation={Gtk.Orientation.VERTICAL} spacing={6} hexpand>
      <box class="brightness-info" spacing={2} halign={Gtk.Align.CENTER} orientation={Gtk.Orientation.VERTICAL}>
        <label label={brightness} class="brightness-level" />
      </box>
      
      <box class="brightness-knob-area" halign={Gtk.Align.CENTER}>
        <button class="brightness-knob">
          <label label="💡" class="brightness-icon" />
        </button>
      </box>
      
      <box class="brightness-scroll-controls" spacing={2} halign={Gtk.Align.CENTER} orientation={Gtk.Orientation.HORIZONTAL}>
        <button class="brightness-scroll-btn" onClicked={brightnessDown}>
          <label label="−" />
        </button>
        <button class="brightness-scroll-btn" onClicked={brightnessUp}>
          <label label="+" />
        </button>
      </box>
    </box>
  )
}

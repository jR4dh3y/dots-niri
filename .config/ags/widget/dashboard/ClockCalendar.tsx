import { Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"

export default function ClockCalendar() {
  const time = createPoll("00:00:00", 1000, `
    set -euo pipefail
    date '+%H:%M:%S' 2>/dev/null || echo '00:00:00'
  `)
  const date = createPoll("", 60000, `
    set -euo pipefail
    date '+%A, %B %d, %Y' 2>/dev/null || echo ''
  `)

  return (
    <box class="clock-calendar-widget" orientation={Gtk.Orientation.VERTICAL} spacing={6}>
      <box class="widget-header">
        <label label="⏰" class="widget-icon" />
        <label label="Time & Date" class="widget-title" hexpand />
      </box>
      
      <box class="time-display" orientation={Gtk.Orientation.VERTICAL} spacing={2} halign={Gtk.Align.CENTER}>
        <label label={time} class="time-label" />
        <label label={date} class="date-label" />
      </box>

      <menubutton class="calendar-button" halign={Gtk.Align.CENTER}>
        <label label="📅 Calendar" />
        <popover>
          <box orientation={Gtk.Orientation.VERTICAL} spacing={6} margin-top={8} margin-bottom={8} margin-start={8} margin-end={8}>
            <Gtk.Calendar />
          </box>
        </popover>
      </menubutton>
    </box>
  )
}

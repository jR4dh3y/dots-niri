import { Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"
import { execAsync } from "ags/process"

export default function NotificationCenter() {
  const notifications = createPoll("No notifications", 3000, `
    set -euo pipefail
    # Try to get recent notifications from various sources
    if command -v dunstctl >/dev/null 2>&1; then
      dunstctl history 2>/dev/null | head -3 | sed 's/^/• /' || echo 'No notifications'
    elif command -v makoctl >/dev/null 2>&1; then
      makoctl history 2>/dev/null | head -3 | sed 's/^/• /' || echo 'No notifications'  
    elif [ -f ~/.local/share/dunst/log ]; then
      tail -3 ~/.local/share/dunst/log 2>/dev/null | sed 's/^/• /' || echo 'No notifications'
    else
      echo 'No notification daemon found'
    fi
  `)

  const clearNotifications = () => {
    execAsync(`
      if command -v dunstctl >/dev/null 2>&1; then
        dunstctl close-all
      elif command -v makoctl >/dev/null 2>&1; then
        makoctl dismiss -a
      fi
    `).catch((err: any) => {
      console.error("Failed to clear notifications:", err)
    })
  }

  return (
    <box class="notification-center-widget" orientation={Gtk.Orientation.VERTICAL} spacing={8}>
      <box class="widget-header">
        <label label="🔔" class="widget-icon" />
        <label label="Notifications" class="widget-title" hexpand />
        <button class="clear-button" onClicked={clearNotifications}>
          <label label="Clear" />
        </button>
      </box>
      
      <scrolledwindow class="notification-scroll" vexpand>
        <box class="notification-list" orientation={Gtk.Orientation.VERTICAL} spacing={4}>
          <label label={notifications} class="notification-content" wrap />
        </box>
      </scrolledwindow>
    </box>
  )
}

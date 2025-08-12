import { Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"

export default function PowerButtons() {
  const logout = () => {
    execAsync("loginctl terminate-user $USER").catch((err: any) => {
      console.error("Failed to logout:", err)
    })
  }

  const reboot = () => {
    execAsync("systemctl reboot").catch((err: any) => {
      console.error("Failed to reboot:", err)
    })
  }

  const shutdown = () => {
    execAsync("systemctl poweroff").catch((err: any) => {
      console.error("Failed to shutdown:", err)
    })
  }

  const lock = () => {
    execAsync("loginctl lock-session").catch((err: any) => {
      console.error("Failed to lock:", err)
    })
  }

  return (
    <box class="power-buttons-widget" orientation={Gtk.Orientation.VERTICAL} spacing={8}>
      <box class="widget-header">
        <label label="⚡" class="widget-icon" />
        <label label="Power Options" class="widget-title" hexpand />
      </box>
      
      <box class="power-grid" spacing={8}>
        <button class="power-button lock-button" onClicked={lock} hexpand>
          <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
            <label label="🔒" class="power-icon" />
            <label label="Lock" class="power-label" />
          </box>
        </button>
        
        <button class="power-button logout-button" onClicked={logout} hexpand>
          <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
            <label label="👤" class="power-icon" />
            <label label="Logout" class="power-label" />
          </box>
        </button>
      </box>
      
      <box class="power-grid" spacing={8}>
        <button class="power-button reboot-button" onClicked={reboot} hexpand>
          <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
            <label label="🔄" class="power-icon" />
            <label label="Reboot" class="power-label" />
          </box>
        </button>
        
        <button class="power-button shutdown-button" onClicked={shutdown} hexpand>
          <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
            <label label="⚡" class="power-icon" />
            <label label="Shutdown" class="power-label" />
          </box>
        </button>
      </box>
    </box>
  )
}

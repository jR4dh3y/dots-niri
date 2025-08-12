import { Astal, Gtk, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"
import SystemStats from "./dashboard/SystemStats"
import MediaPlayer from "./dashboard/MediaPlayer"
import VolumeControl from "./dashboard/VolumeControl"
import BrightnessControl from "./dashboard/BrightnessControl"
import NetworkInfo from "./dashboard/NetworkInfo"
import PowerButtons from "./dashboard/PowerButtons"

export default function Dashboard(gdkmonitor: Gdk.Monitor) {
  const { TOP, RIGHT, BOTTOM } = Astal.WindowAnchor

  return (
    <window
      name="dashboard"
      class="Dashboard"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.NORMAL}
      anchor={TOP | RIGHT | BOTTOM}
      application={app}
      visible={false}
      keymode={Astal.Keymode.ON_DEMAND}
    >
      <box 
        class="dashboard-container"
        orientation={Gtk.Orientation.VERTICAL}
        spacing={0}
        margin-top={0}
        margin-bottom={0}
        margin-start={0}
        margin-end={0}
      >
        <box 
          orientation={Gtk.Orientation.VERTICAL} 
          spacing={0}
          class="dashboard-content"
        >
          <MediaPlayer />
          <box orientation={Gtk.Orientation.HORIZONTAL} spacing={0}>
            <VolumeControl />
            <BrightnessControl />
          </box>
          <SystemStats />
          <NetworkInfo />
          <PowerButtons />
        </box>
      </box>
    </window>
  )
}

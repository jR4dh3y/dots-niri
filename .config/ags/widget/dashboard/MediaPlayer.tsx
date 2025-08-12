import { Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"
import { execAsync } from "ags/process"

export default function MediaPlayer() {
  const playerStatus = createPoll("Not playing", 1000, `
    set -euo pipefail
    playerctl status 2>/dev/null || echo 'Not playing'
  `)
  const playerTitle = createPoll("No media", 1000, `
    set -euo pipefail
    playerctl metadata title 2>/dev/null || echo 'No media'
  `)
  const playerArtist = createPoll("", 1000, `
    set -euo pipefail
    playerctl metadata artist 2>/dev/null || echo ''
  `)
  const playerAlbum = createPoll("", 2000, `
    set -euo pipefail
    playerctl metadata album 2>/dev/null || echo ''
  `)
  const playerPosition = createPoll("", 1000, `
    set -euo pipefail
    if playerctl status >/dev/null 2>&1; then
      POS=$(playerctl position 2>/dev/null | cut -d. -f1 || echo 0)
      LEN=$(playerctl metadata mpris:length 2>/dev/null | sed 's/000000$//' || echo 0)
      if [ -n "$POS" ] && [ -n "$LEN" ] && [ "$LEN" -gt 0 ] 2>/dev/null; then
        POS_MIN=$((POS / 60))
        POS_SEC=$((POS % 60))
        LEN_MIN=$((LEN / 60))
        LEN_SEC=$((LEN % 60))
        printf "%02d:%02d / %02d:%02d" $POS_MIN $POS_SEC $LEN_MIN $LEN_SEC
      else
        echo ""
      fi
    else
      echo ""
    fi
  `)

  const playPause = () => {
    execAsync("playerctl play-pause").catch((err: any) => {
      console.error("Failed to play/pause:", err)
    })
  }

  const next = () => {
    execAsync("playerctl next").catch((err: any) => {
      console.error("Failed to skip to next:", err)
    })
  }

  const previous = () => {
    execAsync("playerctl previous").catch((err: any) => {
      console.error("Failed to skip to previous:", err)
    })
  }

  return (
    <box class="media-player-widget" orientation={Gtk.Orientation.VERTICAL} spacing={6}>
      <box class="widget-header">
        <label label="🎵" class="widget-icon" />
        <label label="Media Player" class="widget-title" hexpand />
      </box>
      
      <box class="media-info" orientation={Gtk.Orientation.VERTICAL} spacing={2} halign={Gtk.Align.CENTER}>
        <label label={playerTitle} class="media-title" />
        <label label={playerArtist} class="media-artist" />
        <label label={playerAlbum} class="media-album" />
        <label label={playerStatus} class="media-status" />
        <label label={playerPosition} class="media-position" />
      </box>

      <box class="media-controls" spacing={6} halign={Gtk.Align.CENTER}>
        <button class="media-button" onClicked={previous}>
          <label label="⏮" />
        </button>
        
        <button class="media-button play-pause" onClicked={playPause}>
          <label label="⏯" />
        </button>
        
        <button class="media-button" onClicked={next}>
          <label label="⏭" />
        </button>
      </box>
    </box>
  )
}

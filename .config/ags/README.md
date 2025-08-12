# AGS Dashboard Configuration

This is a modular AGS dashboard that slides in from the right side of the screen. It's designed for the Niri window manager on Wayland and provides a comprehensive system monitoring and control interface.

## Features

- **System Stats**: Live CPU, RAM, GPU utilization, temperature, and power monitoring
- **Media Player**: Control music playback via playerctl with track info, artist, album, and position
- **Volume & Brightness**: Control system audio and screen brightness with visual indicators
- **Network Info**: Display connection status, IP address, and real-time upload/download speeds
- **Notifications**: View and clear system notifications from various notification daemons
- **Clock & Calendar**: Time display with popup calendar widget
- **Power Options**: Lock, logout, reboot, and shutdown buttons

## Usage

### Toggle Dashboard
```bash
# Use the provided script
./toggle-dashboard.sh

# Or directly with AGS
ags toggle dashboard

# Or use the enhanced launcher
./launch-ags.sh toggle
```

### Start/Stop AGS
```bash
# Start AGS (checks if already running)
./launch-ags.sh

# Restart AGS
./launch-ags.sh restart

# Stop AGS
./launch-ags.sh stop

# Check status
./launch-ags.sh status
```

### Niri Configuration Example
Add this to your Niri config to bind a hotkey:

```kdl
binds {
    Mod+Shift+D { spawn "ags" "toggle" "dashboard"; }
    # Or use the launch script
    Mod+Shift+D { spawn "/home/user/.config/ags/toggle-dashboard.sh"; }
}
```

## File Structure

```
widget/
├── Dashboard.tsx          # Main dashboard window with slide animation
├── Bar.tsx               # Top bar (optional)
└── dashboard/            # Individual widgets
    ├── ClockCalendar.tsx # Time, date, and calendar popup
    ├── SystemStats.tsx   # CPU, RAM, GPU, temperature, power
    ├── MediaPlayer.tsx   # Music controls with detailed track info
    ├── VolumeControl.tsx # Audio volume with mute status
    ├── BrightnessControl.tsx # Screen brightness controls
    ├── NetworkInfo.tsx   # Connection, IP, and speed monitoring
    ├── NotificationCenter.tsx # System notifications management
    └── PowerButtons.tsx  # System control buttons
```

## Dependencies

Make sure you have these tools installed:
- `playerctl` - for media control
- `pactl` (PulseAudio) - for audio control
- `brightnessctl` - for brightness control
- `sensors` (lm-sensors) - for temperature monitoring
- `nmcli` (NetworkManager) - for network information
- `dunstctl` or `makoctl` - for notification management
- `nvidia-smi` (optional) - for GPU monitoring on NVIDIA systems

### Install dependencies (Arch Linux):
```bash
sudo pacman -S playerctl pulseaudio brightnessctl lm_sensors networkmanager dunst
# For NVIDIA GPU monitoring:
# sudo pacman -S nvidia-utils
```

### Install dependencies (Ubuntu/Debian):
```bash
sudo apt install playerctl pulseaudio-utils brightnessctl lm-sensors network-manager dunst
# For NVIDIA GPU monitoring:
# sudo apt install nvidia-utils-xxx
```

## Features Detailed

### System Stats Widget
- **CPU Usage**: Real-time CPU utilization percentage
- **Memory Usage**: RAM usage percentage
- **GPU Usage**: GPU utilization (NVIDIA cards supported, shows N/A if not available)
- **Temperature**: CPU/system temperature from sensors
- **Power**: Power consumption from battery (shows N/A if not on battery)

### Media Player Widget
- **Track Information**: Title, artist, album
- **Playback Status**: Playing, paused, stopped
- **Position**: Current playback position and total duration
- **Controls**: Previous, play/pause, next buttons

### Network Info Widget
- **Connection**: Active network connection name
- **IP Address**: Current local IP address
- **Speed**: Real-time download/upload speeds

### Notification Center
- **Multi-daemon Support**: Works with dunst, mako, or fallback methods
- **Recent Notifications**: Shows up to 3 recent notifications
- **Clear Function**: Clear all notifications with one click

## Customization

The dashboard is fully customizable through:
- `style.scss` - Visual styling, colors, spacing, and animations
- Individual widget files - Functionality, polling intervals, and layout
- Command polling intervals (adjustable in each widget)

### Styling Classes
- `.dashboard-container` - Main container with slide animation
- `.widget-*` - Individual widget styling
- `.media-player-widget`, `.system-stats-widget`, etc. - Specific widget styles

## Animation

The dashboard includes smooth slide-in/out animations using CSS transforms:
- Slides in from the right side of the screen
- Cubic-bezier easing for smooth motion
- Fade effect combined with slide transition
- Wayland-compatible transparency and effects

## Troubleshooting

### Dashboard won't toggle
- Check if AGS is running: `./launch-ags.sh status`
- Restart AGS: `./launch-ags.sh restart`

### Missing data in widgets
- Check if required dependencies are installed
- Test commands manually (e.g., `playerctl status`, `sensors`, `pactl list sinks`)

### GPU stats show "N/A"
- Install nvidia-utils for NVIDIA cards
- For AMD cards, the widget may need modification to use `radeontop` or similar tools

### Network speeds show 0
- Check if NetworkManager is running: `systemctl status NetworkManager`
- Verify network interface names with `ip link`

## Performance

- Polling intervals are optimized for balance between responsiveness and system load
- System stats update every 2-3 seconds
- Media info updates every 1 second
- Network speeds update every 3 seconds
- All commands are lightweight and cached appropriately

# 🎨 Color Profile Toggle Script - Documentation

## Overview

The toggle script allows you to easily switch between color profiles using an interactive Fuzzel menu. It automatically updates all connected applications and reloads them.

## Files

```
~/.config/themes/
├── toggle-profile.sh              ← Simple version
└── toggle-profile-advanced.sh     ← Advanced version (recommended)

~/.local/bin/
└── toggle-profile                 ← Wrapper script
```

## Installation

### Step 1: Make scripts executable

```bash
chmod +x ~/.config/themes/toggle-profile.sh
chmod +x ~/.config/themes/toggle-profile-advanced.sh
chmod +x ~/.local/bin/toggle-profile
```

### Step 2: Ensure ~/.local/bin is in PATH

Add to your shell config (~/.config/fish/config.fish or ~/.bashrc):

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Step 3: Verify installation

```bash
toggle-profile --help
```

## Usage

### Interactive Mode (Recommended)

Open Fuzzel to select a profile:

```bash
toggle-profile
```

Or use the advanced version directly:

```bash
~/.config/themes/toggle-profile-advanced.sh
```

### Command Line Mode

```bash
# Show current profile
toggle-profile current

# List all available profiles
toggle-profile list

# Switch to a specific profile
toggle-profile set nonchalant-purp
toggle-profile set default

# Show help
toggle-profile --help
```

## Features

✅ **Interactive Selection** - Uses Fuzzel for profile selection  
✅ **Multiple Profiles** - Supports default and nonchalant-purp  
✅ **Auto-Reload** - Automatically reloads Waybar  
✅ **Notifications** - Shows status notifications  
✅ **Smart Switching** - Only updates if profile changes  
✅ **Fallback Menu** - Works without Fuzzel (simple menu)  
✅ **Command Line** - Direct profile switching without Fuzzel  

## Keybinding (Optional)

### In Hyprland (~/.config/hypr/hyprland.conf)

```conf
# Super+T to toggle color profile
bind = SUPER, T, exec, toggle-profile
```

### In Niri (~/.config/niri/config.kdl)

```kdl
bind "mod Super+T" { spawn "toggle-profile"; }
```

### In Fish (~/.config/fish/config.fish)

Create a function:

```fish
function toggle_profile
    ~/.config/themes/toggle-profile-advanced.sh $argv
end
```

## What Gets Updated

### CSS Applications (Auto-Updated)
- **Waybar** - `~/.config/waybar/style.css`
- **Wlogout** - `~/.config/wlogout/nova.css`
- **Wlogout Colors** - `~/.config/wlogout/colors.css`

These use CSS `@import` statements, so they're updated automatically.

### Other Applications (Manual Update Available)
- **Kitty** - `~/.config/kitty/colors.conf`
- **Hyprland** - `~/.config/hypr/hyprland/colors.conf`
- **Hyprlock** - `~/.config/hypr/hyprlock.conf`
- **Fuzzel** - `~/.config/fuzzel/fuzzel_theme.ini`
- **Dunst** - `~/.config/dunst/dunstrc`
- **Niri** - `~/.config/niri/config.kdl`

The script can update these partially, but for full updates you may need to manually update hex values.

## Examples

### Example 1: Basic Toggle

```bash
$ toggle-profile
# Fuzzel appears with profile list
# Select "nonchalant-purp"
# Waybar reloads with new colors
```

### Example 2: Command Line Switch

```bash
$ toggle-profile current
Current Profile: default
Description: Default - Modern, vibrant green/blue accents

$ toggle-profile set nonchalant-purp
🎨 Switching color profile...
  From: default
  To:   nonchalant-purp

Colors for nonchalant-purp profile:
  Background:  #1e1e20
  Foreground:  #dcd9e7
  Accent:      #c59edc
  Highlight:   #c3fb5b
  Caution:     #ffb86c
  Urgent:      #ff6e79
  Tray:        #2a2a2c
  Border:      #3a3a3d

✅ Profile switched successfully!
```

### Example 3: List Profiles

```bash
$ toggle-profile list
Available Color Profiles:
==========================
✓ nonchalant-purp (active) - Nonchalant Purp - Sophisticated violet/lime
  default - Default - Modern, vibrant green/blue accents
```

## Customizing the Script

### Add a New Profile

1. Create the profile files:
   - `~/.config/themes/my-profile.css`
   - `~/.config/themes/colors-my-profile.sh`
   - `~/.config/themes/my-profile-kitty.conf`

2. Update the toggle script:

```bash
# Edit toggle-profile-advanced.sh
declare -A PROFILES=(
    ["default"]="..."
    ["nonchalant-purp"]="..."
    ["my-profile"]="My Profile - Description"  # Add this
)

declare -A COLORS_MY_PROFILE=(
    ["bg"]="#XXXXXX"
    ["fg"]="#XXXXXX"
    # ... more colors
)
```

### Change Fuzzel Options

In `toggle-profile-advanced.sh`, find the fuzzel command:

```bash
choice=$(printf '%s\n' "${!PROFILES[@]}" | fuzzel --dmenu \
    --prompt="Select Color Profile: " \
    --lines=10 \
    --width=50 \
    2>/dev/null)
```

Options:
- `--lines=10` - Number of lines to display
- `--width=50` - Width of the dialog
- `--prompt="text"` - Prompt text
- `--font="font_name"` - Font to use

For more fuzzel options, see `man fuzzel` or `fuzzel --help`.

## Troubleshooting

### Fuzzel not found

If Fuzzel is not installed:

```bash
# Install Fuzzel
sudo pacman -S fuzzel  # Arch
# or your package manager

# The script will fall back to a simple menu if Fuzzel is unavailable
```

### Script not found in PATH

```bash
# Verify ~/.local/bin is in PATH
echo $PATH

# If not present, add to ~/.bashrc or ~/.config/fish/config.fish
export PATH="$HOME/.local/bin:$PATH"

# Then reload shell
source ~/.bashrc
# or restart your terminal
```

### Waybar not reloading

The script tries to reload Waybar automatically. If it doesn't work:

```bash
# Manual reload
killall waybar
waybar &
```

### Colors not updating in some apps

Some applications like Hyprland, Dunst, and Niri use configuration files with hardcoded hex values. The toggle script displays the colors but doesn't automatically update these files for full compatibility.

**Solution:** Manually update the hex values in these config files:

```bash
# Find which colors to use
~/.config/themes/toggle-profile-advanced.sh current

# Then manually edit the config files with the displayed colors
vim ~/.config/hypr/hyprland/colors.conf
vim ~/.config/dunst/dunstrc
vim ~/.config/niri/config.kdl
```

## Performance

- ⚡ Very fast - updates only necessary files
- ✅ Minimal disk I/O - only sed operations
- 🔄 Smart reload - only reloads running applications
- 📝 Logs output - shows what it's doing

## Advanced: Creating a Profile Switcher Menu

Create a more visual menu in Fish:

```fish
#!/usr/bin/env fish
# ~/.config/fish/functions/theme.fish

function theme
    if test (count $argv) -eq 0
        ~/.config/themes/toggle-profile-advanced.sh
    else
        ~/.config/themes/toggle-profile-advanced.sh set $argv[1]
    end
end
```

Then use:

```bash
theme                    # Interactive Fuzzel menu
theme nonchalant-purp    # Direct switch
theme current            # Show current profile
theme list               # List all profiles
```

## Tips

1. **Set a keybinding** - Bind toggle-profile to a keyboard shortcut for quick switching
2. **Create aliases** - Add `alias tp='toggle-profile'` to your shell
3. **Automate switching** - Use cron or systemd timers to switch profiles by time of day
4. **Create variants** - Make lighter/darker versions of each profile
5. **Test before switching** - Use `toggle-profile list` to see available profiles first

---

Enjoy quick and easy color profile switching! 🎨

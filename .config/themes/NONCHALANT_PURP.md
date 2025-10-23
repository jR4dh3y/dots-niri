# 🎨 NONCHALANT PURP - Color Profile

## Overview

**Nonchalant Purp** is a sophisticated dark theme featuring soft violet-magenta accents with vibrant lime highlights. It's designed to be easy on the eyes while maintaining excellent contrast and readability.

## Color Palette

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| Background | `#1e1e20` | Deep graphite black | Primary background |
| Foreground | `#dcd9e7` | Pale lilac-white | Main text color |
| Surface/Panel | `#2a2a2c` | Neutral dark | Secondary background |
| Primary Accent | `#c59edc` | Soft violet-magenta | Highlights, accents |
| Secondary Accent | `#e6dfef` | Pale lilac-white | Contrast elements |
| Highlight/Pop | `#c3fb5b` | Vibrant lime | Energy, important elements |
| Warning | `#ffb86c` | Warm amber | Alerts, caution |
| Error | `#ff6e79` | Bright pink-red | Errors, urgent |
| Text (Muted) | `#9c96ad` | Dimmed text | Secondary info |
| Border/Divider | `#3a3a3d` | Subtle tone | Borders, separation |
| Selection/Active | `#4a3b5f` | Soft violet-gray | Selected states |

## Files in This Profile

```
~/.config/themes/
├── nonchalant-purp.css              ← CSS variables for GTK apps
├── colors-nonchalant-purp.sh        ← Shell environment variables
└── nonchalant-purp-kitty.conf       ← Kitty terminal colors
```

## How to Use

### Option 1: Switch to This Profile (CSS Apps)

Update your CSS files to use this profile:

```css
@import url("../themes/nonchalant-purp.css");

background: @bg_color;
color: @fg_color;
```

### Option 2: Use Shell Variables

```bash
source ~/.config/themes/colors-nonchalant-purp.sh

# Use the variables
notify-send "Background: $COLOR_BG"
echo "Accent: $COLOR_ACCENT"
```

### Option 3: Use Kitty Profile

In your `~/.config/kitty/kitty.conf`:

```conf
# Include the nonchalant-purp color profile
include nonchalant-purp-kitty.conf
```

Or directly reference the hex values from `~/.config/themes/nonchalant-purp-kitty.conf`.

## Color Characteristics

### Deep Graphite Background
- **Hex:** `#1e1e20`
- **Why:** Soft on the eyes, reduces eye strain in low-light environments
- **Best for:** Overall background color

### Soft Violet-Magenta Accent
- **Hex:** `#c59edc`
- **Why:** Sophisticated, calming yet distinctive
- **Best for:** Primary highlights, active elements, focus indicators

### Vibrant Lime Highlight
- **Hex:** `#c3fb5b`
- **Why:** Energetic and attention-grabbing without being harsh
- **Best for:** Important notifications, selection highlights, energy indicators

### Warm Amber Warning
- **Hex:** `#ffb86c`
- **Why:** Recognizable as caution without being alarming
- **Best for:** Warnings, temporary alerts, secondary emphasize

### Bright Pink-Red Error
- **Hex:** `#ff6e79`
- **Why:** Clear and immediate visual feedback
- **Best for:** Errors, critical alerts, dangerous actions

### Pale Lilac-White Text
- **Hex:** `#dcd9e7`
- **Why:** Excellent contrast with dark background, easy to read
- **Best for:** Main text and UI elements

## Comparison to Default Profile

| Aspect | Default | Nonchalant Purp |
|--------|---------|-----------------|
| Background | `#1A1B26` | `#1e1e20` |
| Text | `#C0CAF5` | `#dcd9e7` |
| Primary Accent | `#9ECE6A` (Green) | `#c59edc` (Violet) |
| Highlight | `#7AA2F7` (Blue) | `#c3fb5b` (Lime) |
| Error | `#F7768E` (Red) | `#ff6e79` (Pink-Red) |
| Warning | `#E0AF68` (Yellow) | `#ffb86c` (Amber) |

## Applications Compatible with This Profile

- **Waybar** - CSS apps using `@import`
- **Wlogout** - CSS apps using `@import`
- **Kitty** - Using the dedicated config file
- **Hyprland** - Using hex values directly
- **Hyprlock** - Using hex values directly
- **Fuzzel** - Using hex values directly
- **Dunst** - Using hex values directly
- **Niri** - Using hex values directly

## Tips for Using This Profile

### For CSS-Based Apps
Copy the profile's hex values into your app's CSS and adjust as needed:

```css
@import url("../themes/nonchalant-purp.css");

#waybar {
    background: @bg_color;
    color: @fg_color;
}

#workspaces button.focused {
    background: @accent_color;
    color: @bg_color;
}

#workspaces button.urgent {
    background: @urgent_color;
    color: @bg_color;
}
```

### For Terminal Applications
Use the provided kitty colors file as a template for other terminals:

```ini
; In your terminal config
[colors]
background = 1e1e20
foreground = dcd9e7
color0 = 1e1e20
color1 = ff6e79
```

### For Configuration Files
Reference the hex values directly with comments:

```conf
# Nonchalant Purp theme colors
background = #1e1e20
foreground = #dcd9e7
accent = #c59edc
```

## Creating Variants

You can create lighter or darker variants by adjusting the background and foreground values:

**Lighter variant:**
```css
@define-color bg_color #2a2a2c;      /* +20% brightness */
@define-color fg_color #e8e5f3;      /* +5% brightness */
```

**Darker variant:**
```css
@define-color bg_color #16161a;      /* -10% brightness */
@define-color fg_color #d0cdd9;      /* -5% brightness */
```

## Color Psychology

This profile uses:
- **Cool tones** (purples, blues) for a calm, sophisticated feel
- **Warm accents** (amber, red) for contrast and urgency
- **High contrast** between background and foreground for readability
- **Muted secondary colors** to avoid visual clutter

## Profile Metadata

| Property | Value |
|----------|-------|
| Name | nonchalant-purp |
| Theme Type | Dark |
| Primary Color | Violet-Magenta |
| Highlight Color | Lime Green |
| Best For | Dark environments, professionals, VI users |
| Created | 2025-10-23 |
| Compatible Platforms | Linux (GTK, KDE, Wayland) |

## Support

For questions or issues with this profile:
1. Check the main theme README: `~/.config/themes/README.md`
2. View all available profiles: `ls ~/.config/themes/nonchalant-purp*`
3. Compare with other profiles in `~/.config/themes/`

---

**Enjoy your new Nonchalant Purp theme!** 🎨

# 🎨 Color Profiles - Switching Guide

## Available Profiles

Your color system now supports multiple profiles:

### 1. **Default Profile** (Currently Active)
- **File:** `~/.config/themes/global-colors.css`
- **Name:** Default
- **Style:** Modern, vibrant with greens and blues
- **Shell Variables:** `~/.config/themes/colors.sh`
- **Best for:** General use, modern aesthetic

### 2. **Nonchalant Purp** (New!)
- **File:** `~/.config/themes/nonchalant-purp.css`
- **Name:** Nonchalant Purp
- **Style:** Sophisticated dark with violet-magenta accents
- **Shell Variables:** `~/.config/themes/colors-nonchalant-purp.sh`
- **Kitty Colors:** `~/.config/themes/nonchalant-purp-kitty.conf`
- **Best for:** Dark environments, professionals, low-light settings

## How to Switch Profiles

### For CSS-Based Apps (Waybar, Wlogout)

**Current:**
```css
@import url("../themes/global-colors.css");
```

**Switch to Nonchalant Purp:**
```css
@import url("../themes/nonchalant-purp.css");
```

### For Config Files (Kitty, Hyprland, etc.)

Replace the hex values with the new profile's values:

**Current (Global Colors):**
```
foreground = #C0CAF5
background = #1A1B26
accent = #9ECE6A
```

**Switch to Nonchalant Purp:**
```
foreground = #dcd9e7
background = #1e1e20
accent = #c59edc
```

### For Shell Scripts

**Current:**
```bash
source ~/.config/themes/colors.sh
```

**Switch to Nonchalant Purp:**
```bash
source ~/.config/themes/colors-nonchalant-purp.sh
```

## Quick Switch Script (Optional)

Create `~/.config/themes/switch-profile.sh`:

```bash
#!/bin/bash
# Theme Profile Switcher

PROFILE=$1
THEME_DIR="$HOME/.config/themes"

case "$PROFILE" in
    default)
        echo "Switching to Default theme..."
        sed -i 's|global-colors.css|nonchalant-purp.css|g' ~/.config/waybar/style.css
        sed -i 's|global-colors.css|nonchalant-purp.css|g' ~/.config/wlogout/nova.css
        ;;
    nonchalant-purp)
        echo "Switching to Nonchalant Purp theme..."
        sed -i 's|nonchalant-purp.css|global-colors.css|g' ~/.config/waybar/style.css
        sed -i 's|nonchalant-purp.css|global-colors.css|g' ~/.config/wlogout/nova.css
        ;;
    *)
        echo "Usage: switch-profile.sh [default|nonchalant-purp]"
        exit 1
        ;;
esac

echo "Theme switched! Reload applications to see changes."
```

Usage:
```bash
bash ~/.config/themes/switch-profile.sh nonchalant-purp
```

## Color Comparison

| Feature | Default | Nonchalant Purp |
|---------|---------|-----------------|
| Background | #1A1B26 (Dark blue) | #1e1e20 (Deep graphite) |
| Foreground | #C0CAF5 (Lavender) | #dcd9e7 (Pale lilac) |
| Primary Accent | #9ECE6A (Green) | #c59edc (Violet-magenta) |
| Highlight | #7AA2F7 (Blue) | #c3fb5b (Lime) |
| Error | #F7768E (Red) | #ff6e79 (Pink-red) |
| Warning | #E0AF68 (Yellow) | #ffb86c (Amber) |

## Step-by-Step: Switch to Nonchalant Purp

### Step 1: Update Waybar
```bash
vim ~/.config/waybar/style.css
# Change: @import url("../themes/global-colors.css");
# To:     @import url("../themes/nonchalant-purp.css");
```

### Step 2: Update Wlogout
```bash
vim ~/.config/wlogout/nova.css
# Change: @import url("../themes/global-colors.css");
# To:     @import url("../themes/nonchalant-purp.css");
```

### Step 3: Update Kitty (Optional)
```bash
# In ~/.config/kitty/kitty.conf, change:
# include ~/.config/themes/kitty/colors.conf
# To:
# include ~/.config/themes/nonchalant-purp-kitty.conf
```

### Step 4: Update Config Files (Optional)
Update hex values in:
- `~/.config/hypr/hyprland/colors.conf`
- `~/.config/hypr/hyprlock.conf`
- `~/.config/fuzzel/fuzzel_theme.ini`
- `~/.config/dunst/dunstrc`
- `~/.config/niri/config.kdl`

Use the color values from `~/.config/themes/NONCHALANT_PURP.md`

### Step 5: Reload Applications

Some apps pick up changes automatically, others need:
```bash
# Reload individual apps
killall waybar && waybar &
killall hyprlock  # Will restart on next lock
```

## Creating New Profiles

To create a new profile:

1. **Create CSS file:** `~/.config/themes/your-profile.css`
```css
@define-color bg_color #YOUR_HEX;
@define-color fg_color #YOUR_HEX;
/* ... more colors ... */
```

2. **Create shell variables:** `~/.config/themes/colors-your-profile.sh`
```bash
export COLOR_BG="#YOUR_HEX"
export COLOR_FG="#YOUR_HEX"
/* ... more colors ... */
```

3. **Create documentation:** `~/.config/themes/YOUR_PROFILE.md`
- List all colors with descriptions
- Usage examples
- Best practices for this theme

4. **Create terminal colors:** `~/.config/themes/your-profile-kitty.conf`
- 16-color palette for terminals

## Pro Tips

- **Keep profiles symmetrical** - Use similar contrast ratios across profiles
- **Test colors** - Use `bash ~/.config/themes/preview.sh` to see colors
- **Create variants** - Lighter/darker versions of the same profile
- **Use profile names consistently** - `theme-name.css`, `colors-theme-name.sh`
- **Document thoroughly** - Include rationale for color choices

## Reverting to Default

If you want to revert to the default profile:

```bash
# Find and replace all nonchalant-purp references
find ~/.config -type f -name "*.css" -o -name "*.ini" -o -name "*.conf" | xargs grep -l "nonchalant-purp"

# Then edit each file to use global-colors.css instead
```

## Next Steps

- Review the new profile: `cat ~/.config/themes/NONCHALANT_PURP.md`
- Test the colors: `source ~/.config/themes/colors-nonchalant-purp.sh && echo $COLOR_BG`
- Switch your apps to use the new profile
- Enjoy! 🎨

---

**Pro Tip:** You can have multiple profiles active in different apps for a hybrid look, or create profile variants for different times of day!

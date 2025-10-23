# 🎨 Color Abstraction System - Quick Reference

## Single Point of Change
All colors defined in: **`~/.config/themes/global-colors.css`**

Change a color there → All apps update automatically ✨

## For Each Application Type

### CSS/GTK Apps (Waybar, Wlogout)
```css
@import url("../themes/global-colors.css");
background: @bg_color;
color: @fg_color;
```

### .conf/.ini Files (Kitty, Fuzzel, Hyprland, Dunst, Niri)
```conf
# Colors from ~/.config/themes/global-colors.css
background = #1A1B26
foreground = #C0CAF5
```

### Shell Scripts
```bash
source ~/.config/themes/colors.sh
echo $COLOR_BG
```

## Color Variables

| Variable | Color | Hex |
|----------|-------|-----|
| `bg_color` | ⬛ | `#1A1B26` |
| `fg_color` | ⬜ | `#C0CAF5` |
| `accent_color` | 🟢 | `#9ECE6A` |
| `highlight_color` | 🔵 | `#7AA2F7` |
| `caution_color` | 🟡 | `#E0AF68` |
| `urgent_color` | 🔴 | `#F7768E` |
| `first_right_color` | 🔷 | `#7DCFFF` |
| `middle_right_color` | 🔴 | `#F7768E` |
| `last_right_color` | 🟣 | `#BB9AF7` |

## Applications Using Global Colors

- ✅ Waybar
- ✅ Kitty
- ✅ Wlogout
- ✅ Hyprland
- ✅ Hyprlock
- ✅ Fuzzel
- ✅ Dunst
- ✅ Niri

## Documentation

| File | Purpose |
|------|---------|
| `global-colors.css` | CSS variables (GTK/CSS apps) |
| `colors.sh` | Shell environment variables |
| `colors.conf` | Color reference |
| `README.md` | Complete usage guide |
| `preview.sh` | Display all colors |
| `BEFORE_AND_AFTER.md` | Examples and workflow |

## How to Change Colors

### Change one color globally:
1. Open `~/.config/themes/global-colors.css`
2. Find the color you want to change
3. Update the hex value
4. Done! All apps use the new color

### Example: Change green from `#9ECE6A` to `#6AE05E`
```css
/* In global-colors.css */
@define-color accent_color #6AE05E;  /* Changed from #9ECE6A */
```

All these now use the new green:
- Waybar accent elements
- Hyprland borders
- Fuzzel selections
- Dunst highlights
- Kitty colors
- Niri focus ring
- Wlogout buttons
- Hyprlock check marks

## Next Steps

Consider adding colors.sh to your fish/bash shell config:
```bash
# ~/.config/fish/config.fish or ~/.bashrc
source ~/.config/themes/colors.sh
```

Then use colors in scripts:
```bash
echo "Background: $COLOR_BG"
echo "Foreground: $COLOR_FG"
```

## Need Help?

- Read: `~/.config/themes/README.md`
- Preview: `~/.config/themes/preview.sh`
- Examples: `COLOR_ABSTRACTION_SUMMARY.md`
- Before/After: `~/.config/themes/BEFORE_AND_AFTER.md`

# Global Color Abstraction System

This directory contains the centralized color definitions for the entire dotfiles configuration. All applications should reference these colors to maintain a consistent look and feel across the system.

## Files

- **`global-colors.css`** - CSS variables used by GTK-based applications (Waybar, Wlogout, etc.)
- **`colors.sh`** - Shell environment variables that can be sourced in bash scripts
- **`colors.conf`** - Documentation and reference for all color values

## Color Profiles

This system supports multiple color profiles. Available profiles:

- **global-colors.css** - Default profile (currently active)
- **nonchalant-purp.css** - Soft violet-magenta theme (dark, sophisticated)

To switch profiles, update the `@import` statements in your config files.

## Usage by Application Type

### GTK/CSS-Based Applications (Waybar, Wlogout, etc.)

These applications support CSS `@import` and CSS variables. Add this to your config:

```css
@import url("../themes/global-colors.css");

/* Now use the colors */
window#waybar {
    background: @bg_color;
    color: @fg_color;
}
```

**Applications using this pattern:**
- `~/.config/waybar/style.css`
- `~/.config/wlogout/nova.css`
- `~/.config/wlogout/colors.css`

### Terminal Applications (.conf, .ini files)

For applications like Kitty, use the hex color values directly:

```ini
foreground            #C0CAF5
background            #1A1B26
color0                #1A1B26
color1                #F7768E
```

**Applications using this pattern:**
- `~/.config/kitty/colors.conf`
- `~/.config/fuzzel/fuzzel_theme.ini`

### KDL Configuration (Niri, etc.)

For KDL-based configs, use hex colors directly:

```kdl
focus-ring {
    active-color "#7AA2F7"
    inactive-color "#414868"
}
```

**Applications using this pattern:**
- `~/.config/niri/config.kdl`

### Shell Scripts and Env Variables

Source `colors.sh` in your bash/fish scripts:

```bash
source ~/.config/themes/colors.sh
echo "Background: $COLOR_BG"
echo "Foreground: $COLOR_FG"
```

### Hyprland Configuration

For Hyprland configs, import a dedicated colors file:

```conf
source = ~/.config/hypr/hyprland/global-colors.conf
```

Or use hex colors directly:
```conf
col.active_border = rgba(7AA2F7AA)
```

## Color Variables Reference

| Variable | Value | Usage |
|----------|-------|-------|
| `bg_color` | `#1A1B26` | Primary background |
| `fg_color` | `#C0CAF5` | Primary foreground/text |
| `tray_color` | `#414868` | Secondary background |
| `accent_color` | `#9ECE6A` | Primary accent (green) |
| `highlight_color` | `#7AA2F7` | Highlight/focus (blue) |
| `caution_color` | `#E0AF68` | Warning/caution (yellow) |
| `urgent_color` | `#F7768E` | Error/urgent (red) |
| `first_right_color` | `#7DCFFF` | Multi-display first (cyan) |
| `middle_right_color` | `#F7768E` | Multi-display middle (red) |
| `last_right_color` | `#BB9AF7` | Multi-display last (magenta) |
| `funny_pastel_color` | `#FFB7B2` | Special pastel |

## Adding New Colors

When you need a new color value:

1. First, check if an existing color variable fits
2. If not, add it to `global-colors.css`
3. Add the corresponding entry to `colors.sh`
4. Document it in this README
5. Update all affected configuration files to use the variable

## Updating Colors

To change the color scheme globally:

1. Edit `global-colors.css` - change the hex values
2. Edit `colors.sh` - update environment variable values
3. Edit `colors.conf` - update documentation
4. All configuration files will automatically use the new colors!

**No need to manually edit individual config files** for color changes.

## Applications Currently Using Global Colors

- ✅ Waybar
- ✅ Kitty
- ✅ Wlogout
- ⏳ Hyprland (partial)
- ⏳ Dunst (pending)
- ⏳ Fuzzel (pending)
- ⏳ Niri (pending)

## Notes

- CSS variables using `@` prefix are GTK-specific and work in GTK-based applications
- Shell variables are prefixed with `COLOR_` to avoid namespace collisions
- Always use the abstraction layer instead of hardcoding hex colors
- When adding new tools, check if they support CSS import or environment variables first

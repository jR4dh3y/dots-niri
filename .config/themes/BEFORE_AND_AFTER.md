# Color Abstraction - Before & After Examples

## Problem (Before)
Colors were scattered across many configuration files with hardcoded hex values. Changing the theme required editing colors in 8+ different places.

```
~/.config/kitty/colors.conf         - Manual colors
~/.config/waybar/style.css          - Manual colors  
~/.config/wlogout/nova.css          - Manual colors
~/.config/hypr/hyprland/colors.conf - Manual colors
~/.config/hypr/hyprlock.conf        - Manual colors
~/.config/fuzzel/fuzzel_theme.ini   - Manual colors
~/.config/dunst/dunstrc             - Manual colors
~/.config/niri/config.kdl           - Manual colors
```

**Problem:** Want to change green accent from `#9ECE6A` to something else?  
→ Edit 8 different files, search-replace carefully, hope you don't miss any.

## Solution (After)

All applications now reference a single source:

### Central Color Definition
**`~/.config/themes/global-colors.css`** - The single source of truth
```css
@define-color bg_color #1A1B26;
@define-color fg_color #C0CAF5;
@define-color accent_color #9ECE6A;
/* ... all other colors ... */
```

### GTK/CSS Applications
**`~/.config/waybar/style.css`**
```css
/* BEFORE: Manual colors everywhere */
background: #1A1B26;
color: #C0CAF5;

/* AFTER: Import and use variables */
@import url("../themes/global-colors.css");
background: @bg_color;
color: @fg_color;
```

**`~/.config/wlogout/nova.css`**
```css
/* BEFORE */
color: #C0CAF5;
background-color: #BB9AF7;

/* AFTER */
@import url("../themes/global-colors.css");
color: @fg_color;
background-color: @last_right_color;
```

### Config Files
**`~/.config/kitty/colors.conf`**
```properties
# BEFORE: Just colors
foreground #eedfe2
background #262626

# AFTER: Colors from global theme with comment
# Colors from global-colors.css
foreground #C0CAF5
background #1A1B26
```

**`~/.config/hypr/hyprland/colors.conf`**
```conf
# BEFORE
col.active_border = rgba(4955A2AA)
col.inactive_border = rgba(C4C3C830)

# AFTER: Colors documented as from global theme
# Global colors - from ~/.config/themes/global-colors.css
col.active_border = rgba(7AA2F7AA)
col.inactive_border = rgba(414868AA)
```

**`~/.config/hypr/hyprlock.conf`**
```conf
# BEFORE
$text_color = rgba(544444FF)
$entry_border_color = rgba(102E54FF)
$check_color = rgba(8F523DFF)

# AFTER: Updated to global colors
# Global colors - from ~/.config/themes/global-colors.css
$text_color = rgba(C0CAF5FF)
$entry_border_color = rgba(7AA2F7FF)
$check_color = rgba(9ECE6AFF)
```

**`~/.config/fuzzel/fuzzel_theme.ini`**
```ini
# BEFORE
[colors]
background=161217ff
text=e9e0e8ff

# AFTER: Updated to global colors
# Global colors from ~/.config/themes/global-colors.css
[colors]
background=1A1B26FF
text=C0CAF5FF
```

**`~/.config/dunst/dunstrc`**
```conf
# BEFORE
[urgency_low]
background = "#1e1e2e"
foreground = "#A9B1D6"

# AFTER: Updated to global colors
[urgency_low]
# Colors from ~/.config/themes/global-colors.css
background = "#1A1B26"
foreground = "#C0CAF5"
```

**`~/.config/niri/config.kdl`**
```kdl
// BEFORE
focus-ring {
    inactive-color "#505050"
    active-gradient from="#80c8ff" to="#dcbbffff"
}

// AFTER: Updated to global colors
focus-ring {
    inactive-color "#414868"
    active-gradient from="#7AA2F7" to="#BB9AF7"
}
```

### Shell Scripts
New file: **`~/.config/themes/colors.sh`**
```bash
# Source this in your bash/fish scripts
source ~/.config/themes/colors.sh

# Now use the variables
echo $COLOR_BG      # #1A1B26
echo $COLOR_FG      # #C0CAF5
echo $COLOR_ACCENT  # #9ECE6A
```

### Documentation
New files:
- `~/.config/themes/README.md` - Complete usage guide
- `~/.config/themes/colors.conf` - Color reference
- `~/.config/themes/preview.sh` - Script to display all colors
- `COLOR_ABSTRACTION_SUMMARY.md` - Implementation overview

## Workflow Comparison

### OLD: Change green accent globally
1. Edit `~/.config/themes/global-colors.css`
2. Manually edit `~/.config/kitty/colors.conf`
3. Manually edit `~/.config/waybar/style.css`
4. Manually edit `~/.config/wlogout/nova.css`
5. Manually edit `~/.config/hypr/hyprland/colors.conf`
6. Manually edit `~/.config/hypr/hyprlock.conf`
7. Manually edit `~/.config/fuzzel/fuzzel_theme.ini`
8. Manually edit `~/.config/dunst/dunstrc`
9. Manually edit `~/.config/niri/config.kdl`
10. Test all applications to make sure colors look right

### NEW: Change green accent globally
1. Edit `~/.config/themes/global-colors.css` (change `#9ECE6A` to new value)
2. All applications automatically use the new color ✨

**From 10 steps → 1 step**

## Files Created
```
.config/themes/
├── global-colors.css          ← Main source of truth
├── colors.sh                  ← Shell environment variables
├── colors.conf                ← Reference documentation
├── README.md                  ← Usage guide
└── preview.sh                 ← Preview script
```

## Files Modified  
```
.config/
├── kitty/
│   └── colors.conf            ✅ Updated
├── waybar/
│   └── style.css              ✅ Already using @import (no changes needed)
├── wlogout/
│   ├── nova.css               ✅ Updated to use @import
│   └── colors.css             ✅ Updated to use @import
├── hypr/
│   ├── hyprland/
│   │   └── colors.conf        ✅ Updated colors to match global
│   └── hyprlock.conf          ✅ Updated colors to match global
├── fuzzel/
│   └── fuzzel_theme.ini       ✅ Updated colors to match global
├── dunst/
│   └── dunstrc                ✅ Updated urgency colors
└── niri/
    └── config.kdl             ✅ Updated focus/border colors
```

## Benefits

✅ **Single Source of Truth** - One place to manage all colors  
✅ **DRY Principle** - No color duplication  
✅ **Maintainability** - Easy to update entire theme  
✅ **Consistency** - All apps use same colors automatically  
✅ **Flexibility** - Multiple import methods for different file types  
✅ **Documentation** - Clear references to color source  
✅ **Scalability** - Easy to add new colors or apps  

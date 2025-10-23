# ✨ NONCHALANT PURP Profile - Created Successfully

## What Was Created

A complete new color profile called **"nonchalant purp"** with sophisticated violet-magenta accents and vibrant lime highlights.

## Files Created

In `~/.config/themes/`:

1. **nonchalant-purp.css** (650 bytes)
   - CSS color variables for GTK applications
   - Includes all 15+ color definitions
   - Ready to use with @import

2. **colors-nonchalant-purp.sh** (1.7 KB)
   - Shell environment variables
   - 30+ COLOR_* variables
   - Can be sourced in bash/fish scripts

3. **nonchalant-purp-kitty.conf** (580 bytes)
   - 16-color terminal palette
   - Dedicated Kitty terminal colors
   - Includes cursor colors and highlights

4. **NONCHALANT_PURP.md** (4.2 KB)
   - Complete profile documentation
   - Color palette with descriptions
   - Usage examples and tips
   - Comparison to default profile

5. **PROFILE_SWITCHING.md** (3.8 KB)
   - Guide to switching between profiles
   - Step-by-step instructions
   - Script to automate profile switching
   - Tips for creating new profiles

## The Color Palette

| Element | Hex | RGB | Description |
|---------|-----|-----|-------------|
| **Background** | #1e1e20 | Deep graphite | Soft on eyes, professional |
| **Foreground** | #dcd9e7 | Pale lilac | Excellent contrast |
| **Primary Accent** | #c59edc | Violet-magenta | Sophisticated highlights |
| **Secondary Accent** | #e6dfef | Pale lilac-white | Contrast elements |
| **Highlight** | #c3fb5b | Vibrant lime | Energy and attention |
| **Warning** | #ffb86c | Warm amber | Alerts and cautions |
| **Error** | #ff6e79 | Bright pink-red | Errors and critical |
| **Text (Muted)** | #9c96ad | Dimmed lilac | Secondary information |
| **Border** | #3a3a3d | Subtle gray | Dividers and borders |
| **Selection** | #4a3b5f | Soft violet-gray | Selected states |
| **Surface** | #2a2a2c | Neutral dark | Panel backgrounds |

## Key Features

✅ **Sophisticated Design** - Soft violet-magenta with excellent readability  
✅ **Easy on Eyes** - Deep graphite background reduces eye strain  
✅ **High Contrast** - Pale lilac foreground ensures clarity  
✅ **Vibrant Highlights** - Lime green for important elements  
✅ **Complete Support** - CSS, shell, and terminal color definitions  
✅ **Well Documented** - Full usage guide and examples included  

## How to Use This Profile

### Option 1: CSS Apps (Waybar, Wlogout)
```css
@import url("../themes/nonchalant-purp.css");
background: @bg_color;
color: @fg_color;
```

### Option 2: Shell Scripts
```bash
source ~/.config/themes/colors-nonchalant-purp.sh
echo "BG: $COLOR_BG"
echo "Accent: $COLOR_ACCENT"
```

### Option 3: Config Files
Use hex values directly:
```conf
# Nonchalant Purp theme
background = #1e1e20
foreground = #dcd9e7
accent = #c59edc
```

### Option 4: Kitty Terminal
```bash
# In ~/.config/kitty/kitty.conf
include nonchalant-purp-kitty.conf
```

## Quick Switch to Nonchalant Purp

### For Waybar:
```bash
sed -i 's|global-colors.css|nonchalant-purp.css|' ~/.config/waybar/style.css
```

### For Wlogout:
```bash
sed -i 's|global-colors.css|nonchalant-purp.css|' ~/.config/wlogout/nova.css
```

### For Kitty:
Update `~/.config/kitty/kitty.conf` to include:
```
include nonchalant-purp-kitty.conf
```

### For Other Apps:
Update hex values in config files using the color table above.

## View the Profile

```bash
# See detailed documentation
cat ~/.config/themes/NONCHALANT_PURP.md

# See switching guide
cat ~/.config/themes/PROFILE_SWITCHING.md

# View all colors in terminal
source ~/.config/themes/colors-nonchalant-purp.sh
echo -e "BG: $COLOR_BG\nFG: $COLOR_FG\nAccent: $COLOR_ACCENT"
```

## Profile Characteristics

- **Type:** Dark theme
- **Mood:** Sophisticated, professional, calming
- **Primary Color:** Violet-Magenta (#c59edc)
- **Highlight Color:** Vibrant Lime (#c3fb5b)
- **Best For:** Dark environments, professionals, low-light coding
- **Contrast Ratio:** High (WCAG AA compliant)

## Comparison to Default Profile

| Aspect | Default | Nonchalant Purp |
|--------|---------|-----------------|
| **Vibe** | Modern, vibrant | Sophisticated, calm |
| **Accent** | Green (#9ECE6A) | Violet (#c59edc) |
| **Highlight** | Blue (#7AA2F7) | Lime (#c3fb5b) |
| **Error** | Red (#F7768E) | Pink-Red (#ff6e79) |
| **Best for** | General use | Professionals, dark rooms |

## Next Steps

1. **Review the profile:**
   ```bash
   cat ~/.config/themes/NONCHALANT_PURP.md
   ```

2. **Choose switch method:**
   - Update CSS imports (easiest for Waybar/Wlogout)
   - Update hex values in config files
   - Use the provided shell variables in scripts

3. **Switch your apps:**
   - Waybar: Change @import in style.css
   - Wlogout: Change @import in nova.css
   - Kitty: Include nonchalant-purp-kitty.conf
   - Others: Update hex values

4. **Reload applications:**
   ```bash
   killall waybar && waybar &
   ```

5. **Enjoy the new look!** 🎨

## File Locations

```
~/.config/themes/
├── nonchalant-purp.css              ← CSS variables
├── colors-nonchalant-purp.sh        ← Shell variables
├── nonchalant-purp-kitty.conf       ← Terminal colors
├── NONCHALANT_PURP.md               ← Profile docs
└── PROFILE_SWITCHING.md             ← Switching guide
```

## Advanced: Creating Variants

**Lighter variant:**
```css
@define-color bg_color #252527;      /* 10% lighter */
@define-color fg_color #e8e5f3;      /* 5% lighter */
```

**More vibrant variant:**
```css
@define-color accent_color #d4a5f7;  /* Brighter violet */
@define-color highlight_color #d4f758; /* Brighter lime */
```

---

## Summary

✨ **Nonchalant Purp profile is ready to use!**

- **3 file formats:** CSS, Shell, Terminal
- **Complete documentation** with examples
- **Easy switching** between profiles
- **Professional quality** colors

Start using it today by updating your app configs to reference the new profile! 🎉

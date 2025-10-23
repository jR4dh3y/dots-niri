# Wlogout Themes

This folder contains theme configurations for Wlogout (logout menu).

## Available Themes

- **original.css** - Uses colors from the global-colors theme (default NvChad style)
- **nonchalant-purp.css** - Sophisticated dark theme with soft violet-magenta accents and vibrant lime highlights

## How to Switch Themes

Edit `~/.config/wlogout/colors.css` and change the import line:

```css
/* Switch to original theme */
@import url("themes/original.css");

/* Switch to nonchalant-purp theme */
@import url("themes/nonchalant-purp.css");
```

Then reload the wlogout menu (or restart your session).

## Color Reference

### Original Theme
- Background: #1A1B26
- Foreground: #C0CAF5
- Text Color: #C0CAF5
- Accent Colors: #7AA2F7, #9ECE6A, #F7768E, #E0AF68

### Nonchalant Purp Theme
- Background: #1e1e20
- Foreground: #e6dfef
- Text Color: #e6dfef
- Accent Colors: #c59edc, #c3fb5b, #ff6e79, #ffb86c

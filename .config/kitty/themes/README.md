# Kitty Themes

This folder contains theme configurations for Kitty terminal.

## Available Themes

- **original.conf** - Uses colors from the global-colors theme (default NvChad style)
- **nonchalant-purp.conf** - Sophisticated dark theme with soft violet-magenta accents and vibrant lime highlights

## How to Switch Themes

Edit `~/.config/kitty/kitty.conf` and change the include line:

```properties
# Switch to original theme
include themes/original.conf

# Switch to nonchalant-purp theme
include themes/nonchalant-purp.conf
```

Then reload Kitty by pressing Ctrl+Shift+F5 or restarting the application.

## Color Reference

### Original Theme
- Background: #1A1B26
- Foreground: #C0CAF5
- Red: #F7768E
- Green: #9ECE6A
- Yellow: #E0AF68
- Blue: #7AA2F7

### Nonchalant Purp Theme
- Background: #1e1e20
- Foreground: #e6dfef
- Red: #ff6e79
- Green: #c3fb5b
- Yellow: #ffb86c
- Purple: #c59edc

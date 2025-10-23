# Fuzzel Themes

This folder contains theme configurations for Fuzzel (application launcher).

## Available Themes

- **original.ini** - Uses colors from the global-colors theme (default NvChad style)
- **nonchalant-purp.ini** - Sophisticated dark theme with soft violet-magenta accents and vibrant lime highlights

## How to Switch Themes

Edit `~/.config/fuzzel/fuzzel.ini` and change the include line:

```ini
# Switch to original theme
include="~/.config/fuzzel/themes/original.ini"

# Switch to nonchalant-purp theme
include="~/.config/fuzzel/themes/nonchalant-purp.ini"
```

Then reload Fuzzel (it reloads automatically on config change).

## Color Reference

### Original Theme
- Background: #1a1b26
- Text: #c0caf5
- Selection: #7aa2f7
- Match: #9ece6a

### Nonchalant Purp Theme
- Background: #1e1e20
- Text: #e6dfef
- Selection: #c59edc
- Match: #c3fb5b

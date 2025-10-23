#!/usr/bin/env bash
# ASCII Art Visualization of Color Abstraction System

cat << 'EOF'

╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║              🎨  COLOR ABSTRACTION SYSTEM - ARCHITECTURE  🎨              ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝


                    ┌─────────────────────────────────┐
                    │  GLOBAL COLOR DEFINITIONS       │
                    │  ~/.config/themes/              │
                    │  global-colors.css              │
                    │                                 │
                    │  • bg_color: #1A1B26            │
                    │  • fg_color: #C0CAF5            │
                    │  • accent_color: #9ECE6A        │
                    │  • highlight_color: #7AA2F7     │
                    │  • urgent_color: #F7768E        │
                    │  • ... 8 more colors            │
                    └────────────────┬────────────────┘
                                     │
                    ┌────────────────┴────────────────┐
                    │                                 │
        ┌───────────▼────────────┐      ┌───────────▼────────────┐
        │  CSS/GTK APPS          │      │  CONFIG FILES          │
        │  @import url(...)      │      │  Direct hex refs       │
        │  Use @color_var        │      │  With comments         │
        │                        │      │                        │
        │  • Waybar              │      │  • Kitty               │
        │  • Wlogout             │      │  • Hyprland            │
        │  • (Future: more)      │      │  • Hyprlock            │
        │                        │      │  • Fuzzel              │
        └────────────────────────┘      │  • Dunst               │
                                        │  • Niri                │
                                        │                        │
                                        └────────────────────────┘
                    
                    ┌────────────────────────────────┐
                    │  SHELL VARIABLES               │
                    │  ~/.config/themes/colors.sh    │
                    │  source ~/.config/themes/...   │
                    │                                │
                    │  • $COLOR_BG                   │
                    │  • $COLOR_FG                   │
                    │  • $COLOR_ACCENT               │
                    │  • $COLOR_HIGHLIGHT            │
                    │  • ... 13+ variables           │
                    │                                │
                    │  Use in bash/fish scripts      │
                    └────────────────────────────────┘

╔═══════════════════════════════════════════════════════════════════════════╗
║                        WORKFLOW: CHANGE A COLOR                           ║
╚═══════════════════════════════════════════════════════════════════════════╝

    BEFORE:                          AFTER:
    ─────────────────────────────    ─────────────────────────────
    
    1. Edit kitty/colors.conf        1. Edit themes/global-colors.css
    2. Edit waybar/style.css         2. ✅ All apps updated!
    3. Edit wlogout/nova.css
    4. Edit hypr/colors.conf
    5. Edit hypr/hyprlock.conf
    6. Edit fuzzel/fuzzel_theme.ini
    7. Edit dunst/dunstrc
    8. Edit niri/config.kdl
    9. Test all apps
    
    ❌ 8 manual edits                ✅ 1 edit, automatic update


╔═══════════════════════════════════════════════════════════════════════════╗
║                          COLOR PALETTE REFERENCE                          ║
╚═══════════════════════════════════════════════════════════════════════════╝

    PRIMARY:
    ├─ Background:        #1A1B26  (Dark blue-black)
    └─ Foreground:        #C0CAF5  (Light lavender)

    SEMANTIC:
    ├─ Accent/Success:    #9ECE6A  (Green)
    ├─ Highlight/Info:    #7AA2F7  (Blue)
    ├─ Caution/Warning:   #E0AF68  (Yellow)
    └─ Urgent/Error:      #F7768E  (Red)

    COMPLEMENTARY:
    ├─ Cyan:              #7DCFFF
    ├─ Magenta:           #BB9AF7
    ├─ Tray/Secondary:    #414868
    └─ Pastel Special:    #FFB7B2

    16-COLOR TERMINAL PALETTE:
    ├─ 0: Black      (#1A1B26)
    ├─ 1: Red        (#F7768E)
    ├─ 2: Green      (#9ECE6A)
    ├─ 3: Yellow     (#E0AF68)
    ├─ 4: Blue       (#7AA2F7)
    ├─ 5: Magenta    (#BB9AF7)
    ├─ 6: Cyan       (#7DCFFF)
    ├─ 7: White      (#C0CAF5)
    └─ 8-15: Bright variants


╔═══════════════════════════════════════════════════════════════════════════╗
║                        DOCUMENTATION STRUCTURE                            ║
╚═══════════════════════════════════════════════════════════════════════════╝

    ~/.config/themes/
    ├─ global-colors.css ................. CSS variables (GTK)
    ├─ colors.sh ......................... Shell environment variables
    ├─ colors.conf ....................... Reference documentation
    ├─ README.md ......................... Complete usage guide
    ├─ QUICK_REFERENCE.md ............... Fast lookup
    ├─ BEFORE_AND_AFTER.md ............. Examples & improvements
    └─ preview.sh ....................... Color display script

    root/
    ├─ COLOR_ABSTRACTION_SUMMARY.md ..... Overview
    └─ IMPLEMENTATION_COMPLETE.md ....... This summary


╔═══════════════════════════════════════════════════════════════════════════╗
║                         QUICK START COMMANDS                              ║
╚═══════════════════════════════════════════════════════════════════════════╝

    View all colors:
    $ bash ~/.config/themes/preview.sh

    Use colors in script:
    $ source ~/.config/themes/colors.sh
    $ echo "BG: $COLOR_BG, FG: $COLOR_FG"

    Read documentation:
    $ cat ~/.config/themes/QUICK_REFERENCE.md
    $ cat ~/.config/themes/README.md
    $ cat ~/.config/themes/BEFORE_AND_AFTER.md

    Edit colors:
    $ vim ~/.config/themes/global-colors.css


╔═══════════════════════════════════════════════════════════════════════════╗
║                              APPLICATIONS                                  ║
╚═══════════════════════════════════════════════════════════════════════════╝

    ✅ Waybar              - CSS @import
    ✅ Kitty               - Hex references
    ✅ Wlogout             - CSS @import
    ✅ Hyprland            - Hex references
    ✅ Hyprlock            - Hex references
    ✅ Fuzzel              - Hex references
    ✅ Dunst               - Hex references
    ✅ Niri                - Hex references

    ⏸️  QuickShell          - Not modified (per request)
    ⏸️  AGS                 - Not modified (per request)


═══════════════════════════════════════════════════════════════════════════════

                  🎉 SYSTEM READY FOR USE 🎉

         Edit colors in ONE place, theme EVERYWHERE ✨

═══════════════════════════════════════════════════════════════════════════════

EOF

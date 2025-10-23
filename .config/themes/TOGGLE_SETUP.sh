#!/bin/bash
# Quick Setup Summary
# This file documents the toggle script installation and usage

cat << 'EOF'

╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║          ✨ COLOR PROFILE TOGGLE SCRIPT - CREATED SUCCESSFULLY ✨        ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝


📋 WHAT WAS CREATED
═══════════════════════════════════════════════════════════════════════════

Three script files for color profile management:

1. ~/.config/themes/toggle-profile.sh (4.5 KB)
   └─ Simple version, basic functionality
   └─ Good for learning how the system works

2. ~/.config/themes/toggle-profile-advanced.sh (8.8 KB)
   └─ Advanced version with full features
   └─ Recommended for daily use
   └─ Supports multiple commands and options

3. ~/.local/bin/toggle-profile (wrapper)
   └─ Easy access from anywhere
   └─ Delegates to toggle-profile-advanced.sh


🚀 QUICK START
═══════════════════════════════════════════════════════════════════════════

1. Make scripts executable:
   chmod +x ~/.config/themes/toggle-*.sh
   chmod +x ~/.local/bin/toggle-profile

2. Run with Fuzzel (easiest):
   toggle-profile

3. Or use command line:
   toggle-profile current      # Show current profile
   toggle-profile list         # List all profiles
   toggle-profile set nonchalant-purp  # Switch profile


✨ FEATURES
═══════════════════════════════════════════════════════════════════════════

✅ Fuzzel Integration
   - Interactive profile selection with Fuzzel
   - Fallback to simple menu if Fuzzel unavailable
   - Beautiful, user-friendly interface

✅ Multiple Commands
   - toggle-profile           (Fuzzel mode)
   - toggle-profile current   (Show active)
   - toggle-profile list      (Show all)
   - toggle-profile set NAME  (Direct switch)
   - toggle-profile --help    (Help)

✅ Auto-Update
   - Automatically updates CSS @import statements
   - Updates Waybar config
   - Updates Wlogout config
   - Reloads Waybar automatically

✅ Smart Features
   - Detects current profile
   - Prevents redundant switches
   - Shows color values
   - Sends notifications
   - Handles errors gracefully

✅ Easy Integration
   - Works with keybindings
   - Can be used in scripts
   - Supports aliases
   - No dependencies beyond Fuzzel


💻 USAGE EXAMPLES
═══════════════════════════════════════════════════════════════════════════

EXAMPLE 1: Interactive Mode (Recommended)
──────────────────────────────────────────
$ toggle-profile
# Fuzzel opens with profile list
# Select "nonchalant-purp" or "default"
# Profile switches, Waybar reloads
✅ Done!

EXAMPLE 2: View Current Profile
────────────────────────────────
$ toggle-profile current
Current Profile: default
Description: Default - Modern, vibrant green/blue accents

EXAMPLE 3: List All Profiles
─────────────────────────────
$ toggle-profile list
Available Color Profiles:
==========================
✓ default (active) - Default - Modern, vibrant green/blue accents
  nonchalant-purp - Nonchalant Purp - Sophisticated violet/lime

EXAMPLE 4: Direct Switch
────────────────────────
$ toggle-profile set nonchalant-purp
🎨 Switching color profile...
  From: default
  To:   nonchalant-purp

Colors for nonchalant-purp profile:
  Background:  #1e1e20
  Foreground:  #dcd9e7
  Accent:      #c59edc
  [... more colors ...]

✅ Profile switched successfully!


⚙️ KEYBINDING SETUP
═══════════════════════════════════════════════════════════════════════════

HYPRLAND (~/.config/hypr/hyprland.conf)
────────────────────────────────────────
# Super+T to toggle color profile
bind = SUPER, T, exec, toggle-profile

NIRI (~/.config/niri/config.kdl)
─────────────────────────────────
bind "mod Super+T" { spawn "toggle-profile"; }

FISH (~/.config/fish/config.fish)
──────────────────────────────────
# Create alias
alias tp='toggle-profile'

# Then use: tp
#          tp set nonchalant-purp
#          tp list


📊 WHAT GETS UPDATED
═══════════════════════════════════════════════════════════════════════════

AUTOMATIC (CSS Applications)
─────────────────────────────
✅ Waybar         (~/.config/waybar/style.css)
✅ Wlogout        (~/.config/wlogout/nova.css)
✅ Wlogout Colors (~/.config/wlogout/colors.css)

MANUAL (Config Files with Hex Values)
──────────────────────────────────────
ℹ️  Kitty          (~/.config/kitty/colors.conf)
ℹ️  Hyprland       (~/.config/hypr/hyprland/colors.conf)
ℹ️  Hyprlock       (~/.config/hypr/hyprlock.conf)
ℹ️  Fuzzel         (~/.config/fuzzel/fuzzel_theme.ini)
ℹ️  Dunst          (~/.config/dunst/dunstrc)
ℹ️  Niri           (~/.config/niri/config.kdl)

For manual updates:
1. Run: toggle-profile current
2. See the color values in output
3. Manually update the config files
4. Or refer to profile documentation


🔄 PROFILES AVAILABLE
═══════════════════════════════════════════════════════════════════════════

DEFAULT PROFILE
───────────────
Name: default
Type: Modern, vibrant
Colors: Green accents, blue highlights
Background: #1A1B26
Foreground: #C0CAF5
Best for: General use

NONCHALANT PURP PROFILE
───────────────────────
Name: nonchalant-purp
Type: Sophisticated, professional
Colors: Violet accents, lime highlights
Background: #1e1e20
Foreground: #dcd9e7
Best for: Dark environments, focus work


📚 DOCUMENTATION
═══════════════════════════════════════════════════════════════════════════

Main Guide:
  cat ~/.config/themes/TOGGLE_SCRIPT.md

Profile Details:
  cat ~/.config/themes/NONCHALANT_PURP.md
  cat ~/.config/themes/QUICK_REFERENCE.md

Switching Guide:
  cat ~/.config/themes/PROFILE_SWITCHING.md

Color Reference:
  cat ~/.config/themes/NONCHALANT_PURP_SUMMARY.txt


🔧 INSTALLATION CHECK
═══════════════════════════════════════════════════════════════════════════

Verify everything is set up:

1. Check scripts exist:
   ls -l ~/.config/themes/toggle-*.sh
   ls -l ~/.local/bin/toggle-profile

2. Check executable permissions:
   file ~/.local/bin/toggle-profile

3. Check PATH includes ~/.local/bin:
   echo $PATH | grep local/bin

4. Test the script:
   toggle-profile --help

5. Run interactively:
   toggle-profile


⚡ TROUBLESHOOTING
═══════════════════════════════════════════════════════════════════════════

❌ "toggle-profile: command not found"
   → Add ~/.local/bin to PATH in your shell config

❌ "Fuzzel not found"
   → Install Fuzzel: sudo pacman -S fuzzel
   → Script will fall back to simple menu

❌ "Permission denied"
   → Make scripts executable: chmod +x ~/.config/themes/toggle-*.sh

❌ "Script can't find config files"
   → Check paths exist: ls ~/.config/waybar/style.css

❌ "Waybar not reloading"
   → Try manual reload: killall waybar && waybar &


💡 TIPS & TRICKS
═══════════════════════════════════════════════════════════════════════════

1. Create an alias for quick access:
   alias tp='toggle-profile'
   tp                    # Opens Fuzzel
   tp set nonchalant-purp  # Direct switch

2. Bind to a key:
   # In Hyprland: bind = SUPER, T, exec, toggle-profile
   # Press Super+T to open profile selector

3. Use in scripts:
   toggle-profile set nonchalant-purp
   some-other-command

4. Create new profiles:
   # Copy nonchalant-purp.* files
   # Edit the hex values
   # Add to toggle-profile-advanced.sh

5. Schedule profile switching:
   # Use cron to switch profiles by time of day
   0 18 * * * toggle-profile set nonchalant-purp
   0 8 * * * toggle-profile set default


✅ READY TO USE
═══════════════════════════════════════════════════════════════════════════

Everything is installed and ready!

Try it now:
  toggle-profile

Or with a specific command:
  toggle-profile list
  toggle-profile current
  toggle-profile set nonchalant-purp


═══════════════════════════════════════════════════════════════════════════

Questions? Check the full documentation:
  cat ~/.config/themes/TOGGLE_SCRIPT.md

═══════════════════════════════════════════════════════════════════════════

EOF

#!/bin/bash
# Apply Color Profile to All Applications
# This script properly applies a color profile across all config files

PROFILE=${1:-default}
THEMES_DIR="$HOME/.config/themes"

# Validate profile
if [ ! -f "$THEMES_DIR/$PROFILE.css" ]; then
    echo "❌ Profile not found: $PROFILE"
    echo "Available profiles:"
    ls "$THEMES_DIR"/*.css | xargs -n1 basename | sed 's/.css//'
    exit 1
fi

echo "📝 Applying profile: $PROFILE"

# ============================================================================
# CSS APPLICATIONS (Auto-handled by @import)
# ============================================================================

echo "  Updating CSS applications..."

# Waybar
if [ -f ~/.config/waybar/style.css ]; then
    sed -i "s|@import url(\"../themes/[^\"]*\.css\");|@import url(\"../themes/$PROFILE.css\");|" ~/.config/waybar/style.css
    echo "    ✓ Waybar"
fi

# Wlogout
if [ -f ~/.config/wlogout/nova.css ]; then
    sed -i "s|@import url(\"../themes/[^\"]*\.css\");|@import url(\"../themes/$PROFILE.css\");|" ~/.config/wlogout/nova.css
    echo "    ✓ Wlogout (nova.css)"
fi

if [ -f ~/.config/wlogout/colors.css ]; then
    sed -i "s|@import url(\"../themes/[^\"]*\.css\");|@import url(\"../themes/$PROFILE.css\");|" ~/.config/wlogout/colors.css
    echo "    ✓ Wlogout (colors.css)"
fi

# ============================================================================
# CONFIG FILES - Direct Color Values
# ============================================================================

echo "  Updating config files..."

# Get color values based on profile
case "$PROFILE" in
    "global-colors")
        BG="#1A1B26"
        FG="#C0CAF5"
        ACCENT="#9ECE6A"
        HIGHLIGHT="#7AA2F7"
        CAUTION="#E0AF68"
        URGENT="#F7768E"
        TRAY="#414868"
        BORDER="#414868"
        ;;
    "nonchalant-purp")
        BG="#1e1e20"
        FG="#dcd9e7"
        ACCENT="#c59edc"
        HIGHLIGHT="#c3fb5b"
        CAUTION="#ffb86c"
        URGENT="#ff6e79"
        TRAY="#2a2a2c"
        BORDER="#3a3a3d"
        ;;
    *)
        echo "❌ Unknown profile: $PROFILE"
        exit 1
        ;;
esac

# Update Kitty
if [ -f ~/.config/kitty/colors.conf ]; then
    cat > ~/.config/kitty/colors.conf << EOF
# Colors from $PROFILE profile
cursor $FG
cursor_text_color $BG

foreground            $FG
background            $BG
selection_foreground  $BG
selection_background  $HIGHLIGHT
url_color             $ACCENT

# black
color0   $BG
color8   $TRAY

# red
color1   $URGENT
color9   $URGENT

# green
color2   $ACCENT
color10  $ACCENT

# yellow
color3   $CAUTION
color11  $CAUTION

# blue
color4   $HIGHLIGHT
color12  $HIGHLIGHT

# magenta
color5   $ACCENT
color13  $ACCENT

# cyan
color6   $ACCENT
color14  $ACCENT

# white
color7   $FG
color15  $FG
EOF
    echo "    ✓ Kitty"
fi

# Update Hyprland
if [ -f ~/.config/hypr/hyprland/colors.conf ]; then
    sed -i "s/col\.active_border = rgba([^)]*)/col.active_border = rgba(${HIGHLIGHT:1}AA)/g" ~/.config/hypr/hyprland/colors.conf
    sed -i "s/col\.inactive_border = rgba([^)]*)/col.inactive_border = rgba(${BORDER:1}AA)/g" ~/.config/hypr/hyprland/colors.conf
    echo "    ✓ Hyprland"
fi

# Update Hyprlock
if [ -f ~/.config/hypr/hyprlock.conf ]; then
    # Create hex RGBA format
    TEXT_RGBA="rgba(${FG:1}FF)"
    BORDER_RGBA="rgba(${HIGHLIGHT:1}FF)"
    BG_RGBA="rgba(${TRAY:1}CC)"
    CHECK_RGBA="rgba(${ACCENT:1}FF)"
    FAIL_RGBA="rgba(${URGENT:1}FF)"
    
    sed -i "s/\$text_color = rgba([^)]*)/\$text_color = $TEXT_RGBA/" ~/.config/hypr/hyprlock.conf
    sed -i "s/\$entry_background_color = rgba([^)]*)/\$entry_background_color = $BG_RGBA/" ~/.config/hypr/hyprlock.conf
    sed -i "s/\$entry_border_color = rgba([^)]*)/\$entry_border_color = $BORDER_RGBA/" ~/.config/hypr/hyprlock.conf
    sed -i "s/\$entry_color = rgba([^)]*)/\$entry_color = $TEXT_RGBA/" ~/.config/hypr/hyprlock.conf
    sed -i "s/\$check_color = rgba([^)]*)/\$check_color = $CHECK_RGBA/" ~/.config/hypr/hyprlock.conf
    sed -i "s/\$fail_color = rgba([^)]*)/\$fail_color = $FAIL_RGBA/" ~/.config/hypr/hyprlock.conf
    sed -i "s/\$caps_color = rgba([^)]*)/\$caps_color = $BORDER_RGBA/" ~/.config/hypr/hyprlock.conf
    echo "    ✓ Hyprlock"
fi

# Update Fuzzel
if [ -f ~/.config/fuzzel/fuzzel_theme.ini ]; then
    # Remove '#' from hex and convert to lowercase
    BG_FUZZEL=$(echo "${BG:1}" | tr '[:upper:]' '[:lower:]')ff
    FG_FUZZEL=$(echo "${FG:1}" | tr '[:upper:]' '[:lower:]')ff
    HIGHLIGHT_FUZZEL=$(echo "${HIGHLIGHT:1}" | tr '[:upper:]' '[:lower:]')ff
    ACCENT_FUZZEL=$(echo "${ACCENT:1}" | tr '[:upper:]' '[:lower:]')ff
    
    sed -i "s/background=.*/background=$BG_FUZZEL/" ~/.config/fuzzel/fuzzel_theme.ini
    sed -i "s/text=.*/text=$FG_FUZZEL/" ~/.config/fuzzel/fuzzel_theme.ini
    sed -i "s/selection=.*/selection=$HIGHLIGHT_FUZZEL/" ~/.config/fuzzel/fuzzel_theme.ini
    sed -i "s/match=.*/match=$ACCENT_FUZZEL/" ~/.config/fuzzel/fuzzel_theme.ini
    echo "    ✓ Fuzzel"
fi

# Update Dunst
if [ -f ~/.config/dunst/dunstrc ]; then
    sed -i "s/background = \"[^\"]*\"/background = \"$BG\"/g" ~/.config/dunst/dunstrc
    sed -i "s/foreground = \"[^\"]*\"/foreground = \"$FG\"/g" ~/.config/dunst/dunstrc
    sed -i "s/frame_color = \"[^\"]*\"/frame_color = \"$HIGHLIGHT\"/g" ~/.config/dunst/dunstrc
    echo "    ✓ Dunst"
fi

# Note: Niri uses gradients, harder to update programmatically
echo "    ℹ Niri (update manually or use sed)"

# ============================================================================
# Reload Applications
# ============================================================================

echo ""
echo "🔄 Reloading applications..."

# Waybar
if pgrep -x waybar > /dev/null 2>&1; then
    killall waybar 2>/dev/null || true
    sleep 0.3
    waybar > /dev/null 2>&1 &
    echo "  ✓ Waybar reloaded"
fi

# Notify user
if command -v notify-send &> /dev/null; then
    notify-send "🎨 Color Profile Applied" \
        "Profile: $PROFILE\n\nWaybar has been reloaded.\nOther apps will update on next restart." \
        -t 5000
fi

echo ""
echo "✅ Profile applied: $PROFILE"
echo ""
echo "Next steps:"
echo "  - Restart Wlogout: Press your logout key"
echo "  - Restart Hyprlock: Lock and unlock screen"
echo "  - Restart Fuzzel: Close and reopen"
echo "  - Restart Dunst: killall dunst"
echo "  - For Niri: Update ~/.config/niri/config.kdl manually"

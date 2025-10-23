#!/bin/bash
# Color Preview Script
# This script displays all the colors from the global color scheme

source ~/.config/themes/colors.sh

echo -e "\n=== GLOBAL COLOR PALETTE ===" 
echo -e "Source: ~/.config/themes/global-colors.css\n"

# Helper function to print color blocks
print_color() {
    local name="$1"
    local var_name="$2"
    local value="${!var_name}"
    
    printf "%-20s %-20s %s\n" "$name" "$var_name" "$value"
}

echo "PRIMARY COLORS:"
print_color "Background" "COLOR_BG"
print_color "Foreground" "COLOR_FG"

echo -e "\nACCENT COLORS:"
print_color "Accent (Green)" "COLOR_ACCENT"
print_color "Highlight (Blue)" "COLOR_HIGHLIGHT"
print_color "Caution (Yellow)" "COLOR_CAUTION"
print_color "Urgent (Red)" "COLOR_URGENT"

echo -e "\nSECONDARY COLORS:"
print_color "Tray" "COLOR_TRAY"
print_color "Invert" "COLOR_INVERT"
print_color "Middle" "COLOR_MIDDLE"

echo -e "\nRIGHT-SIDE COLORS:"
print_color "First (Cyan)" "COLOR_FIRST_RIGHT"
print_color "Middle (Red)" "COLOR_MIDDLE_RIGHT"
print_color "Last (Magenta)" "COLOR_LAST_RIGHT"

echo -e "\nSPECIAL COLORS:"
print_color "Pastel" "COLOR_PASTEL"

echo -e "\n16-COLOR TERMINAL PALETTE:"
echo "  0: Black      1: Red        2: Green      3: Yellow"
echo "  4: Blue       5: Magenta    6: Cyan       7: White"
echo "  8-15: Bright variants"

echo -e "\nStandard Colors (0-7):"
for i in {0..7}; do
    var="COLOR_$i"
    printf "  Color%-2d: %s\n" "$i" "${!var}"
done

echo -e "\nBright Colors (8-15):"
for i in {8..15}; do
    var="COLOR_$i"
    printf "  Color%-2d: %s\n" "$i" "${!var}"
done

echo -e "\n=== CONFIGURATION FILES ===\n"
echo "Global Colors Source:     ~/.config/themes/global-colors.css"
echo "Shell Variables:          ~/.config/themes/colors.sh"
echo "Reference Documentation: ~/.config/themes/colors.conf"
echo "Usage Guide:             ~/.config/themes/README.md"

echo -e "\n=== APPLICATIONS USING GLOBAL COLORS ===\n"
echo "✅ Waybar                ~/.config/waybar/style.css"
echo "✅ Kitty                 ~/.config/kitty/colors.conf"
echo "✅ Wlogout               ~/.config/wlogout/*.css"
echo "✅ Hyprland              ~/.config/hypr/hyprland/colors.conf"
echo "✅ Hyprlock              ~/.config/hypr/hyprlock.conf"
echo "✅ Fuzzel                ~/.config/fuzzel/fuzzel_theme.ini"
echo "✅ Dunst                 ~/.config/dunst/dunstrc"
echo "✅ Niri                  ~/.config/niri/config.kdl"

echo -e "\n"

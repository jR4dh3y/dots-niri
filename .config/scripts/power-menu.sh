#!/usr/bin/env bash

# Power Menu - Elegant power options menu
# Lock, Logout, Suspend, Reboot, Shutdown with countdown and confirmation

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Icons (using nerd font symbols)
LOCK_ICON="󰌾"
LOGOUT_ICON="󰍃"
SUSPEND_ICON="󰤄"
REBOOT_ICON="󰜉"
SHUTDOWN_ICON="󰐥"
CANCEL_ICON="󰜺"

# Function to show countdown
countdown() {
    local seconds=$1
    local action=$2
    
    for ((i=seconds; i>0; i--)); do
        echo -ne "\r${YELLOW}${action} in ${i} seconds... (Ctrl+C to cancel)${NC}  "
        sleep 1
    done
    echo ""
}

# Function to confirm action
confirm_action() {
    local action=$1
    local prompt=$2
    
    echo ""
    echo -e "${YELLOW}${prompt}${NC}"
    read -p "Type 'yes' to confirm: " -r response
    
    if [[ "$response" == "yes" ]]; then
        return 0
    else
        echo -e "${BLUE}Cancelled${NC}"
        return 1
    fi
}

# Create menu options
menu_options=(
    "${LOCK_ICON}  Lock Screen"
    "${LOGOUT_ICON}  Logout"
    "${SUSPEND_ICON}  Suspend"
    "${REBOOT_ICON}  Reboot"
    "${SHUTDOWN_ICON}  Shutdown"
    "${CANCEL_ICON}  Cancel"
)

# FZF configuration
fzf_args=(
  --height=100%
  --layout=reverse
  --border=rounded
#   --prompt="⚡ Power Menu > "
#   --preview='case {} in 
#     *"Lock"*) echo "Lock the screen\nYour session will remain active" ;;
#     *"Logout"*) echo "End current session\nClose all applications" ;;
#     *"Suspend"*) echo "Suspend to RAM\nLow power state, quick resume" ;;
#     *"Reboot"*) echo "Restart the system\nAll applications will close" ;;
#     *"Shutdown"*) echo "Power off the system\nAll applications will close" ;;
#     *"Cancel"*) echo "Return without action" ;;
#   esac'
#   --preview-window='right:40%:wrap'
  --color='prompt:magenta,pointer:magenta,marker:green,header:cyan'
)

# Show menu
selection=$(printf '%s\n' "${menu_options[@]}" | fzf "${fzf_args[@]}")

# Handle selection
case "$selection" in
    *"Lock"*)
        echo -e "${CYAN}Locking screen...${NC}"
        exec "hyprlock" "-q" "-c" "/home/radhey/code/dots-niri/.config/hypr/hyprlock-static.conf"
        ;;
        
    *"Logout"*)
        if confirm_action "logout" "Are you sure you want to logout?"; then
            countdown 3 "Logging out"
            # For niri
            niri msg action quit
            # Alternative: loginctl terminate-user "$USER"
        fi
        ;;
        
    *"Suspend"*)
        echo -e "${CYAN}Locking and suspending...${NC}"
        exec "hyprlock" "-q" "-c" "/home/radhey/code/dots-niri/.config/hypr/hyprlock-static.conf"
        sleep 1
        systemctl suspend
        ;;
        
    *"Reboot"*)
        if confirm_action "reboot" "Are you sure you want to reboot?"; then
            countdown 5 "Rebooting"
            notify-send "System Reboot" "System is rebooting..." -u critical -t 3000
            systemctl reboot
        fi
        ;;
        
    *"Shutdown"*)
        if confirm_action "shutdown" "Are you sure you want to shutdown?"; then
            countdown 5 "Shutting down"
            notify-send "System Shutdown" "System is shutting down..." -u critical -t 3000
            systemctl poweroff
        fi
        ;;
        
    *"Cancel"*|"")
        echo -e "${BLUE}Cancelled${NC}"
        exit 0
        ;;
        
    *)
        echo -e "${RED}Invalid selection${NC}"
        exit 1
        ;;
esac

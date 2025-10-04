#!/usr/bin/env bash

# Service Manager - Interactive systemd service manager
# Manage systemd services with FZF

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to get service status with color
get_service_list() {
    systemctl list-units --type=service --all --no-pager --plain | \
    grep -E '\.service' | \
    awk '{
        status = $4;
        color = "";
        if (status == "running") color = "\033[0;32m●";
        else if (status == "failed") color = "\033[0;31m●";
        else if (status == "dead") color = "\033[0;90m●";
        else color = "\033[0;33m●";
        
        # Extract service name and description
        service = $1;
        sub(/\.service$/, "", service);
        
        # Get the rest as description
        desc = "";
        for(i=5; i<=NF; i++) desc = desc $i " ";
        
        printf "%s %-30s %-10s %s\033[0m\n", color, service, status, desc;
    }'
}

# Main menu
while true; do
    echo -e "${BLUE}Loading services...${NC}"
    
    # FZF configuration
    fzf_args=(
      --ansi
      --height=90%
      --layout=reverse
      --border=rounded
      --prompt="⚙️  Service Manager > "
      --header='ENTER:manage | CTRL-R:reload | CTRL-U:user-services | ESC:quit'
      --preview='systemctl status {2}.service'
      --preview-window='right:60%:wrap'
      --bind 'ctrl-r:reload(systemctl list-units --type=service --all --no-pager --plain | grep -E "\.service" | awk '"'"'{status=$4;color="";if(status=="running")color="\033[0;32m●";else if(status=="failed")color="\033[0;31m●";else if(status=="dead")color="\033[0;90m●";else color="\033[0;33m●";service=$1;sub(/\.service$/,"",service);desc="";for(i=5;i<=NF;i++)desc=desc $i " ";printf"%s %-30s %-10s %s\033[0m\n",color,service,status,desc}'"'"')'
      --bind 'alt-p:toggle-preview'
      --color='prompt:blue,pointer:blue,marker:green'
    )
    
    selection=$(get_service_list | fzf "${fzf_args[@]}")
    
    if [[ -z "$selection" ]]; then
        echo "Exiting..."
        exit 0
    fi
    
    # Extract service name and status
    service_name=$(echo "$selection" | awk '{print $2}')
    service_status=$(echo "$selection" | awk '{print $3}')
    
    echo ""
    echo -e "${BLUE}Selected service:${NC} ${service_name}"
    echo -e "${BLUE}Current status:${NC} ${service_status}"
    echo ""
    
    # Action menu
    echo "Actions:"
    echo "  1) Start service"
    echo "  2) Stop service"
    echo "  3) Restart service"
    echo "  4) Enable service (start on boot)"
    echo "  5) Disable service (don't start on boot)"
    echo "  6) View full status"
    echo "  7) View logs (journalctl)"
    echo "  8) Edit service file"
    echo "  9) Back to service list"
    echo "  0) Exit"
    echo ""
    read -p "Choose action: " -n 1 -r action
    echo ""
    echo ""
    
    case $action in
        1)
            echo -e "${YELLOW}Starting ${service_name}...${NC}"
            if sudo systemctl start "${service_name}.service"; then
                echo -e "${GREEN}✓ Service started${NC}"
                notify-send "Service Manager" "Started: ${service_name}" -i system-run
            else
                echo -e "${RED}✗ Failed to start service${NC}"
                notify-send "Service Manager" "Failed to start: ${service_name}" -u critical
            fi
            read -p "Press any key to continue..."
            ;;
        2)
            echo -e "${YELLOW}Stopping ${service_name}...${NC}"
            if sudo systemctl stop "${service_name}.service"; then
                echo -e "${GREEN}✓ Service stopped${NC}"
                notify-send "Service Manager" "Stopped: ${service_name}" -i process-stop
            else
                echo -e "${RED}✗ Failed to stop service${NC}"
                notify-send "Service Manager" "Failed to stop: ${service_name}" -u critical
            fi
            read -p "Press any key to continue..."
            ;;
        3)
            echo -e "${YELLOW}Restarting ${service_name}...${NC}"
            if sudo systemctl restart "${service_name}.service"; then
                echo -e "${GREEN}✓ Service restarted${NC}"
                notify-send "Service Manager" "Restarted: ${service_name}" -i system-reboot
            else
                echo -e "${RED}✗ Failed to restart service${NC}"
                notify-send "Service Manager" "Failed to restart: ${service_name}" -u critical
            fi
            read -p "Press any key to continue..."
            ;;
        4)
            echo -e "${YELLOW}Enabling ${service_name}...${NC}"
            if sudo systemctl enable "${service_name}.service"; then
                echo -e "${GREEN}✓ Service enabled${NC}"
                notify-send "Service Manager" "Enabled: ${service_name}" -i emblem-default
            else
                echo -e "${RED}✗ Failed to enable service${NC}"
            fi
            read -p "Press any key to continue..."
            ;;
        5)
            echo -e "${YELLOW}Disabling ${service_name}...${NC}"
            if sudo systemctl disable "${service_name}.service"; then
                echo -e "${GREEN}✓ Service disabled${NC}"
                notify-send "Service Manager" "Disabled: ${service_name}" -i dialog-error
            else
                echo -e "${RED}✗ Failed to disable service${NC}"
            fi
            read -p "Press any key to continue..."
            ;;
        6)
            clear
            systemctl status "${service_name}.service"
            echo ""
            read -p "Press any key to continue..."
            ;;
        7)
            clear
            echo -e "${BLUE}Last 50 lines of logs for ${service_name}:${NC}"
            echo ""
            sudo journalctl -u "${service_name}.service" -n 50 --no-pager
            echo ""
            read -p "Press any key to continue..."
            ;;
        8)
            service_file=$(systemctl show -p FragmentPath "${service_name}.service" | cut -d= -f2)
            if [[ -n "$service_file" && -f "$service_file" ]]; then
                sudo "${EDITOR:-nano}" "$service_file"
                read -p "Reload systemd daemon? (y/N) " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    sudo systemctl daemon-reload
                    echo -e "${GREEN}✓ Daemon reloaded${NC}"
                fi
            else
                echo -e "${RED}✗ Service file not found${NC}"
                read -p "Press any key to continue..."
            fi
            ;;
        9|"")
            continue
            ;;
        0)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            read -p "Press any key to continue..."
            ;;
    esac
    
    clear
done

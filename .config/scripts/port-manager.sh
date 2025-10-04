#!/usr/bin/env bash

# Port Manager - Check open ports and manage processes using them
# Shows listening ports and allows killing processes

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check if running with sufficient privileges
if [[ $EUID -ne 0 ]]; then
    USE_SUDO="sudo"
else
    USE_SUDO=""
fi


# Function to get listening ports
get_ports() {
    $USE_SUDO ss -tulpn | grep LISTEN | awk '{
        # Extract port and address
        split($5, addr, ":");
        port = addr[length(addr)];
        address = substr($5, 1, length($5)-length(port)-1);
        
        # Extract process info
        if ($7 ~ /users/) {
            match($7, /\("([^"]+)",pid=([0-9]+)/, proc);
            process = proc[1];
            pid = proc[2];
        } else {
            process = "-";
            pid = "-";
        }
        
        # Protocol
        proto = $1;
        
        printf "%-8s %-25s %-8s %-8s %-20s\n", port, address, proto, pid, process;
    }' | sort -n
}

# FZF configuration
fzf_args=(
  --height=100%
  --layout=reverse
  --border=rounded
  --prompt="🔌 Port Manager > "
  --header='ENTER:kill-process | CTRL-R:reload | CTRL-P:show-all-ports | ESC:quit'
#   --preview='echo "Port Details:"; echo ""; if [ {4} != "-" ]; then ps -p {4} -o pid,user,%cpu,%mem,etime,cmd --no-headers 2>/dev/null || echo "Process not found"; lsof -i :{1} 2>/dev/null; else echo "No process information available"; fi'
#   --preview-window='bottom:50%:wrap'
#   --bind 'ctrl-r:reload('"$USE_SUDO"' ss -tulpn | grep LISTEN | awk '"'"'{split($5,addr,":");port=addr[length(addr)];address=substr($5,1,length($5)-length(port)-1);if($7~/users/){match($7,/\("([^"]+)",pid=([0-9]+)/,proc);process=proc[1];pid=proc[2]}else{process="-";pid="-"}proto=$1;printf"%-8s %-25s %-8s %-8s %-20s\n",port,address,proto,pid,process}'"'"' | sort -n)'
#   --bind 'ctrl-p:reload('"$USE_SUDO"' ss -tupn | awk '"'"'{split($5,addr,":");port=addr[length(addr)];address=substr($5,1,length($5)-length(port)-1);if($7~/users/){match($7,/\("([^"]+)",pid=([0-9]+)/,proc);process=proc[1];pid=proc[2]}else{process="-";pid="-"}proto=$1;state=$2;printf"%-8s %-25s %-8s %-12s %-8s %-20s\n",port,address,proto,state,pid,process}'"'"' | sort -n)'
#   --bind 'alt-p:toggle-preview'
  --color='prompt:cyan,pointer:cyan,marker:green'
)

port_list=$(get_ports)

clear

if [[ -z "$port_list" ]]; then
    echo -e "${YELLOW}No listening ports found${NC}"
    exit 0
fi

selection=$(echo "$port_list" | fzf "${fzf_args[@]}")

if [[ -n "$selection" ]]; then
    port=$(echo "$selection" | awk '{print $1}')
    address=$(echo "$selection" | awk '{print $2}')
    proto=$(echo "$selection" | awk '{print $3}')
    pid=$(echo "$selection" | awk '{print $4}')
    process=$(echo "$selection" | awk '{print $5}')
    
    echo ""
    echo -e "${BLUE}Selected Port:${NC}"
    echo -e "  Port:     ${GREEN}${port}${NC}"
    echo -e "  Address:  ${address}"
    echo -e "  Protocol: ${proto}"
    echo -e "  PID:      ${pid}"
    echo -e "  Process:  ${process}"
    echo ""
    
    if [[ "$pid" != "-" ]]; then
        echo "Actions:"
        echo "  1) Kill process (SIGTERM)"
        echo "  2) Kill process (SIGKILL)"
        echo "  3) View process details"
        echo "  4) View all connections on this port"
        echo "  5) Cancel"
        echo ""
        read -p "Choose action: " -n 1 -r action
        echo ""
        echo ""
        
        case $action in
            1)
                echo -e "${YELLOW}Killing process ${pid} (${process}) with SIGTERM...${NC}"
                if $USE_SUDO kill "$pid" 2>/dev/null; then
                    echo -e "${GREEN}✓ Process killed${NC}"
                    notify-send "Port Manager" "Killed process: ${process} (PID: ${pid})" -i process-stop
                else
                    echo -e "${RED}✗ Failed to kill process${NC}"
                    notify-send "Port Manager" "Failed to kill: ${process}" -u critical
                fi
                ;;
            2)
                read -p "Are you sure you want to force kill this process? (y/N) " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    echo -e "${YELLOW}Force killing process ${pid} (${process})...${NC}"
                    if $USE_SUDO kill -9 "$pid" 2>/dev/null; then
                        echo -e "${GREEN}✓ Process force killed${NC}"
                        notify-send "Port Manager" "Force killed: ${process} (PID: ${pid})" -i process-stop
                    else
                        echo -e "${RED}✗ Failed to kill process${NC}"
                    fi
                fi
                ;;
            3)
                clear
                echo -e "${BLUE}Process Details:${NC}"
                echo ""
                ps -p "$pid" -o pid,ppid,user,%cpu,%mem,vsz,rss,etime,cmd
                echo ""
                echo -e "${BLUE}Open Files:${NC}"
                $USE_SUDO lsof -p "$pid" 2>/dev/null | head -20
                echo ""
                read -p "Press any key to continue..."
                ;;
            4)
                clear
                echo -e "${BLUE}All connections on port ${port}:${NC}"
                echo ""
                $USE_SUDO lsof -i :"${port}"
                echo ""
                read -p "Press any key to continue..."
                ;;
            5|"")
                echo "Cancelled"
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                ;;
        esac
    else
        echo -e "${YELLOW}No process information available for this port${NC}"
    fi
else
    echo "No port selected"
fi

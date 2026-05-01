#!/usr/bin/env bash

# --- CONFIG ---
CURL_KEY=""
[ -n "$CURL_KEY" ] && AUTH="?token=$CURL_KEY" || AUTH=""

# --- STYLING ---
G="\033[1;32m"; C="\033[1;36m"; Y="\033[1;33m"; R="\033[1;31m"
M="\033[1;35m"; W="\033[1;37m"; RESET="\033[0m"; BOLD="\033[1m"

export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"

center() {
  local term_width=72
  local text="$1"
  local clean_text=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
  local padding=$(( (72 - ${#clean_text}) / 2 ))
  printf "%${padding}s%b\n" "" "$text"
}

get_info() {
    curl -s --max-time 3 "ipinfo.io/ip${AUTH}" "ipinfo.io/city${AUTH}" "ipinfo.io/country${AUTH}" | paste -sd' ' -
}

clear
echo -e "\n"
center "${C}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RESET}"
center "${C}┃${RESET}   ${M}${BOLD}󰒘  WIREGUARD NETWORK MANAGER${RESET}    ${C}┃${RESET}"
center "${C}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${RESET}"
center "${C}┃${RESET}   ${Y}1)${RESET}  Activate ${BOLD}wg0${RESET}                      ${C}┃${RESET}"
center "${C}┃${RESET}   ${Y}2)${RESET}  Activate ${BOLD}wg1${RESET}                      ${C}┃${RESET}"
center "${C}┃${RESET}   ${Y}3)${RESET}  Activate ${BOLD}wg2${RESET}                      ${C}┃${RESET}"
center "${C}┃${RESET}   ${R}4)${RESET}  Disconnect Active Tunnel             ${C}┃${RESET}"
center "${C}┃${RESET}   ${G}5)${RESET}  Exit Manager                         ${C}┃${RESET}"
center "${C}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RESET}"
echo -e "\n"
center "${W}${BOLD}󰄾 Select an Option${RESET}"
echo -ne "                                > "
read -r choice

case $choice in
    1|2|3) IFACE="wg$((choice-1))" ;;
    4)
        ACTIVE=$(sudo wg show interfaces | awk '{print $1}')
        if [ -n "$ACTIVE" ]; then
            center "${R}󰒄 Deactivating $ACTIVE...${RESET}"
            sudo wg-quick down "$ACTIVE"
            sudo resolvectl flush-caches
            INFO=$(get_info)
            notify-send "󰒄 WireGuard ($INFO) $ACTIVE Deactivated"
        fi
        exit 0 ;;
    5) exit 0 ;;
    *) exit 1 ;;
esac

# --- EXECUTION ---
CURRENT=$(sudo wg show interfaces)
if [ -n "$CURRENT" ]; then
    center "${Y}󱊔 Switching from $CURRENT...${RESET}"
    sudo wg-quick down "$CURRENT" >/dev/null 2>&1
fi

center "${C}󱑔 Handshaking $IFACE...${RESET}"

if sudo wg-quick up "$IFACE" >/dev/null 2>&1; then
    sudo resolvectl flush-caches
    center "${C}󰄬 Verifying Connection...${RESET}"
    sleep 1.5
    INFO=$(get_info)
    notify-send "󰒘 WireGuard ($INFO) $IFACE Activo"
    center "${G}󰄬 Done!${RESET}"
    sleep 0.5
    exit 0
else
    notify-send -u critical "Error" "Failed to start $IFACE"
    exit 1
fi

#!/bin/sh

log_file="${XDG_CACHE_HOME:-$HOME/.cache}/sway/wifi-menu.log"
mkdir -p "$(dirname "$log_file")"

notify() {
    notify-send "Wi-Fi" "$1" >/dev/null 2>&1 || true
}

wifi_device() {
    nmcli -t -f DEVICE,TYPE dev status 2>/dev/null \
        | awk -F: '$2 == "wifi" { print $1; exit }'
}

saved_wifi_exists() {
    nmcli -t -f NAME,TYPE connection show 2>/dev/null \
        | awk -F: -v ssid="$1" '$1 == ssid && $2 == "802-11-wireless" { found = 1 } END { exit !found }'
}

network_choices() {
    nmcli -t -f ACTIVE,SSID,SIGNAL,SECURITY dev wifi list --rescan yes 2>>"$log_file" \
        | awk -F: '
            $2 != "" && !seen[$2]++ {
                active = ($1 == "yes") ? "●" : " "
                security = ($4 == "") ? "" : ""
                printf "%s %s %s%% %s\n", active, security, $3, $2
            }
        '
}

device=$(wifi_device)
if [ -z "$device" ]; then
    notify "No Wi-Fi device found"
    exit 1
fi

radio=$(nmcli radio wifi 2>/dev/null)
connected=$(nmcli -t -f ACTIVE,SSID dev wifi list --rescan no 2>/dev/null \
    | awk -F: '$1 == "yes" { print $2; exit }')

if [ "$radio" = "disabled" ]; then
    choice=$(printf " Turn Wi-Fi on\n" | wofi --dmenu --prompt "Wi-Fi" --width 420 --height 120)
else
    choice=$(
        {
            printf " Rescan\n"
            printf " Turn Wi-Fi off\n"
            [ -n "$connected" ] && printf " Disconnect from %s\n" "$connected"
            network_choices
        } | wofi --dmenu --prompt "Wi-Fi" --width 520 --height 420
    )
fi

case "$choice" in
    " Turn Wi-Fi on")
        nmcli radio wifi on >>"$log_file" 2>&1 && notify "Wi-Fi enabled"
        ;;
    " Turn Wi-Fi off")
        nmcli radio wifi off >>"$log_file" 2>&1 && notify "Wi-Fi disabled"
        ;;
    " Rescan")
        nmcli dev wifi rescan ifname "$device" >>"$log_file" 2>&1
        exec "$0"
        ;;
    " Disconnect from "*)
        nmcli device disconnect "$device" >>"$log_file" 2>&1 && notify "Disconnected"
        ;;
    "")
        ;;
    *)
        ssid=$(printf "%s" "$choice" | sed 's/^[^ ]* [^ ]* [0-9][0-9]*% //')
        [ -z "$ssid" ] && exit 0

        if saved_wifi_exists "$ssid"; then
            nmcli connection up id "$ssid" >>"$log_file" 2>&1 \
                && notify "Connected to $ssid" \
                || notify "Could not connect to $ssid"
            exit 0
        fi

        case "$choice" in
            *""*)
                password=$(printf "\n" | wofi --dmenu --password --exec-search --prompt "Password for $ssid" --width 420 --height 120)
                [ -z "$password" ] && exit 0
                nmcli device wifi connect "$ssid" password "$password" ifname "$device" >>"$log_file" 2>&1 \
                    && notify "Connected to $ssid" \
                    || notify "Could not connect to $ssid"
                ;;
            *)
                nmcli device wifi connect "$ssid" ifname "$device" >>"$log_file" 2>&1 \
                    && notify "Connected to $ssid" \
                    || notify "Could not connect to $ssid"
                ;;
        esac
        ;;
esac

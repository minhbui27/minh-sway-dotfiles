#!/bin/sh

power_menu="/home/minhbui/.config/sway/power-menu.sh"
input_menu="/home/minhbui/.config/sway/input-menu.sh"
audio_menu="/home/minhbui/.config/sway/audio-menu.sh"
bluetooth_menu="/home/minhbui/.config/sway/bluetooth-menu.sh"
wifi_menu="/home/minhbui/.config/sway/wifi-menu.sh"
click_log="${XDG_CACHE_HOME:-$HOME/.cache}/sway/status-clicks.log"
mkdir -p "$(dirname "$click_log")"

json_string() {
    jq -Rn --arg text "$1" '$text'
}

block() {
    printf '{"name":%s,"full_text":%s}' "$(json_string "$1")" "$(json_string "$2")"
}

keyboard_status() {
    im=$(fcitx5-remote -n 2>/dev/null)
    state=$(fcitx5-remote 2>/dev/null)
    case "$im:$state" in
        mozc:2)
            mode=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/sway/fcitx5-mode" 2>/dev/null)
            case "$mode" in
                あ|ア|Ａ|ｱ) printf " JP %s" "$mode" ;;
                *) printf " JP あ" ;;
            esac
            return
            ;;
        keyboard-us:*|*:1|*:0) printf " US"; return ;;
    esac

    layout=$(swaymsg -t get_inputs -r 2>/dev/null \
        | jq -r '[.[] | select(.type == "keyboard" and .xkb_active_layout_name != null) | .xkb_active_layout_name] | unique | first // ""')

    case "$layout" in
        *"(US)"*) printf " US" ;;
        "") printf " ?" ;;
        *) printf " %s" "$layout" ;;
    esac
}

volume_status() {
    volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null) || {
        printf "vol ?"
        return
    }

    percent=$(printf "%s\n" "$volume" | awk '/Volume:/ { printf "%d", ($2 * 100) + 0.5 }')
    case "$volume" in
        *MUTED*) printf " muted" ;;
        *) printf " %s%%" "${percent:-?}" ;;
    esac
}

battery_status() {
    battery=$(find /sys/class/power_supply -maxdepth 1 -name 'BAT*' 2>/dev/null | sort | head -n 1)
    if [ -z "$battery" ] || [ ! -r "$battery/capacity" ]; then
        printf "bat ?"
        return
    fi

    capacity=$(cat "$battery/capacity")
    status=$(cat "$battery/status" 2>/dev/null)

    case "$status" in
        Charging) icon=""; state="" ;;
        Full) icon=""; state="full" ;;
        Discharging) icon=""; state="" ;;
        "Not charging") icon=""; state="" ;;
        *) state=$(printf "%s" "$status" | tr '[:upper:]' '[:lower:]') ;;
    esac

    printf "%s %s%%" "${icon:-}" "$capacity"
    [ -n "$state" ] && printf " %s" "$state"
}

wifi_status() {
    wifi=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi list --rescan no 2>/dev/null \
        | awk -F: '$1 == "yes" { print $2 " " $3 "%"; exit }')

    if [ -n "$wifi" ]; then
        printf " %s" "$wifi"
    else
        printf " off"
    fi
}

bluetooth_status() {
    powered=$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered:/ { print $2; exit }')
    if [ "$powered" != "yes" ]; then
        printf " off"
        return
    fi

    count=$(bluetoothctl devices Connected 2>/dev/null | awk 'END { print NR + 0 }')
    if [ "$count" -gt 0 ]; then
        printf " %s" "$count"
    else
        printf " on"
    fi
}

print_status() {
    printf ',['
    block keyboard "$(keyboard_status)"
    printf ','
    block volume "$(volume_status)"
    printf ','
    block battery "$(battery_status)"
    printf ','
    block wifi "$(wifi_status)"
    printf ','
    block clock "$(date +' %Y-%m-%d %H:%M')"
    printf ','
    block bluetooth "$(bluetooth_status)"
    printf ','
    block power_menu ""
    printf ']\n'
}

handle_clicks() {
    while IFS= read -r event; do
        printf "%s %s\n" "$(date '+%F %T')" "$event" >> "$click_log"
        case "$event" in
            *power_menu*) swaymsg exec "$power_menu" >> "$click_log" 2>&1 ;;
            *'"name": "keyboard"'*|*'"name":"keyboard"'*) swaymsg exec "$input_menu" >> "$click_log" 2>&1 ;;
            *'"name": "volume"'*|*'"name":"volume"'*) swaymsg exec "$audio_menu" >> "$click_log" 2>&1 ;;
            *'"name": "bluetooth"'*|*'"name":"bluetooth"'*) swaymsg exec "$bluetooth_menu" >> "$click_log" 2>&1 ;;
            *'"name": "wifi"'*|*'"name":"wifi"'*) swaymsg exec "$wifi_menu" >> "$click_log" 2>&1 ;;
        esac
    done
}

printf '{"version":1,"click_events":true}\n'
printf '[\n'
printf '[]\n'

while :; do
    print_status
    sleep 2
done &
status_pid=$!

trap 'kill "$status_pid" 2>/dev/null' EXIT
handle_clicks

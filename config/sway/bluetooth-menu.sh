#!/bin/sh

log_file="${XDG_CACHE_HOME:-$HOME/.cache}/sway/bluetooth-menu.log"
mkdir -p "$(dirname "$log_file")"

notify() {
    notify-send "Bluetooth" "$1" >/dev/null 2>&1 || true
}

powered() {
    bluetoothctl show 2>/dev/null | awk -F': ' '/Powered:/ { print $2; exit }'
}

device_connected() {
    bluetoothctl info "$1" 2>/dev/null | awk -F': ' '/Connected:/ { print $2; exit }'
}

device_choices() {
    bluetoothctl devices Paired 2>/dev/null | while read -r _ mac name; do
        [ -n "$mac" ] || continue
        if [ "$(device_connected "$mac")" = "yes" ]; then
            printf "● %s %s\n" "$mac" "$name"
        else
            printf "○ %s %s\n" "$mac" "$name"
        fi
    done
}

set_bluetooth_sink_default() {
    mac_key=$(printf "%s" "$1" | tr ':' '_')
    sink=$(pw-dump 2>>"$log_file" | jq -r --arg mac "$mac_key" '
        .[]
        | select(.type == "PipeWire:Interface:Node")
        | select((.info.props."media.class" // "") == "Audio/Sink")
        | select((.info.props."node.name" // "") | contains($mac))
        | .id
    ' | head -n 1)

    [ -n "$sink" ] && wpctl set-default "$sink" >>"$log_file" 2>&1
}

if [ "$(powered)" != "yes" ]; then
    choice=$(printf " Turn Bluetooth on\n" | wofi --dmenu --prompt "Bluetooth" --width 420 --height 120)
else
    choice=$(
        {
            printf " Turn Bluetooth off\n"
            device_choices
        } | wofi --dmenu --prompt "Bluetooth" --width 520 --height 360
    )
fi

case "$choice" in
    " Turn Bluetooth on")
        bluetoothctl power on >>"$log_file" 2>&1 && notify "Bluetooth on"
        ;;
    " Turn Bluetooth off")
        bluetoothctl power off >>"$log_file" 2>&1 && notify "Bluetooth off"
        ;;
    "● "*)
        mac=$(printf "%s\n" "$choice" | awk '{ print $2 }')
        name=$(printf "%s\n" "$choice" | cut -d' ' -f3-)
        bluetoothctl disconnect "$mac" >>"$log_file" 2>&1 && notify "Disconnected $name"
        ;;
    "○ "*)
        mac=$(printf "%s\n" "$choice" | awk '{ print $2 }')
        name=$(printf "%s\n" "$choice" | cut -d' ' -f3-)
        if bluetoothctl connect "$mac" >>"$log_file" 2>&1; then
            sleep 2
            set_bluetooth_sink_default "$mac"
            notify "Connected $name"
        else
            notify "Could not connect $name"
        fi
        ;;
esac

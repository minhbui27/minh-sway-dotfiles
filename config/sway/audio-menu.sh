#!/bin/sh

bluetooth_menu="/home/minhbui/.config/sway/bluetooth-menu.sh"
log_file="${XDG_CACHE_HOME:-$HOME/.cache}/sway/audio-menu.log"
mkdir -p "$(dirname "$log_file")"

notify() {
    notify-send "Audio" "$1" >/dev/null 2>&1 || true
}

default_id() {
    wpctl inspect "$1" 2>/dev/null | awk '/^id / { gsub(",", "", $2); print $2; exit }'
}

audio_choices() {
    media_class=$1
    current=$2

    pw-dump 2>>"$log_file" | jq -r --arg class "$media_class" --arg current "$current" '
        .[]
        | select(.type == "PipeWire:Interface:Node")
        | select((.info.props."media.class" // "") == $class)
        | . as $node
        | ($node.info.props."node.description" // $node.info.props."node.name" // "unknown") as $description
        | ($description
            | gsub("Tiger Lake-LP Smart Sound Technology Audio Controller "; "")
            | gsub("Built-in Audio "; "")
          ) as $label
        | (if (($node.id | tostring) == $current) then "●" else "○" end) as $mark
        | "\($mark) \($node.id) \($label)"
    '
}

select_default() {
    media_class=$1
    target=$2
    prompt=$3

    current=$(default_id "$target")
    choice=$(audio_choices "$media_class" "$current" | wofi --dmenu --prompt "$prompt" --width 620 --height 320)
    [ -n "$choice" ] || exit 0

    id=$(printf "%s\n" "$choice" | awk '{ print $2 }')
    label=$(printf "%s\n" "$choice" | cut -d' ' -f3-)
    [ -n "$id" ] || exit 0

    if wpctl set-default "$id" >>"$log_file" 2>&1; then
        notify "Default $prompt: $label"
    else
        notify "Could not set $prompt"
    fi
}

set_volume_prompt() {
    current=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null \
        | awk '/Volume:/ { printf "%d", ($2 * 100) + 0.5 }')

    value=$(printf "%s\n" "${current:-50}" \
        | wofi --dmenu --exec-search --prompt "Volume 0-100" --width 260 --height 120)

    case "$value" in
        ""|*[!0-9]*)
            notify "Enter a number from 0 to 100"
            return
            ;;
    esac

    [ "$value" -lt 0 ] && value=0
    [ "$value" -gt 100 ] && value=100

    wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 >>"$log_file" 2>&1
    wpctl set-volume @DEFAULT_AUDIO_SINK@ "$value%" >>"$log_file" 2>&1 \
        && notify "Volume set to $value%"
}

choice=$(printf " Toggle output mute\n Volume up\n Volume down\n󰝝 Set volume\n󰓃 Output device\n󰍬 Input device\n Bluetooth devices\n" \
    | wofi --dmenu --prompt "Audio" --width 360 --height 300)

case "$choice" in
    " Toggle output mute")
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle >>"$log_file" 2>&1
        ;;
    " Volume up")
        wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 >>"$log_file" 2>&1
        wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+ >>"$log_file" 2>&1
        ;;
    " Volume down")
        wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 >>"$log_file" 2>&1
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- >>"$log_file" 2>&1
        ;;
    "󰝝 Set volume")
        set_volume_prompt
        ;;
    "󰓃 Output device")
        select_default "Audio/Sink" "@DEFAULT_AUDIO_SINK@" "Output"
        ;;
    "󰍬 Input device")
        select_default "Audio/Source" "@DEFAULT_AUDIO_SOURCE@" "Input"
        ;;
    " Bluetooth devices")
        swaymsg exec "$bluetooth_menu" >>"$log_file" 2>&1
        ;;
esac

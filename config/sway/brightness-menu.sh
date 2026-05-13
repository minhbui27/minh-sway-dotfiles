#!/bin/sh

brightness="/home/minhbui/.config/sway/brightness.sh"
log_file="${XDG_CACHE_HOME:-$HOME/.cache}/sway/brightness-menu.log"
mkdir -p "$(dirname "$log_file")"

notify() {
    notify-send "Brightness" "$1" >/dev/null 2>&1 || true
}

current=$("$brightness" percent 2>>"$log_file" || printf "?")

set_brightness_prompt() {
    value=$(printf "%s\n" "${current:-50}" \
        | wofi --dmenu --exec-search --prompt "Brightness 0-100" --width 300 --height 120)

    case "$value" in
        ""|*[!0-9]*)
            notify "Enter a number from 0 to 100"
            return
            ;;
    esac

    [ "$value" -lt 0 ] && value=0
    [ "$value" -gt 100 ] && value=100
    "$brightness" set "$value%" >>"$log_file" 2>&1
}

choice=$(printf " 100%%\n 75%%\n 50%%\n 25%%\n 10%%\n Set brightness\n" \
    | wofi --dmenu --prompt "Brightness ${current}%" --width 320 --height 260)

case "$choice" in
    *"100%")
        "$brightness" set 100% >>"$log_file" 2>&1
        ;;
    *"75%")
        "$brightness" set 75% >>"$log_file" 2>&1
        ;;
    *"50%")
        "$brightness" set 50% >>"$log_file" 2>&1
        ;;
    *"25%")
        "$brightness" set 25% >>"$log_file" 2>&1
        ;;
    *"10%")
        "$brightness" set 10% >>"$log_file" 2>&1
        ;;
    *"Set brightness")
        set_brightness_prompt
        ;;
esac

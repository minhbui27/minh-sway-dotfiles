#!/bin/sh

log_file="${XDG_CACHE_HOME:-$HOME/.cache}/sway/suspend-on-battery.log"
mkdir -p "$(dirname "$log_file")"

log() {
    printf "%s %s\n" "$(date '+%F %T')" "$1" >> "$log_file"
}

on_battery_upower() {
    command -v upower >/dev/null 2>&1 || return 2

    state=$(upower -d 2>/dev/null | awk -F: '
        /on-battery:/ {
            gsub(/^[ \t]+|[ \t]+$/, "", $2)
            print $2
            exit
        }
    ')

    case "$state" in
        yes) return 0 ;;
        no) return 1 ;;
        *) return 2 ;;
    esac
}

on_battery_sysfs() {
    has_battery=0

    for supply in /sys/class/power_supply/*; do
        [ -r "$supply/type" ] || continue
        type=$(cat "$supply/type" 2>/dev/null)

        case "$type" in
            Battery)
                has_battery=1
                ;;
            Mains)
                if [ "$(cat "$supply/online" 2>/dev/null)" = "1" ]; then
                    return 1
                fi
                ;;
        esac
    done

    [ "$has_battery" = "1" ]
}

if on_battery_upower || { [ "$?" = "2" ] && on_battery_sysfs; }; then
    log "on battery; suspending"
    systemctl suspend
else
    log "plugged in; skipping suspend"
fi

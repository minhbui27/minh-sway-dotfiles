#!/bin/sh

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/sway"
log_file="$cache_dir/brightness.log"
saved_file="$cache_dir/screen-brightness"
gnome_helper="/usr/libexec/gsd-backlight-helper"

mkdir -p "$cache_dir"

log() {
    printf "%s %s\n" "$(date '+%F %T')" "$*" >> "$log_file"
}

notify_error() {
    log "$*"
    command -v notify-send >/dev/null 2>&1 && notify-send "Brightness" "$*" >/dev/null 2>&1
}

percent_for() {
    value=$1

    if [ "$max" -le 0 ]; then
        printf '0\n'
        return
    fi

    printf '%s\n' $((value * 100 / max))
}

notify_level() {
    percent=$(percent_for "$1")
    log "set brightness to ${percent}%"
    command -v notify-send >/dev/null 2>&1 || return 0

    notify-send \
        -t 900 \
        -h string:x-canonical-private-synchronous:brightness \
        -h int:value:"$percent" \
        "Brightness" "${percent}%" >/dev/null 2>&1 || true
}

find_device() {
    if [ -n "${BACKLIGHT_DEVICE:-}" ] &&
        [ -r "$BACKLIGHT_DEVICE/brightness" ] &&
        [ -r "$BACKLIGHT_DEVICE/max_brightness" ]; then
        printf '%s\n' "$BACKLIGHT_DEVICE"
        return 0
    fi

    for candidate in /sys/class/backlight/*; do
        [ -d "$candidate" ] || continue
        [ -r "$candidate/brightness" ] || continue
        [ -r "$candidate/max_brightness" ] || continue
        printf '%s\n' "$candidate"
        return 0
    done

    return 1
}

read_int() {
    value=$(cat "$1" 2>/dev/null || true)
    case "$value" in
        ''|*[!0-9]*)
            return 1
            ;;
    esac
    printf '%s\n' "$value"
}

clamp_raw() {
    value=$1

    [ "$value" -lt 0 ] && value=0
    [ "$value" -gt "$max" ] && value=$max
    printf '%s\n' "$value"
}

set_raw() {
    value=$1

    case "$value" in
        ''|*[!0-9]*)
            notify_error "invalid brightness value: $value"
            return 1
            ;;
    esac

    value=$(clamp_raw "$value")

    if command -v brightnessctl >/dev/null 2>&1; then
        brightnessctl -d "$(basename "$device")" set "$value" >/dev/null 2>&1 && return 0
    fi

    if command -v pkexec >/dev/null 2>&1 && [ -x "$gnome_helper" ]; then
        pkexec "$gnome_helper" "$device" "$value" >/dev/null 2>&1 && return 0
    fi

    if [ -w "$device/brightness" ]; then
        printf '%s\n' "$value" > "$device/brightness" && return 0
    fi

    notify_error "no usable brightness backend"
    return 1
}

parse_target() {
    target=$1

    case "$target" in
        *%)
            percent=${target%\%}
            case "$percent" in
                ''|*[!0-9]*)
                    return 1
                    ;;
            esac
            [ "$percent" -gt 100 ] && percent=100
            printf '%s\n' $((max * percent / 100))
            ;;
        *)
            case "$target" in
                ''|*[!0-9]*)
                    return 1
                    ;;
            esac
            printf '%s\n' "$target"
            ;;
    esac
}

device=$(find_device) || {
    notify_error "no backlight device found"
    exit 1
}

current=$(read_int "$device/brightness") || {
    notify_error "could not read current brightness"
    exit 1
}

max=$(read_int "$device/max_brightness") || {
    notify_error "could not read max brightness"
    exit 1
}

step=$((max / 20))
[ "$step" -lt 1 ] && step=1
floor=$((max / 100))
[ "$floor" -lt 1 ] && floor=1

case "${1:-}" in
    up)
        next=$((current + step))
        next=$(clamp_raw "$next")
        set_raw "$next" && notify_level "$next"
        ;;
    down)
        next=$((current - step))
        [ "$next" -lt "$floor" ] && next=$floor
        next=$(clamp_raw "$next")
        set_raw "$next" && notify_level "$next"
        ;;
    set)
        next=$(parse_target "${2:-}") || {
            notify_error "usage: brightness.sh set VALUE|PERCENT%"
            exit 1
        }
        next=$(clamp_raw "$next")
        set_raw "$next" && notify_level "$next"
        ;;
    blank)
        if [ "$current" -gt 0 ]; then
            printf '%s\n' "$current" > "$saved_file"
        fi
        set_raw 0
        ;;
    restore)
        saved=""
        if [ -r "$saved_file" ]; then
            saved=$(cat "$saved_file")
        fi

        case "$saved" in
            ''|*[!0-9]*|0)
                saved=$((max * 40 / 100))
                ;;
        esac

        if set_raw "$saved"; then
            rm -f "$saved_file"
        fi
        ;;
    get)
        printf '%s\n' "$current"
        ;;
    percent)
        percent_for "$current"
        ;;
    *)
        notify_error "usage: brightness.sh up|down|set|get|percent|blank|restore"
        exit 1
        ;;
esac

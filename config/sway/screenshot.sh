#!/bin/sh

mode=${1:-region}
directory="$HOME/Pictures/Screenshots"
file="$directory/Screenshot-$(date '+%F-%H%M%S').png"
log_file="${XDG_CACHE_HOME:-$HOME/.cache}/sway/screenshot.log"
mkdir -p "$(dirname "$log_file")"
printf "%s launched mode=%s pid=%s\n" "$(date '+%F %T')" "$mode" "$$" >> "$log_file"

notify() {
    notify-send "Screenshot" "$1" >/dev/null 2>&1 || true
}

need() {
    if ! command -v "$1" >/dev/null 2>&1; then
        notify "Missing $1. Install it with: sudo apt install $1"
        exit 1
    fi
}

need grim
mkdir -p "$directory"

case "$mode" in
    full)
        grim "$file" && notify "Saved to $file"
        ;;
    region)
        need slurp
        geometry=$(slurp) || exit 0
        [ -n "$geometry" ] || exit 0
        grim -g "$geometry" "$file" && notify "Saved to $file"
        ;;
    clipboard)
        need slurp
        need wl-copy
        geometry=$(slurp) || exit 0
        [ -n "$geometry" ] || exit 0
        grim -g "$geometry" - | wl-copy && notify "Copied region to clipboard"
        ;;
    *)
        notify "Unknown screenshot mode: $mode"
        exit 1
        ;;
esac

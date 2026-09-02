#!/bin/sh

mode=${1:-region}
directory="$HOME/Pictures/Screenshots"
file="$directory/Screenshot-$(date '+%F-%H%M%S').png"
log_file="${XDG_CACHE_HOME:-$HOME/.cache}/sway/screenshot.log"
mkdir -p "$(dirname "$log_file")"
printf "%s launched mode=%s pid=%s\n" "$(date '+%F %T')" "$mode" "$$" >> "$log_file"

# Only one instance at a time: a second launch (e.g. from a duplicate
# keybinding) stacks a second slurp overlay on top of the first.
exec 9> "${XDG_RUNTIME_DIR:-/tmp}/screenshot.lock"
if ! flock -n 9; then
    printf "%s skipped: lock held by another instance\n" "$(date '+%F %T')" >> "$log_file"
    exit 0
fi

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
        # Selection done — release the lock so children (zenity) don't
        # inherit and hold it past this script's lifetime.
        exec 9>&-
        # Capture first, then ask where to save so the shot isn't lost
        # while the dialog is open.
        tmp=$(mktemp --suffix=.png)
        if ! grim -g "$geometry" "$tmp"; then
            rm -f "$tmp"
            notify "Capture failed"
            exit 1
        fi
        if command -v zenity >/dev/null 2>&1; then
            target=$(zenity --file-selection --save --confirm-overwrite \
                --title="Save screenshot" --filename="$file" \
                --file-filter="PNG images | *.png" 2>/dev/null)
            if [ -n "$target" ]; then
                mv "$tmp" "$target" && notify "Saved to $target"
            else
                rm -f "$tmp"
                notify "Screenshot discarded"
            fi
        else
            mv "$tmp" "$file" && notify "Saved to $file"
        fi
        ;;
    clipboard)
        need slurp
        need wl-copy
        geometry=$(slurp) || exit 0
        [ -n "$geometry" ] || exit 0
        # Selection done — release the lock so wl-copy (which lingers to
        # serve the clipboard) doesn't inherit and hold it forever.
        exec 9>&-
        grim -g "$geometry" - | wl-copy && notify "Copied region to clipboard"
        ;;
    *)
        notify "Unknown screenshot mode: $mode"
        exit 1
        ;;
esac

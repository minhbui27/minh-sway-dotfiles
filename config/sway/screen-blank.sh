#!/bin/sh

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/sway"
log_file="$cache_dir/screen-blank.log"
outputs_file="$cache_dir/screen-outputs"
mkdir -p "$cache_dir"

/home/minhbui/.config/sway/brightness.sh blank

if command -v jq >/dev/null 2>&1; then
    swaymsg -t get_outputs \
        | jq -r '.[] | select(.active and .power) | .name' > "$outputs_file"
else
    printf '%s\n' "${INTERNAL_OUTPUT:-eDP-1}" > "$outputs_file"
fi

external_outputs=""
internal_outputs=""
while IFS= read -r output; do
    [ -n "$output" ] || continue

    case "$output" in
        eDP-*|LVDS-*|DSI-*)
            internal_outputs="$internal_outputs $output"
            ;;
        *)
            external_outputs="$external_outputs $output"
            ;;
    esac
done < "$outputs_file"

for output in $external_outputs $internal_outputs; do
    if swaymsg "output $output power off" >/dev/null 2>&1; then
        printf "%s powered off %s\n" "$(date '+%F %T')" "$output" >> "$log_file"
    else
        printf "%s failed to power off %s\n" "$(date '+%F %T')" "$output" >> "$log_file"
    fi
done

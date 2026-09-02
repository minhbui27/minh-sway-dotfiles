#!/bin/sh

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/sway"
log_file="$cache_dir/screen-blank.log"
outputs_file="$cache_dir/screen-outputs"

mkdir -p "$cache_dir"

if [ -r "$outputs_file" ]; then
    while IFS= read -r output; do
        [ -n "$output" ] || continue
        swaymsg "output $output power on" >/dev/null 2>&1 || true
    done < "$outputs_file"
fi

swaymsg "output * power on" >/dev/null 2>&1 || true
printf "%s screen unblank requested\n" "$(date '+%F %T')" >> "$log_file"
exec /home/minhbui/.config/sway/brightness.sh restore

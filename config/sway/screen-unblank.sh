#!/bin/sh

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/sway"
log_file="$cache_dir/screen-blank.log"

mkdir -p "$cache_dir"
swaymsg "output * power on" >/dev/null 2>&1 || true
printf "%s screen unblank requested\n" "$(date '+%F %T')" >> "$log_file"
exec /home/minhbui/.config/sway/brightness.sh restore

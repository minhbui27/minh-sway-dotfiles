#!/bin/sh

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/sway"
log_file="$cache_dir/idle-suspend.log"
resume_file="$cache_dir/last-resume"

mkdir -p "$cache_dir"
date '+%s' > "$resume_file"
printf "%s resumed from suspend\n" "$(date '+%F %T')" >> "$log_file"
swaymsg "output * power on" >/dev/null 2>&1

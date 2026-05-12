#!/bin/sh

log_file="${XDG_CACHE_HOME:-$HOME/.cache}/sway/lid.log"
mkdir -p "$(dirname "$log_file")"
printf "%s lid opened: powering outputs on\n" "$(date '+%F %T')" >> "$log_file"

swaymsg "output * power on" >/dev/null 2>&1

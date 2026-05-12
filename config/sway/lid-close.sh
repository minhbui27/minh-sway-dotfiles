#!/bin/sh

log_file="${XDG_CACHE_HOME:-$HOME/.cache}/sway/lid.log"
mkdir -p "$(dirname "$log_file")"
printf "%s lid closed: suspending\n" "$(date '+%F %T')" >> "$log_file"

systemctl suspend

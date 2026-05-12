#!/bin/sh

log_file="${XDG_CACHE_HOME:-$HOME/.cache}/sway/lid.log"
mkdir -p "$(dirname "$log_file")"

if pgrep -u "$(id -u)" -f '[s]way-lid-inhibitor' >/dev/null 2>&1; then
    printf "%s lid suspend inhibitor already running\n" "$(date '+%F %T')" >> "$log_file"
    exit 0
fi

printf "%s starting lid suspend inhibitor\n" "$(date '+%F %T')" >> "$log_file"
exec systemd-inhibit \
    --what=handle-lid-switch \
    --who=sway-lid-inhibitor \
    --why="Sway handles lid close and calls suspend itself" \
    --mode=block \
    sleep infinity

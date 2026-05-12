#!/bin/sh

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/sway"
log_file="$cache_dir/idle-suspend.log"
resume_file="$cache_dir/last-resume"
grace_seconds=120

mkdir -p "$cache_dir"
now=$(date '+%s')

if [ -r "$resume_file" ]; then
    last_resume=$(cat "$resume_file")
    case "$last_resume" in
        *[!0-9]*|'')
            last_resume=0
            ;;
    esac

    age=$((now - last_resume))
    if [ "$age" -lt "$grace_seconds" ]; then
        printf "%s skip idle suspend: resumed %ss ago\n" "$(date '+%F %T')" "$age" >> "$log_file"
        exit 0
    fi
fi

printf "%s idle suspend\n" "$(date '+%F %T')" >> "$log_file"
systemctl suspend

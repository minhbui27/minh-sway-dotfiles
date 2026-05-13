#!/bin/sh

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/sway"
log_file="$cache_dir/idle-suspend.log"
resume_file="$cache_dir/last-resume"
grace_seconds=120

mkdir -p "$cache_dir"
now=$(date '+%s')

if upower -e 2>/dev/null | while IFS= read -r device; do
    upower -i "$device" 2>/dev/null | awk '
        /line-power/ { line_power = 1 }
        line_power && /online:[[:space:]]+yes/ { found = 1 }
        END { exit found ? 0 : 1 }
    ' && exit 0
done; then
    printf "%s skip idle suspend: plugged in\n" "$(date '+%F %T')" >> "$log_file"
    exit 0
fi

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

printf "%s idle suspend: on battery\n" "$(date '+%F %T')" >> "$log_file"
systemctl suspend

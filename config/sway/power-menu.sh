#!/bin/sh

log_file="${XDG_CACHE_HOME:-$HOME/.cache}/sway/power-menu.log"
mkdir -p "$(dirname "$log_file")"
exec >> "$log_file" 2>&1
printf "%s launched pid=%s\n" "$(date '+%F %T')" "$$" >> "$log_file"

choice=$(printf " Lock\n Restart\n Power off\n" \
    | wofi --dmenu --prompt "Power" --width 260 --height 180)

case "$choice" in
    *Lock)
        /home/minhbui/.config/sway/lock.sh
        ;;
    *Restart)
        confirm=$(printf " Restart\nCancel\n" \
            | wofi --dmenu --prompt "Confirm" --width 260 --height 140)
        [ "$confirm" = " Restart" ] && systemctl reboot
        ;;
    *"Power off")
        confirm=$(printf " Power off\nCancel\n" \
            | wofi --dmenu --prompt "Confirm" --width 260 --height 140)
        [ "$confirm" = " Power off" ] && systemctl poweroff
        ;;
esac

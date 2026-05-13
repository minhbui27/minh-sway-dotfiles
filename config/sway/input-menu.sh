#!/bin/sh

mode_file="${XDG_CACHE_HOME:-$HOME/.cache}/sway/fcitx5-mode"
mkdir -p "$(dirname "$mode_file")"

if ! fcitx5-remote --check >/dev/null 2>&1; then
    /home/minhbui/.config/sway/start-fcitx5.sh >/dev/null 2>&1
    sleep 0.2
fi

choice=$(printf '%s\n' \
    "US keyboard" \
    "Japanese Mozc" \
    "Fcitx5 settings" \
    "Restart Fcitx5" \
    | wofi --dmenu --prompt "Input")

case "$choice" in
    "US keyboard")
        fcitx5-remote -s keyboard-us >/dev/null 2>&1 || true
        fcitx5-remote -c >/dev/null 2>&1 || true
        printf "US\n" > "$mode_file"
        ;;
    "Japanese Mozc")
        fcitx5-remote -s mozc >/dev/null 2>&1 || true
        fcitx5-remote -o >/dev/null 2>&1 || true
        printf "あ\n" > "$mode_file"
        ;;
    "Fcitx5 settings")
        fcitx5-configtool >/dev/null 2>&1 &
        ;;
    "Restart Fcitx5")
        /home/minhbui/.config/sway/start-fcitx5.sh >/dev/null 2>&1
        ;;
esac

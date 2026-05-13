#!/bin/sh

mode_file="${XDG_CACHE_HOME:-$HOME/.cache}/sway/fcitx5-mode"
log_file="${XDG_CACHE_HOME:-$HOME/.cache}/sway/kana-input.log"
mkdir -p "$(dirname "$mode_file")"

if ! fcitx5-remote --check >/dev/null 2>&1; then
    /home/minhbui/.config/sway/start-fcitx5.sh >/dev/null 2>&1
    sleep 0.2
fi

{
    printf "%s pid=%s im_before=" "$(date '+%F %T')" "$$"
    fcitx5-remote -n 2>/dev/null || printf "unknown"
    printf "\n"
} >> "$log_file"

fcitx5-remote -s mozc >/dev/null 2>&1 || true
fcitx5-remote -o >/dev/null 2>&1 || true
printf "あ\n" > "$mode_file"

{
    printf "%s pid=%s im_after=" "$(date '+%F %T')" "$$"
    fcitx5-remote -n 2>/dev/null || printf "unknown"
    printf " mode_cache="
    cat "$mode_file" 2>/dev/null || printf "unknown"
} >> "$log_file"
